`timescale 1ns/1ps
module key_expansion (
    input logic [3:0] round_num,
    input aes_pkg::key_t key_in,
    output aes_pkg::key_t key_out
);
    import aes_pkg::*;

    logic [31:0] w0, w1, w2, w3;
    logic [31:0] sub_word_out;
    logic [7:0] rcon;

    assign {w0, w1, w2, w3} = key_in;

    assign sub_word_out[31:24] = AES_SBOX[w3[23:16]];
    assign sub_word_out[23:16] = AES_SBOX[w3[15:8]];
    assign sub_word_out[15:8] = AES_SBOX[w3[7:0]];
    assign sub_word_out[7:0] = AES_SBOX[w3[31:24]];

    assign rcon = get_rcon(round_num);

    logic [31:0] next_w0, next_w1, next_w2, next_w3;

    assign next_w0 = w0^sub_word_out^{rcon, 24'h0};
    assign next_w1 = w1^next_w0;
    assign next_w2 = w2^next_w1;
    assign next_w3 = w3^next_w2;

    assign key_out = {next_w0, next_w1, next_w2, next_w3};

endmodule

module sub_bytes(
    input aes_pkg::state_t state_in,
    output aes_pkg::state_t state_out
);
    always_comb begin
        for (int i = 0; i < 16; i++) begin
            state_out[i*8 +: 8] = aes_pkg::AES_SBOX[state_in[i*8 +: 8]];
        end
    end
endmodule

module shift_rows(
    input aes_pkg::state_t state_in,
    output aes_pkg::state_t state_out
);

    logic [7:0] bytes_in [16];
    logic [7:0] bytes_out [16];

    always_comb begin
        for (int i = 0; i < 16; i++) begin
            bytes_in[i] = state_in[127 - i*8 -: 8];
        end
    end

    //First row do nothing
    assign bytes_out[0] = bytes_in[0];
    assign bytes_out[4] = bytes_in[4];
    assign bytes_out[8] = bytes_in[8];
    assign bytes_out[12] = bytes_in[12];

    // Second row shift left 1
    assign bytes_out[1] = bytes_in[5];
    assign bytes_out[5] = bytes_in[9];
    assign bytes_out[9] = bytes_in[13];
    assign bytes_out[13] = bytes_in[1];

    // Third row shift left 2
    assign bytes_out[2] = bytes_in[10];
    assign bytes_out[6] = bytes_in[14];
    assign bytes_out[10] = bytes_in[2];
    assign bytes_out[14] = bytes_in[6];

    // Fourth row shift left 3
    assign bytes_out[3] = bytes_in[15];
    assign bytes_out[7] = bytes_in[3];
    assign bytes_out[11] = bytes_in[7];
    assign bytes_out[15] = bytes_in[11];

    // Repack
    always_comb begin
        for (int i = 0; i < 16; i++) begin
            state_out[127 - i*8 -: 8] = bytes_out[i];
        end
    end
endmodule

module mix_columns (
    input aes_pkg::state_t state_in,
    output aes_pkg::state_t state_out
);

    function automatic logic [7:0] xtime(logic [7:0] b);
        return (b[7]) ? ((b << 1) ^ 8'h1b) : (b << 1);
    endfunction

    always_comb begin
        logic [7:0] b0, b1, b2, b3;
        for (int i = 0; i < 4; i++) begin
            
            // get column bytes
            b0 = state_in[127 - i*32 -:8];
            b1 = state_in[119 - i*32 -:8];
            b2 = state_in[111 - i*32 -:8];
            b3 = state_in[103 - i*32 -:8];

            state_out[127 - i*32 -: 8] = xtime(b0) ^ (b1^xtime(b1)) ^ b2 ^ b3;
            state_out[119 - i*32 -: 8] = b0 ^ xtime(b1) ^ (b2^xtime(b2)) ^ b3;
            state_out[111 - i*32 -: 8] = b0 ^ b1 ^ xtime(b2) ^ (b3^xtime(b3));
            state_out[103 - i*32 -: 8] = (b0^xtime(b0)) ^ b1 ^ b2 ^ xtime(b3);
        end
    end
endmodule

module aes_round(
    input aes_pkg::state_t state_in,
    input aes_pkg::key_t round_key,
    input logic skip_mix_col,
    output aes_pkg::state_t state_out
);
    import aes_pkg::*;
    
    state_t sb_out, sr_out, mc_out;

    sub_bytes sub (.state_in(state_in), .state_out(sb_out));
    shift_rows shift (.state_in(sb_out), .state_out(sr_out));
    mix_columns mix (.state_in(sr_out), .state_out(mc_out));

    always_comb begin
        if (skip_mix_col)
            state_out = sr_out ^ round_key;
        else
            state_out = mc_out ^ round_key;
    end

endmodule