#include <verilated.h>
#include "Vaes_sbox.h"
#include "gf_operations.h"

#include <iostream>
#include <cstdio>
#include <cassert>

int main(int argc, char** argv) 
{
    for (uint64_t sbox_in = 0; sbox_in < 256; sbox_in += 1)
    {
        uint64_t sbox_out = aes_sbox(sbox_in, gf_256_inv_canright);
        assert(sbox_out == AES_SBOX_TABLE[sbox_in]);
        uint64_t inv_sbox_out = aes_inv_sbox(sbox_in, gf_256_inv_canright);
        assert(sbox_in == AES_SBOX_TABLE[inv_sbox_out]);
    }

    // Initialize Verilator
    Verilated::commandArgs(argc, argv);

    // Create an instance of the DUT module
    Vaes_sbox* dut = new Vaes_sbox;

    const char* dir_strs[2] = {"Backward", "Forward"};
    for (uint32_t direction = 0; direction <= 1; direction++)
    {
        for (uint32_t input = 0; input < 256; input++) {
            // Set input value
            dut->in_a = input;
            dut->in_enc = direction;

            // Evaluate the DUT
            dut->eval();

            uint32_t expected = direction ? aes_sbox(input) : aes_inv_sbox(input);
            uint32_t output = dut->out_b;
            
            // Check if the output matches the expected value
            if (output != expected)
            {
                // Test failed
                printf("Forward test failed %02x: %02x != %02x\n", input, output, expected);
                // Exit with failure
                exit(1);
            }
        }
        // All tests passed
        printf("%s: All tests passed!\n", dir_strs[direction]);
    }
    // Delete the DUT instance
    delete dut;

    // Exit with success
    exit(0);
}