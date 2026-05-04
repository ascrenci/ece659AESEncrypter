module aes_fsm_locked (
    input logic clk,
    input logic rst,
    aes_if.dut bus
);
    import aes_pkg::*;

    typedef enum logic [2:0] {IDLE, INIT, ROUNDS, FINAL, DONE} state_e;
    state_e current_state, next_state;

    state_t state_reg;
    key_t key_reg;
    logic [3:0] round_ctr;

    key_t key_to_expand;
    key_t next_key;
    state_t round_out;
    logic skip_mc;

    // SAR Lock Vars
    localparam sat_key_t CORRECT_KEY = "testingaessarkey";
    logic [1:0] sat_round;
    key_t key_mask;

    assign key_to_expand = (current_state == INIT) ? (bus.key^key_mask) : key_reg;

    key_expansion u_key_expansion (
        .round_num(round_ctr),
        .key_in(key_to_expand),
        .key_out(next_key)
    );

    aes_round u_aes_round (
        .state_in(state_reg),
        .round_key(key_reg),
        .skip_mix_col(skip_mc),
        .state_out(round_out)
    );

    always_ff @(posedge clk) begin
        if (rst) current_state <= IDLE;
        else     current_state <= next_state;
    end

    always_comb begin
        next_state = current_state;
        skip_mc = 1'b0;
        bus.ready = 1'b0;

        case (current_state)
            IDLE:   if (bus.start) next_state = INIT;
            INIT: if (sat_round <= 2'd1) next_state = INIT;
                  else                next_state = ROUNDS;
            ROUNDS: if (round_ctr >= 4'd9) next_state = FINAL;
                    else                   next_state = ROUNDS;
            FINAL:  begin
                skip_mc = 1'b1;
                next_state = DONE;
            end
            DONE:   begin
                bus.ready = 1'b1;
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    assign key_mask = (sat_round == 2) ? (round_out ^ 128'hbfa63cc726e34ac88d8a2abf025113f2): 128'h0;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= '0;
            key_reg   <= '0;
            round_ctr <= 4'd0;
            sat_round <= 2'd0;
        end else begin
            case (current_state)
                IDLE: begin
                    round_ctr <= 4'd0;
                    sat_round <= 2'd0;
                end
                INIT: begin
                    if (sat_round == 2'd0) begin
                        state_reg <= bus.sat_key;
                        key_reg <= bus.sat_key;
                        sat_round <= sat_round + 1;
                    end else
                    if (sat_round == 1) begin
                        state_reg <= round_out;
                        key_reg <= bus.sat_key;
                        sat_round <= sat_round + 1;
                    end else if (sat_round == 2) begin
                        state_reg <= bus.plaintext ^ bus.key;
                        key_reg   <= next_key; 
                        round_ctr <= 4'd1;
                        sat_round <= 2'd0;
                    end
                end
                ROUNDS, FINAL: begin
                    state_reg <= round_out;
                    key_reg   <= next_key; 
                    round_ctr <= round_ctr + 1;
                end
                default: ; 
            endcase
        end
    end

    assign bus.ciphertext = state_reg;

endmodule