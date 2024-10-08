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

`ifndef MASKED_TEST_HPC1_AND_SHARED0_SV
`define MASKED_TEST_HPC1_AND_SHARED0_SV

`include "aes128_package.sv"
`include "masked_hpc1_mul.sv"
`include "masked_zero.sv"

module masked_test_hpc1_and_shared0 #(
    parameter NUM_SHARES = 2,
    parameter BIT_WIDTH = 4
)(
    in_a_t1, in_b_t0, in_r_raw, in_p, out_c, in_clock, in_reset
);
    import aes128_package::*;
    localparam NUM_QUADRATIC = num_quad(NUM_SHARES);
    localparam NUM_ZERO_RANDOM = num_zero_random(NUM_SHARES);
    typedef bit[BIT_WIDTH-1:0] T;

    input  T[NUM_SHARES-1:0] in_a_t1;
    input  T[NUM_SHARES-1:0] in_b_t0;
    input  T[NUM_ZERO_RANDOM-1:0] in_r_raw;
    input  T[NUM_QUADRATIC-1:0] in_p;
    output T[NUM_SHARES-1:0] out_c;
    input in_clock;
    input in_reset;
    
    T[NUM_SHARES-1:0] r_ab;

    masked_zero #(
        .NUM_SHARES(NUM_SHARES), 
        .BIT_WIDTH(BIT_WIDTH)
    ) shared_0_b (
        .in_random(in_r_raw),
        .out_random(r_ab),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    
    // Multiply B and A
    masked_hpc1_mul #(
        .NUM_SHARES(NUM_SHARES),
        .BIT_WIDTH(BIT_WIDTH)
    ) mul1 (
        .in_a(in_a_t1),
        .in_b(in_b_t0),
        .in_r(r_ab),
        .in_p(in_p),
        .out_c(out_c),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
endmodule: masked_test_hpc1_and_shared0
`endif // MASKED_TEST_HPC1_AND_SHARED0_SV
