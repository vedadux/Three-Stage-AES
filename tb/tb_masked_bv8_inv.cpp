#include <verilated.h>
#include "Vmasked_bv8_inv.h"
#include "gf_operations.h"

#include <iostream>
#include <cstdio>
#include <cassert>
#include <random>

template<typename T>
void tick(T* dut)
{
    dut->in_clock = 1;
    dut->eval();
    dut->in_clock = 0;
    dut->eval();
}

template<typename T>
void reset(T* dut)
{
    dut->in_reset = 1;
    dut->eval();
    tick(dut);
    dut->in_reset = 0;
    dut->eval();
    tick(dut);
}

int main(int argc, char** argv) 
{
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);

    // Create an instance of the DUT module
    Vmasked_bv8_inv* dut = new Vmasked_bv8_inv;

    // Create a randomness source
    std::random_device rd;
    
    // Create a pseudo-random generator
    std::mt19937_64 gen(rd());

    printf("uint8_t bv8_inv[256] = {\n    ");
    for (uint32_t input = 0; input < 256; input += 1)
    {
        std::printf("0x%02lx, ", gf_256_inv_canright(input));
        if (input % 16 == 15) printf("\n    ");
    }
    printf("};\n");

    // Test every possible input value for in_a
    for (uint32_t run_id = 0; run_id < 100; run_id += 1)
    for (uint32_t input = 0; input < 256; input++) 
    {
        uint32_t expected = gf_256_inv_canright(input);
        
        // Set input value
        reset(dut);

        dut->in_random = gen();
        dut->in_a = input;
        dut->eval();

        for (int time = 0; time < 3; time++)
        {
            dut->in_random = gen();
            dut->eval();
            tick(dut);
        }
        
        uint32_t shares[2];
        uint32_t output = 0;
        for (int i = 0; i < 2; i++)
        {
            shares[i] = ((dut->out_b) >> (8 * i)) & 0xff;
            output ^= shares[i];
        }
        
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