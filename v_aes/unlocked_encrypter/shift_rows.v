`timescale 1ns/1ps

module shift_rows(
    input wire [127:0] state_in,
    output wire [127:0] state_out
);

    wire [7:0] b [0:15];

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : SHIFT_ROWS_BYTE_EXTRACT
            assign b[i] = state_in[127 - i*8 -: 8];
        end
    endgenerate
    
    // b.T =:
    // b[0], b[4], b[8], b[12],
    // b[1], b[5], b[9], b[13],
    // b[2], b[6], b[10], b[14],
    // b[3], b[7], b[11], b[15]

    assign state_out = {
        b[0],  b[5],  b[10], b[15],
        b[4],  b[9],  b[14], b[3],
        b[8],  b[13], b[2],  b[7],
        b[12], b[1],  b[6],  b[11]
    };

endmodule
