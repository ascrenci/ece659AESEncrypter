#!/bin/tcsh

set PLAINTEXT = `printf 00112233445566778899AABBCCDDEEFF | xxd -r -p` #"testingaes123456"
set AES_KEY   = `printf 000102030405060708090A0B0C0D0E0F | xxd -r -p` #"ascrenci33882356"

printf $PLAINTEXT | openssl enc -aes-128-ecb -K `printf $AES_KEY | xxd -p` -nosalt -nopad | xxd -p


#set CIPHERTEXT = "44f43f501c0cc07af19c621243fe01c0"
#printf $CIPHERTEXT | xxd -r -p | openssl enc -aes-128-ecb -d -K `printf $AES_KEY | xxd -p` -nosalt -nopad