#include <verilated.h>
#include "Vbv8_inv.h"

int main(int argc, char** argv) {
    // Initialize Verilator
    Verilated::commandArgs(argc, argv);

    // Create an instance of the DUT module
    Vbv8_inv* dut = new Vbv8_inv;

    // Test every possible input value for in_a
    for (int i = 0; i < 256; i++) {
        // Set input value
        dut->in_a = i;

        // Evaluate the DUT
        dut->eval();

        // Check if the output matches the expected value
        if (dut->out_b != ~dut->in_a) {
            // Test failed
            printf("Test failed: in_a = %d, expected out_b = %d, actual out_b = %d\n", dut->in_a, ~dut->in_a, dut->out_b);
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