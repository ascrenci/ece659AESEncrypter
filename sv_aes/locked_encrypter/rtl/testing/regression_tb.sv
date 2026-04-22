module regression_tb;
    import aes_pkg::*;

    logic clk = 0, rst = 1;
    aes_if bus();
    aes_fsm dut(.clk(clk), .rst(rst), .bus(bus));

    aes_if bus2();
    aes_fsm_unlocked dut2(.clk(clk), .rst(rst), .bus(bus2));

    always #5 clk = ~clk;

    // Reference model — pure software AES (pre-computed golden vectors)
    // Load from file or hardcode known-good pt/ct pairs
    state_t golden_ct;
    state_t ct_out;
    int pass_count, fail_count;

    task run_encryption(
        input state_t pt,
        input key_t   k,
        input sar_key_t sk,
        output state_t ct
    );  
        @(posedge clk); rst = 1;
        repeat(5) @(posedge clk); rst = 0;

        bus.plaintext = pt;
        bus.key       = k;
        bus.sar_key   = sk;
        @(posedge clk); bus.start     = 1;
        @(posedge clk); bus.start = 0;
        do @(posedge clk); while(!bus.ready);
        ct = bus.ciphertext;
    endtask

    task run_encryption_unlocked(
        input state_t pt,
        input key_t k,
        output state_t ct
    );
        @(posedge clk); rst = 1;
        repeat (5) @(posedge clk); rst = 0;

        bus2.plaintext = pt;
        bus2.key = k;
        @(posedge clk); bus2.start = 1;
        @(posedge clk); bus2.start = 0;
        do @(posedge clk); while(!bus2.ready);
        ct = bus2.ciphertext;
    endtask

    initial begin
        @(posedge clk); rst = 1; repeat(4) @(posedge clk); rst = 0;

        pass_count = 0; fail_count = 0;

        // Test 1: NIST FIPS-197 known-answer vectors with CORRECT_KEY
        // Plaintext:  00112233445566778899AABBCCDDEEFF
        // AES Key:    000102030405060708090A0B0C0D0E0F
        // Ciphertext: 69c4e0d86a7b0430d8cdb78070b4c55a (standard AES output)
        //state_t ct_out;
        run_encryption(
            128'h00112233445566778899AABBCCDDEEFF,
            128'h000102030405060708090A0B0C0D0E0F,
            32'hABCDEF01,   // CORRECT_KEY
            ct_out
        );
        // Verify matches known AES output — no corruption
        if (ct_out == 128'h69c4e0d86a7b0430d8cdb78070b4c55a)
            pass_count++;
        else begin
            $error("REGRESSION FAIL: Correct key corrupted output!");
            fail_count++;
        end

        // Test 2: 10,000 random plaintexts with CORRECT_KEY
        // Compare against software reference model
        repeat(10000) begin
            automatic state_t pt  = {$urandom,$urandom,$urandom,$urandom};
            automatic key_t   k   = {$urandom,$urandom,$urandom,$urandom};
            run_encryption(pt, k, 32'hABCDEF01, ct_out);
            run_encryption_unlocked(pt, k, golden_ct);

            if (ct_out != golden_ct) begin
                fail_count++;
            end else begin
                pass_count++;
            end
            //$display("Regression: %0d PASS / %0d FAIL", pass_count, fail_count);
        end

        $display("Regression: %0d PASS / %0d FAIL", pass_count, fail_count);
        if (fail_count > 0)
            $fatal("Correct key causes corruption — lock is broken");

        $finish;
    end
endmodule