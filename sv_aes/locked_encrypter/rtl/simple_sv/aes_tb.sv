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

    initial clk = 0;
    always #5 clk = ~clk;
                           //16bytesrulerhere
    const logic [127:0] TV_PT   = "testingaes123456";//128'h00112233445566778899AABBCCDDEEFF;//
    const logic [127:0] TV_KEY  = "ascrenci33882356";//128'h000102030405060708090A0B0C0D0E0F;//
    const logic [127:0] TV_EXP  = 128'h44f43f501c0cc07af19c621243fe01c0;

    initial begin
        rst = 1;
        start = 0;
        plaintext = 0;
        key = 0;
        sat_key = 0;

        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        $display("--- Starting AES Encryption Test ---");
        plaintext = TV_PT;
        key = TV_KEY;
        $value$plusargs("SAR_KEY=%h", sat_key);

        @(posedge clk);
        start = 1;
        repeat(1) @(posedge clk);
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
        $dumpvars(0, aes_tb);
    end

endmodule