#include <verilated.h>
#include "Vbv8_back_basis.h"
#include "gf_operations.h"

#include <iostream>
#include <cstdio>
#include <cassert>

int main(int argc, char** argv) 
{
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);

    // Create an instance of the DUT module
    Vbv8_back_basis* dut = new Vbv8_back_basis;

    // Test every possible input value for in_a
    for (uint32_t input = 0; input < 256; input++) {
        // Set input value
        dut->in_x = input;

        // Evaluate the DUT
        dut->eval();

        uint32_t exp_l = gf_256_switch_basis(input, X2S);
        uint32_t exp_h = gf_256_switch_basis(input, X2A);
        uint32_t expected = (exp_h << 8) | (exp_l << 0);
        uint32_t out_l = dut->out_fwd;
        uint32_t out_h = dut->out_bwd;
        uint32_t output = (out_h << 8) | (out_l << 0);

        // Check if the output matches the expected value
        if (output != expected)
        {
            // Test failed
            printf("Test failed %02x: %04x != %04x\n", input, output, expected);
            // Exit with failure
            exit(1);
        }
    }

    // All tests passed
    printf("All tests passed!\n");

    // Delete the DUT instance
    delete dut;

    // Exit with success
    exit(0);
}