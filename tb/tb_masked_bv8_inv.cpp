// 
// Copyright (C) 2024 Vedad Hadžić
// 
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
// 

#include <verilated.h>
#include "Vmasked_3stage_bv8_inv.h"
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

#ifndef NUM_SHARES
#define NUM_SHARES 2
#endif

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
    Vmasked_3stage_bv8_inv* dut = new Vmasked_3stage_bv8_inv;
    printf("Size of in_random: %ld\n", sizeof(dut->in_random));

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

        uint8_t in_shares[NUM_SHARES];
        uint8_t share_xor = 0;
        for (int i = 0; i < NUM_SHARES - 1; i++)
        {
            in_shares[i] = gen() & 0xff;
            share_xor ^= in_shares[i];
        }
        in_shares[NUM_SHARES-1] = share_xor ^ input;

        set_randoms(gen, (uint8_t*)(&(dut->in_random)), sizeof(dut->in_random));

        dut->in_a = 0;
        for (int i = 0; i < NUM_SHARES; i++)
        {
            dut->in_a |= (uint64_t)(in_shares[i]) << (uint64_t)(i*8);
        }
        dut->eval();

        for (int time = 0; time < 3; time++)
        {
            set_randoms(gen, (uint8_t*)(&(dut->in_random)), sizeof(dut->in_random));
            dut->eval();
            tick(dut);
        }
        
        uint32_t out_shares[NUM_SHARES];
        uint32_t output = 0;
        for (int i = 0; i < NUM_SHARES; i++)
        {
            out_shares[i] = ((dut->out_b) >> (8 * i)) & 0xff;
            output ^= out_shares[i];
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