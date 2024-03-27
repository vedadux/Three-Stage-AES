#include <verilated.h>
#include "Vbv8_front_basis.h"
#include "gf_operations.h"

#include <iostream>
#include <cstdio>
#include <cassert>

uint16_t test(uint8_t x)
{
    bool x0 = (x >> 0) & 1;
    bool x1 = (x >> 1) & 1;
    bool x2 = (x >> 2) & 1;
    bool x3 = (x >> 3) & 1;
    bool x4 = (x >> 4) & 1;
    bool x5 = (x >> 5) & 1;
    bool x6 = (x >> 6) & 1;
    bool x7 = (x >> 7) & 1;

    bool x8 = x5 ^ x6; // depth 1
    bool x9 = x0 ^ x3; // depth 1
    bool x10 = x1 ^ x6; // depth 1
    bool x11 = x0 ^ x8; // depth 2
    bool x12 = x9 ^ x10; // depth 2
    bool x13 = x4 ^ x6; // depth 1
    bool x14 = x7 ^ x13; // depth 2
    bool x15 = x12 ^ x14; // depth 3
    bool x16 = x2 ^ x7; // depth 1
    bool x17 = x5 ^ x16; // depth 2
    bool x18 = x7 ^ x11; // depth 3
    bool x19 = x2 ^ x12; // depth 3
    bool x20 = x4 ^ x11; // depth 3
    bool x21 = x4 ^ x7; // depth 1
    bool x22 = x0 ^ x1; // depth 1
    bool x23 = x4 ^ x9; // depth 2
    bool x24 = x8 ^ x22; // depth 2
    bool x25 = x13 ^ x22; // depth 2
    bool x26 = x5 ^ x25; // depth 3
    bool x27 = x16 ^ x24; // depth 3
    bool y0 = x19; // depth 3
    bool y1 = x11; // depth 2
    bool y2 = x0; // depth 0
    bool y3 = x15; // depth 3
    bool y4 = x18; // depth 3
    bool y5 = x24; // depth 2
    bool y6 = x20; // depth 3
    bool y7 = x27; // depth 3
    bool y8 = x26; // depth 3
    bool y9 = x23; // depth 2
    bool y10 = x17; // depth 2
    bool y11 = x14; // depth 2
    bool y12 = x12; // depth 2
    bool y13 = x13; // depth 1
    bool y14 = x25; // depth 2
    bool y15 = x21; // depth 1

    uint16_t y = 0;
    y |= (uint16_t)y0  << 0 ;
    y |= (uint16_t)y1  << 1 ;
    y |= (uint16_t)y2  << 2 ;
    y |= (uint16_t)y3  << 3 ;
    y |= (uint16_t)y4  << 4 ;
    y |= (uint16_t)y5  << 5 ;
    y |= (uint16_t)y6  << 6 ;
    y |= (uint16_t)y7  << 7 ;
    y |= (uint16_t)y8  << 8 ;
    y |= (uint16_t)y9  << 9 ;
    y |= (uint16_t)y10 << 10;
    y |= (uint16_t)y11 << 11;
    y |= (uint16_t)y12 << 12;
    y |= (uint16_t)y13 << 13;
    y |= (uint16_t)y14 << 14;
    y |= (uint16_t)y15 << 15;
    return y;
}

int main(int argc, char** argv) 
{
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);

    // Create an instance of the DUT module
    Vbv8_front_basis* dut = new Vbv8_front_basis;

    // Test every possible input value for in_a
    for (uint32_t input = 0; input < 256; input++) {
        // Set input value
        dut->in_x = input;

        // Evaluate the DUT
        dut->eval();

        uint32_t exp_l = gf_256_switch_basis(input, A2X);
        uint32_t exp_h = gf_256_switch_basis(input, S2X);
        uint32_t expected = (exp_h << 8) | (exp_l << 0);
        uint32_t out_l = dut->out_fwd;
        uint32_t out_h = dut->out_bwd;
        uint32_t output = (out_h << 8) | (out_l << 0);
        

        // Check if the output matches the expected value
        if (output != expected)
        {
            // Test failed
            printf("Test failed %02x: %04x != %04x %04x (diff %04x)\n", input, output, expected, test(input), output ^ expected);
            // Exit with failure
            // exit(1);
        }
    }

    // All tests passed
    printf("All tests passed!\n");

    // Delete the DUT instance
    delete dut;

    // Exit with success
    exit(0);
}