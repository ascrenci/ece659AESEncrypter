`timescale 1ns/1ps


module aes_tb;

reg  [127:0] plaintext;
reg  [127:0] key;
reg    [7:0] sar_key;
wire [127:0] ciphertext;


// Top level module
aes_encrypt_128 dut (
    .plaintext(plaintext),
    .key(key),
    .ciphertext(ciphertext)
);


// Expected output from AES standard test vector
reg [127:0] expected_ciphertext;

// Corrupted output, not printed for user just here for me to visually inspect and
// compare to corrupted output across different trials
reg [127:0] corrupted_output;

initial begin

                //16bytesrulerhere
    plaintext =  "testingaes123456";
    key       =  "ascrenci33882356";
    sar_key   =  8'hAA;

    expected_ciphertext = 128'h44f43f501c0cc07af19c621243fe01c0;

    #1;

    $display("Plaintext  : %s", plaintext);
    $display("Key        : %s", key);
    $display("SAR Key    : %h", sar_key);
    $display("Ciphertext : %h", ciphertext);
    $display("Expected   : %h", expected_ciphertext);

    if (ciphertext == expected_ciphertext)
        $display("TEST PASSED");
    else
        $display("TEST FAILED");

    $finish;

end

endmodule