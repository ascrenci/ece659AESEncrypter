`timescale 1ns/1ps

module aes_tb;
    logic clk;
    logic rst;
    logic [127:0] plaintext;
    logic [127:0] key;
    logic [127:0] sat_key;
    logic [127:0] ciphertext;
    logic start;
    logic ready;

    aes_fsm_locked dut (
        .clk(clk),
        .rst(rst),
        .plaintext(plaintext),
        .key(key),
        .ciphertext(ciphertext),
        .sat_key(sat_key),
        .start(start),
        .ready(ready)
    );

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        plaintext = 0;
        key = 0;
        sat_key = 0;
        forever #5 clk <= ~clk;
    end
                                //16bytesrulerhere
    const logic[127:0] TV_PT   = "testingaes123456";
    const logic[127:0] TV_KEY  = "ascrenci33882356";
    const logic[127:0] TV_EXP  = 128'h44f43f501c0cc07af19c621243fe01c0;

    initial begin
        @(posedge clk); #1;
        rst = 0;
        $display("--- Starting AES Encryption Test ---");
        plaintext = TV_PT;
        key = TV_KEY;
        $value$plusargs("SAR_KEY=%h", sat_key);
        @(negedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0;

        do @(posedge clk); while (!ready);
        
        #1;
        if (ciphertext === TV_EXP) begin
            $display("SUCCESS: Ciphertext matches expected output!");
            $display("Result:   %h", ciphertext);
            $display("Expected: %h", TV_EXP);
            $display("SAR KEY:  %h", sat_key);
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
        $dumpfile("aes_test.vcd");
        $dumpvars(1, aes_tb.dut);
    end

endmodule