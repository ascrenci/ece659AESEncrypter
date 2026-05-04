module aes_fsm_locked (
    input logic clk,
    input logic rst,
    input logic start,
    input logic [127:0] plaintext,
    input logic [127:0] key,
    input logic [127:0] sat_key,
    output logic [127:0] ciphertext,
    output logic ready
);
    typedef logic [7:0] byte_t;
    localparam byte_t AES_SBOX [0:255] = '{
        8'h63, 8'h7c, 8'h77, 8'h7b,
        8'hf2, 8'h6b, 8'h6f, 8'hc5,
        8'h30, 8'h01, 8'h67, 8'h2b,
        8'hfe, 8'hd7, 8'hab, 8'h76,
        8'hca, 8'h82, 8'hc9, 8'h7d,
        8'hfa, 8'h59, 8'h47, 8'hf0,
        8'had, 8'hd4, 8'ha2, 8'haf,
        8'h9c, 8'ha4, 8'h72, 8'hc0,
        8'hb7, 8'hfd, 8'h93, 8'h26,
        8'h36, 8'h3f, 8'hf7, 8'hcc,
        8'h34, 8'ha5, 8'he5, 8'hf1,
        8'h71, 8'hd8, 8'h31, 8'h15,
        8'h04, 8'hc7, 8'h23, 8'hc3,
        8'h18, 8'h96, 8'h05, 8'h9a,
        8'h07, 8'h12, 8'h80, 8'he2,
        8'heb, 8'h27, 8'hb2, 8'h75,
        8'h09, 8'h83, 8'h2c, 8'h1a,
        8'h1b, 8'h6e, 8'h5a, 8'ha0,
        8'h52, 8'h3b, 8'hd6, 8'hb3,
        8'h29, 8'he3, 8'h2f, 8'h84,
        8'h53, 8'hd1, 8'h00, 8'hed,
        8'h20, 8'hfc, 8'hb1, 8'h5b,
        8'h6a, 8'hcb, 8'hbe, 8'h39,
        8'h4a, 8'h4c, 8'h58, 8'hcf,
        8'hd0, 8'hef, 8'haa, 8'hfb,
        8'h43, 8'h4d, 8'h33, 8'h85,
        8'h45, 8'hf9, 8'h02, 8'h7f,
        8'h50, 8'h3c, 8'h9f, 8'ha8,
        8'h51, 8'ha3, 8'h40, 8'h8f,
        8'h92, 8'h9d, 8'h38, 8'hf5,
        8'hbc, 8'hb6, 8'hda, 8'h21,
        8'h10, 8'hff, 8'hf3, 8'hd2,
        8'hcd, 8'h0c, 8'h13, 8'hec,
        8'h5f, 8'h97, 8'h44, 8'h17,
        8'hc4, 8'ha7, 8'h7e, 8'h3d,
        8'h64, 8'h5d, 8'h19, 8'h73,
        8'h60, 8'h81, 8'h4f, 8'hdc,
        8'h22, 8'h2a, 8'h90, 8'h88,
        8'h46, 8'hee, 8'hb8, 8'h14,
        8'hde, 8'h5e, 8'h0b, 8'hdb,
        8'he0, 8'h32, 8'h3a, 8'h0a,
        8'h49, 8'h06, 8'h24, 8'h5c,
        8'hc2, 8'hd3, 8'hac, 8'h62,
        8'h91, 8'h95, 8'he4, 8'h79,
        8'he7, 8'hc8, 8'h37, 8'h6d,
        8'h8d, 8'hd5, 8'h4e, 8'ha9,
        8'h6c, 8'h56, 8'hf4, 8'hea,
        8'h65, 8'h7a, 8'hae, 8'h08,
        8'hba, 8'h78, 8'h25, 8'h2e,
        8'h1c, 8'ha6, 8'hb4, 8'hc6,
        8'he8, 8'hdd, 8'h74, 8'h1f,
        8'h4b, 8'hbd, 8'h8b, 8'h8a,
        8'h70, 8'h3e, 8'hb5, 8'h66,
        8'h48, 8'h03, 8'hf6, 8'h0e,
        8'h61, 8'h35, 8'h57, 8'hb9,
        8'h86, 8'hc1, 8'h1d, 8'h9e,
        8'he1, 8'hf8, 8'h98, 8'h11,
        8'h69, 8'hd9, 8'h8e, 8'h94,
        8'h9b, 8'h1e, 8'h87, 8'he9,
        8'hce, 8'h55, 8'h28, 8'hdf,
        8'h8c, 8'ha1, 8'h89, 8'h0d,
        8'hbf, 8'he6, 8'h42, 8'h68,
        8'h41, 8'h99, 8'h2d, 8'h0f,
        8'hb0, 8'h54, 8'hbb, 8'h16
    };

    typedef enum logic [2:0] {IDLE, INIT, ROUNDS, FINAL, DONE} state_e;
    state_e current_state, next_state;

    logic [127:0] state_reg;
    logic [127:0] key_reg;
    logic [3:0] round_ctr;

    logic [127:0] key_to_expand;
    logic [127:0] next_key;
    logic [127:0] round_out;
    logic skip_mc;

    // SAR Lock Vars
    localparam logic [127:0] CORRECT_KEY = "testingaessarkey";
    logic [1:0] sat_round;
    logic [127:0] key_mask;

    assign key_to_expand = (current_state == INIT) ? (key^key_mask) : key_reg;

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
            INIT: if (sat_round <= 1) next_state = INIT;
                  else                next_state = ROUNDS;
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

    assign key_mask = (sat_round == 2) ? (round_out ^ 128'hbfa63cc726e34ac88d8a2abf025113f2): 128'h0;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_reg <= '0;
            key_reg   <= '0;
            round_ctr <= 4'd0;
            sat_round <= 0;
        end else begin
            case (current_state)
                IDLE: begin
                    round_ctr <= 4'd0;
                    sat_round <= 0;
                end
                INIT: begin
                    if (sat_round == 0) begin
                        state_reg <= sat_key;
                        key_reg <= sat_key;
                        sat_round <= sat_round + 1;
                    end else
                    if (sat_round < 2) begin
                        state_reg <= round_out;
                        key_reg <= sat_key;
                        sat_round <= sat_round + 1;
                    end else begin
                        state_reg <= plaintext ^ key;
                        key_reg   <= next_key; 
                        round_ctr <= 4'd1;
                        sat_round <= 0;
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

    assign ciphertext = state_reg;

endmodule