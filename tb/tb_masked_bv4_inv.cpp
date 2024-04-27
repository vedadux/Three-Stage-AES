#include <verilated.h>
#include "Vmasked_bv4_inv.h"
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

void set_randoms(std::mt19937_64& gen, uint8_t* ptr, uint64_t size)
{
    for (int i = 0; i < size / sizeof(uint8_t); i += 1)
    {
        ptr[i] = gen();
    }
}

int main(int argc, char** argv) 
{
    printf("NUM_SHARES: %d\n", NUM_SHARES);
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);

    // Create an instance of the DUT module
    Vmasked_bv4_inv* dut = new Vmasked_bv4_inv;
    printf("Size of in_random: %ld\n", sizeof(dut->in_random));

    // Create a randomness source
    std::random_device rd;
    
    // Create a pseudo-random generator
    std::mt19937_64 gen(rd());

    printf("uint8_t bv4_inv_canright[16] = {\n    ");
    for (uint32_t input = 0; input < 16; input += 1)
    {
        std::printf("0x%02lx, ", gf_16_inv_canright(input));
    }
    printf("};\n");
    printf("uint8_t bv4_inv_new[16] = {\n    ");
    for (uint32_t input = 0; input < 16; input += 1)
    {
        std::printf("0x%02lx, ", gf_16_inv_new(input));
    }
    printf("};\n");

    // Test every possible input value for in_a
    for (uint32_t run_id = 0; run_id < 100; run_id += 1)
    for (uint32_t input = 0; input < 16; input++) 
    {
        uint32_t expected = gf_16_inv_canright(input);
        
        // Set input value
        reset(dut);

        uint8_t in_shares[NUM_SHARES];
        uint8_t share_xor = 0;
        for (int i = 0; i < NUM_SHARES - 1; i++)
        {
            in_shares[i] = gen() & 0xf;
            share_xor ^= in_shares[i];
        }
        in_shares[NUM_SHARES-1] = share_xor ^ input;

        set_randoms(gen, (uint8_t*)(&(dut->in_random)), sizeof(dut->in_random));

        dut->in_x = 0;
        for (int i = 0; i < NUM_SHARES; i++)
        {
            dut->in_x |= (uint64_t)(in_shares[i]) << (uint64_t)(i*4);
        }
        dut->eval();

        for (int time = 0; time < 2; time++)
        {
            set_randoms(gen, (uint8_t*)(&(dut->in_random)), sizeof(dut->in_random));
            dut->eval();
            tick(dut);
        }
        
        uint32_t out_shares[NUM_SHARES];
        uint32_t output = 0;
        for (int i = 0; i < NUM_SHARES; i++)
        {
            out_shares[i] = ((dut->out_y) >> (4 * i)) & 0xf;
            output ^= out_shares[i];
        }
        
        // Check if the output matches the expected value
        if (output != expected)
        {
            // Test failed
            printf("Test failed %x: %x != %x\n", input, output, expected);
            printf("%x: %x\n", dut->in_x, dut->out_y);
            
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