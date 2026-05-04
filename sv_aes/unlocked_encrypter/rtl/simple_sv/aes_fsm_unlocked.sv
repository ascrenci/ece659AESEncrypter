module aes_fsm_unlocked (
    input logic clk,
    input logic rst,
    input aes_pkg::signal_t start,
    input aes_pkg::state_t plaintext,
    input aes_pkg::key_t key,
    output aes_pkg::state_t ciphertext,
    output aes_pkg::signal_t ready
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

    assign key_to_expand = (current_state == INIT) ? key : key_reg;

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
        ready = 1'b0;

        case (current_state)
            IDLE:   if (start) next_state = INIT;
            INIT:   next_state = ROUNDS;
            ROUNDS: if (round_ctr >= 4'd9) next_state = FINAL;
                    else                   next_state = ROUNDS;
            FINAL:  begin
                skip_mc = 1'b1;
                next_state = DONE;
            end
            DONE:   begin
                ready = 1'b1;
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= '0;
            key_reg   <= '0;
            round_ctr <= 4'd0;
        end else begin
            case (current_state)
                IDLE: begin
                    round_ctr <= 4'd0;
                end
                INIT: begin
                    state_reg <= plaintext ^ key;
                    key_reg   <= next_key; 
                    round_ctr <= 4'd1;
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

    assign ciphertext = state_reg;

endmodule