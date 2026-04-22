module aes_encrypt_128 (
    input  wire [127:0] plaintext,
    input  wire [127:0] key,
    output wire [127:0] ciphertext
);
    // key expansion
    wire [1407:0] round_keys;
    key_expansion u_key_expand (
        .key(key),
        .round_keys(round_keys)
    );

    wire [127:0] rk [0:10];
    genvar i;
    generate
        for (i = 0; i < 11; i = i + 1) begin : ROUND_KEY_EXTRACT
            assign rk[i] = round_keys[(1407 - i*128) -: 128];
        end
    endgenerate

    // add initial round key
    wire [127:0] state0;
    add_round_key u_add_round_key0 (
        .state_in(plaintext),
        .round_key(rk[0]),
        .state_out(state0)
    );


    // rounds 1-9
    wire [127:0] state [1:9];
    generate
        for (i = 1; i <= 9; i = i + 1) begin : AES_ROUNDS

            aes_round u_round (
                .state_in((i == 1) ? state0 : state[i-1]),
                .round_key(rk[i]),
                .state_out(state[i])
            );

        end
    endgenerate

    // final round
    aes_final_round u_final_round (
        .state_in(state[9]),
        .round_key(rk[10]),
        .state_out(ciphertext)
    );

endmodule