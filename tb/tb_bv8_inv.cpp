#include <verilated.h>
#include "Vbv8_inv.h"
#include "gf_operations.h"

#include <iostream>
#include <cstdio>
#include <cassert>

int main(int argc, char** argv) 
{
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);

    // Create an instance of the DUT module
    Vbv8_inv* dut = new Vbv8_inv;

    // Test every possible input value for in_a
    for (uint32_t input = 0; input < 256; input++) {
        // Set input value
        dut->in_a = input;

        // Evaluate the DUT
        dut->eval();

        uint32_t expected = gf_256_inv_canright(input);
        uint32_t output = dut->out_b;
        
        // Check if the output matches the expected value
        if (output != expected)
        {
            // Test failed
            printf("Test failed %02x: %02x != %02x\n", input, output, expected);
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