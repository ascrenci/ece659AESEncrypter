`timescale 1ns/1ps

package aes_pkg;
    typedef logic [127:0] state_t;
    typedef logic [127:0] key_t;
    typedef logic [7:0] sbox_t [256];
    typedef logic signal_t;
endpackage

module aes_tb;
    import aes_pkg::*;
    logic clk;
    logic rst;

    state_t plaintext;
    key_t key;
    state_t ciphertext;

    signal_t start;
    signal_t ready;

    aes_fsm_unlocked dut (
        .clk(clk),
        .rst(rst),
        .bus_plaintext(plaintext),
        .bus_key(key),
        .bus_ciphertext(ciphertext),
        .bus_start(start),
        .bus_ready(ready)
    );

    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        plaintext = 0;
        key = 0;
        forever #10 clk <= ~clk;
    end

    const state_t TV_PT   = "testingaes123456";
    const key_t TV_KEY  = "ascrenci33882356";
    const state_t TV_EXP  = 128'h44f43f501c0cc07af19c621243fe01c0;

    initial begin
        @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        // Apply inputs and start
        $display("--- Starting AES Encryption Test ---");
        plaintext = TV_PT;
        key = TV_KEY;

        // Pulse start for one clk period
        @(posedge clk); #1;
        start = 1;
        @(posedge clk); #1;
        start = 0; 

        // Wait for dut to pulse ready
        do @(posedge clk); while (!ready);

        #1;
        if (ciphertext == TV_EXP) begin
            $display("SUCCESS: Ciphertext matches expected output!");
            $display("Result:   %h", ciphertext);
            $display("Expected: %h", TV_EXP);
        end else begin
            $display("ERROR: Ciphertext mismatch!");
            $display("Expected: %h", TV_EXP);
            $display("Actual:   %h", ciphertext);
        end

        #50;
        $display("--- Test Complete ---");
        $finish;
    end

    // Waveform Export (For GTKWave or Vivado)
    initial begin
        $dumpfile("aes_post_synth.vcd");
        $dumpvars(1, aes_tb);
    end

endmodule