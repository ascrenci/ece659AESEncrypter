module dip_oracle_tb;
    import aes_pkg::*;

    logic clk = 0, rst = 1;

    // Two identical DUTs — one with correct key, one with candidate
    aes_if bus_correct(), bus_candidate();
    aes_fsm_unlocked dut_c (.clk(clk), .rst(rst), .bus(bus_correct));
    aes_fsm dut_a (.clk(clk), .rst(rst), .bus(bus_candidate));

    always #5 clk = ~clk;

    // Shared stimulus — same plaintext and AES key to both
    state_t shared_pt;
    key_t   shared_k;
    assign bus_correct.plaintext   = shared_pt;
    assign bus_correct.key         = shared_k;
    assign bus_candidate.plaintext = shared_pt;
    assign bus_candidate.key       = shared_k;

    // Fixed correct key vs. swept attacker key
    assign bus_correct.sar_key   = 8'hAA;  // CORRECT_KEY
    sar_key_t attacker_key;
    assign bus_candidate.sar_key = attacker_key;

    // -------------------------------------------------------
    // Metrics
    // -------------------------------------------------------
    int total_queries;
    int dip_count;
    int zero_trap_hits;  // track predictable fallback triggers
    
    // Per-key DIP tracking for distribution analysis
    int dip_histogram [int];

    logic dip_detected;
    assign dip_detected = bus_correct.ready && bus_candidate.ready &&
                          (bus_correct.ciphertext != bus_candidate.ciphertext);

    task run_pair(
        input state_t pt,
        input key_t k,
        input sar_key_t sk
    );
        // Synchronous start
        @(posedge clk); rst = 1;
        repeat(5) @(posedge clk); rst = 0;

        @(negedge clk);
        shared_pt    = pt;
        shared_k     = k;
        attacker_key = sk;
        bus_correct.start   = 1;
        bus_candidate.start = 1;
        @(posedge clk);
        #1 bus_correct.start   = 0;
        #1 bus_candidate.start = 0;

        // Wait for both to complete
        do @(posedge clk); while (!bus_correct.ready);
        //$display("Correct Cipher:   %h", bus_correct.ciphertext);
        //$display("Candidate Cipher: %h", bus_candidate.ciphertext);
        //$display("Sar key used:     %h", sk);
        //@(posedge bus_candidate.ready);
        total_queries++;

        if (dip_detected) begin
            dip_count++;
            if (!dip_histogram.exists(int'(sk)))
                dip_histogram[int'(sk)] = 0;
            dip_histogram[int'(sk)]++;

            $display("[DIP %0d] pt=%h k=%h sk=%h | correct=%h candidate=%h",
                dip_count, pt, k, sk,
                bus_correct.ciphertext, bus_candidate.ciphertext);
        end
    endtask

    // -------------------------------------------------------
    // Phase 1: Fixed-PT sweep (worst-case adversary model)
    // Attacker fixes plaintext, sweeps all sar_key values
    // -------------------------------------------------------
    task phase1_fixed_pt_sweep;
        automatic state_t fixed_pt = 128'h0;
        automatic key_t   fixed_k  = 128'h0;
        $display("\n=== Phase 1: Fixed PT sweep ===");

        for (int sk = 0; sk <= 8'hFF; sk++) begin  // sample first 64K
            run_pair(fixed_pt, fixed_k, sar_key_t'(sk));
            //$display("sk: %h", sk);
        end

        $display("Phase 1 complete: %0d DIPs in first 64K keys", dip_count);
        // Expected: exactly 1 DIP at trap_key for (fixed_pt, fixed_k)
        // If > 1: multiple keys trigger corruption = weak lock
        // If 0:   corruption unreachable = non-functional lock
    endtask

    // -------------------------------------------------------
    // Phase 2: Random-PT sweep (general attacker model)
    // Mimics SAT solver iterating with random DIPs
    // -------------------------------------------------------
    int dip_start;
    task phase2_random_sweep;
        $display("\n=== Phase 2: Random PT/Key sweep ===");
        dip_start = dip_count;

        repeat(100000) begin
            automatic state_t pt  = {$urandom,$urandom,$urandom,$urandom};
            automatic key_t   k   = {$urandom,$urandom,$urandom,$urandom};
            automatic sar_key_t sk = $urandom;
            run_pair(pt, k, sk);
        end

        $display("Phase 2: %0d new DIPs in 100K random queries",
                 dip_count - dip_start);
        // DIP rate ≈ (dip_count - dip_start) / 100000
        // Ideal rate ≈ 1/2^32 per query ≈ ~0.000023%
        // High rate indicates many keys cause corruption = SAT-weak
    endtask

    // -------------------------------------------------------
    // Phase 3: Zero-trap targeting
    // Craft plaintexts where pk_state folds to 0
    // -------------------------------------------------------
    
    task phase3_zero_trap;
        automatic sar_key_t static_trap = 8'h11;  // CORRECT_KEY ^ 32'h01234567
        $display("\n=== Phase 3: Zero-trap key test ===");

        // Try 1000 plaintexts where attacker submits the static trap key
        repeat(1000) begin
            automatic state_t pt = {$urandom,$urandom,$urandom,$urandom};
            automatic key_t   k  = {$urandom,$urandom,$urandom,$urandom};
            run_pair(pt, k, static_trap);
        end

        $display("Phase 3: Zero-trap triggered %0d / 1000 times",
                 dip_count);
        // If this is non-zero, the zero-fallback is exploitable
    endtask
    

    // -------------------------------------------------------
    // Report
    // -------------------------------------------------------
    task print_report;
        real dip_rate;
        dip_rate = 100.0 * dip_count / total_queries;

        $display("\n======= SAT HARDINESS REPORT =======");
        $display("Total queries:     %0d",    total_queries);
        $display("Total DIPs found:  %0d",    dip_count);
        $display("DIP rate:          %.6f%%", dip_rate);
        $display("Unique DIP keys:   %0d",    dip_histogram.size());
        $display("");
        $display("Hardiness Rating:");
        if (dip_rate < 0.0001)
            $display("  STRONG  — DIP rate consistent with 1/2^32");
        else if (dip_rate < 0.01)
            $display("  MODERATE — elevated DIP rate, review compression");
        else
            $display("  WEAK    — too many keys trigger corruption");
        $display("=====================================\n");
    endtask

    initial begin
        rst = 1; repeat(4) @(posedge clk); rst = 0;
        total_queries = 0; dip_count = 0;

        phase1_fixed_pt_sweep();
        phase2_random_sweep();
        //phase3_zero_trap();
        print_report();
        $finish;
    end
endmodule