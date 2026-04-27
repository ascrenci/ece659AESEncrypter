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
    localparam sar_key_t CORRECT_KEY = "testingaessarkey";
    key_t expanded_key;
    key_t scrambled_key_reg;
    logic [3:0] byte_ctr;
    logic [7:0] sbox_in, sbox_out;

    assign key_to_expand = (current_state == INIT) ? bus.key : key_reg;

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
            INIT:   begin
                if (byte_ctr == 4'd15) next_state = ROUNDS;
                else next_state = INIT;
            end
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

    /*
    always_comb begin
        expanded_key_clean = bus.sar_key ^ CORRECT_KEY;
        expanded_key = {expanded_key_clean[95:0], expanded_key_clean[127:96]};
        for (int i = 0; i < 16; i++) begin
            scrambled_key[127 - i*8 -: 8] = (expanded_key[127 - i*8 -: 8] == 8'h00) ? 8'h00: AES_SBOX[expanded_key[127 - i*8 -: 8]];
        end
    end*/

    assign expanded_key = bus.sar_key^CORRECT_KEY;
    always_comb begin
        sbox_in = expanded_key[127 - byte_ctr*8 -: 8];
        sbox_out = (sbox_in == 8'h00) ? 8'h00: AES_SBOX[sbox_in];
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= '0;
            key_reg   <= '0;
            round_ctr <= 4'd0;
            scrambled_key_reg <= '0;
            byte_ctr <= '0;
        end else begin
            case (current_state)
                IDLE: begin
                    round_ctr <= 4'd0;
                    byte_ctr <= '0;
                end
                INIT: begin
                    if (byte_ctr < 4'd15) begin
                        scrambled_key_reg <= {scrambled_key_reg[119:0], sbox_out};
                        //shifting_key <= {shifting_key[119:0], 8'h00};
                        byte_ctr <= byte_ctr + 1;
                    end 
                    if (byte_ctr == 4'd15) begin
                        state_reg <= bus.plaintext ^ bus.key;
                        key_reg   <= next_key; 
                        round_ctr <= 4'd1;
                    end
                end
                ROUNDS, FINAL: begin
                    state_reg <= round_out^scrambled_key_reg;
                    key_reg   <= next_key; 
                    round_ctr <= round_ctr + 1;
                end
                default: ; 
            endcase
        end
    end

    assign bus.ciphertext = state_reg;

endmodule