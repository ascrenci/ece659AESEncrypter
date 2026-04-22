`timescale 1ns/1ps

module aes_round (
    input wire [127:0] state_in,
    input wire [127:0] round_key,
    output wire [127:0] state_out
);

    wire [127:0] sub_out;
    wire [127:0] shift_out;
    wire [127:0] mix_out;

    sub_bytes u_sub_bytes (
        .state_in(state_in),
        .state_out(sub_out)
    );

    shift_rows u_shift_rows (
        .state_in(sub_out),
        .state_out(shift_out)
    );

    mix_columns u_mix_columns (
        .state_in(shift_out),
        .state_out(mix_out)
    );

    add_round_key u_add_round_key (
        .state_in(mix_out),
        .round_key(round_key),
        .state_out(state_out)
    );

endmodule

module aes_final_round (
    input wire [127:0] state_in,
    input wire [127:0] round_key,
    output wire [127:0] state_out
);

    wire [127:0] sub_out;
    wire [127:0] shift_out;

    sub_bytes u_sub_bytes (
        .state_in(state_in),
        .state_out(sub_out)
    );

    shift_rows u_shift_rows (
        .state_in(sub_out),
        .state_out(shift_out)
    );

    add_round_key u_add_round_key (
        .state_in(shift_out),
        .round_key(round_key),
        .state_out(state_out)
    );

endmodule