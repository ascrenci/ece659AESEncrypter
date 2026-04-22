`timescale 1ns/1ps

module rot_word(
    input [31:0] word_in,
    output [31:0] word_out
);

    assign word_out = {word_in[23:0], word_in[31:24]};

endmodule

module sub_word(
    input [31:0] word_in,
    output [31:0] word_out
);

    wire [7:0] b0, b1, b2, b3;
    assign {b0, b1, b2, b3} = word_in;

    sbox s0(.sbox_in(b0), .sbox_out(word_out[31:24]));
    sbox s1(.sbox_in(b1), .sbox_out(word_out[23:16]));
    sbox s2(.sbox_in(b2), .sbox_out(word_out[15:8]));
    sbox s3(.sbox_in(b3), .sbox_out(word_out[7:0]));

endmodule

module rcon(
    input [3:0] round,
    output reg [31:0] rcon_out
);

always @(*) begin
    case(round)
        1: rcon_out = 32'h01000000;
        2: rcon_out = 32'h02000000;
        3: rcon_out = 32'h04000000;
        4: rcon_out = 32'h08000000;
        5: rcon_out = 32'h10000000;
        6: rcon_out = 32'h20000000;
        7: rcon_out = 32'h40000000;
        8: rcon_out = 32'h80000000;
        9: rcon_out = 32'h1B000000;
       10: rcon_out = 32'h36000000;
    endcase
end

endmodule

module key_expansion(
    input wire [127:0] key,
    output wire [1407:0] round_keys
);

    wire [31:0] W [0:43];

    assign W[0] = key[127:96];
    assign W[1] = key[95:64];
    assign W[2] = key[63:32];
    assign W[3] = key[31:0];

    wire [31:0] rot [1:10];
    wire [31:0] sub [1:10];
    wire [31:0] rcon_out [1:10];

    genvar r;
    generate
        for (r = 1; r <= 10; r = r + 1) begin: KEY_SCHEDULER

            rot_word rot_inst (
                .word_in(W[(r*4)-1]),
                .word_out(rot[r])
            );

            sub_word sub_inst (
                .word_in(rot[r]),
                .word_out(sub[r])
            );

            rcon rcon_inst (
                .round(r[3:0]),
                .rcon_out(rcon_out[r])
            );

            assign W[r*4] = W[(r*4)-4]^sub[r]^rcon_out[r];
            assign W[r*4 + 1] = W[(r*4) - 3]^W[r*4];
            assign W[r*4 + 2] = W[(r*4)-2] ^ W[r*4 + 1];
            assign W[r*4 + 3] = W[(r*4)-1] ^ W[r*4 + 2];

        end
    endgenerate

    genvar i;
    generate
        for (i = 0; i < 11; i = i + 1) begin : ROUND_KEY_PACK

            assign round_keys[(1407 - i*128) -: 128] = {
                W[i*4],
                W[i*4 + 1],
                W[i*4 + 2],
                W[i*4 + 3]
            };

        end
    endgenerate
endmodule