`timescale 1ns/1ps
package aes_pkg;
    typedef logic [127:0] state_t;
    typedef logic [127:0] key_t;
    typedef logic [7:0] sbox_t [256];
    typedef logic signal_t;
    typedef logic [127:0] sar_key_t;
endpackage

module aes_tb;
    import aes_pkg::*;

    logic clk;
    logic rst;
    state_t plaintext;
    key_t key;
    sar_key_t sar_key;
    signal_t start;
    state_t ciphertext;
    signal_t ready;

    aes_fsm_locked dut (
        .clk(clk),
        .rst(rst),
        .bus_plaintext(plaintext),
        .bus_key(key),
        .bus_sar_key(sar_key),
        .bus_start(start),
        .bus_ciphertext(ciphertext),
        .bus_ready(ready)
    );

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        plaintext = 0;
        key = 0;
        sar_key = 0;
        forever #10 clk <= ~clk;
    end
                           //16bytesrulerhere
    const state_t TV_PT   = "testingaes123456";//128'h00112233445566778899AABBCCDDEEFF;//
    const key_t   TV_KEY  = "ascrenci33882356";//128'h000102030405060708090A0B0C0D0E0F;//
    const state_t TV_EXP  = 128'h44f43f501c0cc07af19c621243fe01c0;

    initial begin
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        $display("--- Starting AES Encryption Test ---");
        plaintext = TV_PT;
        key = TV_KEY;
        $value$plusargs("SAR_KEY=%h", sar_key);

        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        do @(posedge clk); while (!ready);
        
        #1;
        if (ciphertext === TV_EXP) begin
            $display("SUCCESS: Ciphertext matches expected output!");
            $display("Result:   %h", ciphertext);
            $display("Expected: %h", TV_EXP);
            $display("SAR KEY:  %h", sar_key);
        end else begin
            $display("ERROR: Ciphertext mismatch!");
            $display("Expected: %h", TV_EXP);
            $display("Actual:   %h", ciphertext);
        end

        #50;
        $display("--- Test Complete ---");
        $finish;
    end

    initial begin
        //$fsdbDumpfile("aes_test.fsdb");
        //$fsdbDumpvars(0, aes_tb);
        $dumpfile("aes_test.vcd");
        $dumpvars(1, aes_tb.dut);
    end

endmodule