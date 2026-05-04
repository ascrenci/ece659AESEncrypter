`timescale 1ns/1ps

module aes_tb;
    import aes_pkg::*;

    logic clk;
    logic rst;
    
    aes_if bus();

    aes_fsm_locked dut (
        .clk(clk),
        .rst(rst),
        .bus(bus.dut)
    );

                           //16bytesrulerhere
    const state_t TV_PT   = "testingaes123456";//128'h00112233445566778899AABBCCDDEEFF;//
    const key_t   TV_KEY  = "ascrenci33882356";//128'h000102030405060708090A0B0C0D0E0F;//
    const state_t TV_EXP  = 128'h44f43f501c0cc07af19c621243fe01c0;

    initial begin
        clk = 0;
        rst = 1;
        bus.start = 0;
        bus.plaintext = 0;
        bus.key = 0;
        bus.sat_key = 0;
        forever #5 clk <= ~clk;
    end

    initial begin
        @(posedge clk); #1;
        rst = 0;
        $display("--- Starting AES Encryption Test ---");
        bus.plaintext = TV_PT;
        bus.key = TV_KEY;
        $value$plusargs("SAR_KEY=%h", bus.sat_key);
        @(negedge clk); #2;
        bus.start = 1;
        @(posedge clk); #1;
        bus.start = 0;

        do @(posedge clk); while (!bus.ready);
        
        #1;
        if (bus.ciphertext === TV_EXP) begin
            $display("SUCCESS: Ciphertext matches expected output!");
            $display("Result:   %h", bus.ciphertext);
            $display("Expected: %h", TV_EXP);
            $display("SAR KEY:  %h", bus.sat_key);
        end else begin
            $display("ERROR: Ciphertext mismatch!");
            $display("Expected: %h", TV_EXP);
            $display("Actual:   %h", bus.ciphertext);
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