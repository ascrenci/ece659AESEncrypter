module wrapper_unlocked (
    input  logic                  clk,
    input  logic                  rst,
    input  aes_pkg::state_t       plaintext,
    input  aes_pkg::key_t         key,
    input  aes_pkg::signal_t      start,
    output aes_pkg::state_t       ciphertext,
    output aes_pkg::signal_t      ready
);
    import aes_pkg::*;

    aes_if bus();

    assign bus.plaintext = plaintext;
    assign bus.key       = key;
    assign bus.start     = start;
    assign ciphertext    = bus.ciphertext;
    assign ready         = bus.ready;

    aes_fsm_unlocked dut (
        .clk(clk),
        .rst(rst),
        .bus(bus.dut)
    );
endmodule