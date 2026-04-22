`timescale 1ns/1ps

module aes_tb;
    import aes_pkg::*;

    logic clk;
    logic rst;

    aes_if bus();

    aes_fsm dut (
        .clk(clk),
        .rst(rst),
        .bus(bus.dut)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    const state_t TV_PT   = "testingaes123456";
    const key_t   TV_KEY  = "ascrenci33882356";
    const state_t TV_EXP  = 128'h44f43f501c0cc07af19c621243fe01c0;

    initial begin
        rst = 1;
        bus.start = 0;
        bus.plaintext = 0;
        bus.key = 0;

        repeat(5) @(posedge clk);
        rst = 0;
        @(posedge clk);

        $display("--- Starting AES Encryption Test ---");
        bus.plaintext = TV_PT;
        bus.key = TV_KEY;

        @(posedge clk);
        bus.start = 1;
        repeat(1) @(posedge clk);
        bus.start = 0;

        do @(posedge clk); while (!bus.ready);
        
        #1;
        if (bus.ciphertext === TV_EXP) begin
            $display("SUCCESS: Ciphertext matches expected output!");
            $display("Result:   %h", bus.ciphertext);
            $display("Expected: %h", TV_EXP);
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
        $dumpvars(0, aes_tb);
    end

endmodule