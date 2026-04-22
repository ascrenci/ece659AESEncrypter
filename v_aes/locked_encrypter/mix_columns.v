`timescale 1ns/1ps

module mix_columns(
    input wire [127:0] state_in,
    output wire [127:0] state_out
);

    // get bytes from input bits
    wire [7:0] b [0:15];

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : MIX_COLUMNS_BYTE_EXTRACT
            assign b[i] = state_in[127 - i*8 -: 8];
        end
    endgenerate

    // function to multiply by 2 in galois field
    // If MSB = 1: left shift and XOR with 0x1b, else left shift 1
    // multiply by 3 = xtime(x) XOR x
    function [7:0] xtime;
        input [7:0] x;
        begin
            xtime = (x[7]) ? ((x << 1) ^ 8'h1B) :
                              (x << 1);
        end
    endfunction

    // Matrix to be multiplied by
    // | 02 03 01 01 |
    // | 01 02 03 01 |
    // | 01 01 02 03 |
    // | 03 01 01 02 |

    // mix columns
    wire [7:0] m [0:15];

    genvar c;
    generate
        for (c = 0; c < 4; c = c + 1) begin : MIX_COLUMN

            // assigns s[0:3] to the each column for each iteration
            wire [7:0] s0 = b[c*4 + 0]; 
            wire [7:0] s1 = b[c*4 + 1];
            wire [7:0] s2 = b[c*4 + 2];
            wire [7:0] s3 = b[c*4 + 3];

            // 2*s0 + 3*s1 + s2 + s3
            assign m[c*4 + 0] = xtime(s0) ^ (xtime(s1) ^ s1) ^ s2 ^ s3;
            // s0 + 2*s1 + 3*s2 + s3
            assign m[c*4 + 1] = s0 ^ xtime(s1) ^ (xtime(s2) ^ s2) ^ s3;
            // s0 + s1 + 2*s2 + 3*s3
            assign m[c*4 + 2] = s0 ^ s1 ^ xtime(s2) ^ (xtime(s3) ^ s3);
            
            assign m[c*4 + 3] = (xtime(s0) ^ s0) ^ s1 ^ s2 ^ xtime(s3);

        end
    endgenerate

    // reconstruct output from column major order
      generate
        for (i = 0; i < 16; i = i + 1) begin : OUTPUT_PACK
            assign state_out[127 - i*8 -: 8] = m[i];
        end
    endgenerate

endmodule