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

`ifndef TEST_SV
`define TEST_SV

`include "aes128_package.sv"
`include "masked_hpc3_1_mul.sv"

module test #(
    parameter NUM_SHARES = 3,
    parameter BIT_WIDTH = 1
)(
    in_a, in_b, in_c, in_r_ab, in_r_ac, in_p_ab, in_p_ac, out_d, out_e, in_clock, in_reset
);
    import aes128_package::*;
    localparam NUM_QUADRATIC = num_quad(NUM_SHARES);
    typedef bit[BIT_WIDTH-1:0] T;

    input  T[NUM_SHARES-1:0] in_a;
    input  T[NUM_SHARES-1:0] in_b;
    input  T[NUM_SHARES-1:0] in_c;
    input  T[NUM_QUADRATIC-1:0] in_r_ab;
    input  T[NUM_QUADRATIC-1:0] in_r_ac;
    input  T[NUM_QUADRATIC-1:0] in_p_ab;
    input  T[NUM_QUADRATIC-1:0] in_p_ac;
    output T[NUM_SHARES-1:0] out_d;
    output T[NUM_SHARES-1:0] out_e;
    input in_clock;
    input in_reset;
    
    // Multiply B and A
    masked_hpc3_1_mul #(
        .NUM_SHARES(NUM_SHARES),
        .BIT_WIDTH(BIT_WIDTH)
    ) mul1 (
        .in_a(in_b),
        .in_b(in_a),
        .in_r(in_r_ab),
        .in_p(in_p_ab),
        .out_c(out_d),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    // Multiply C and A
    masked_hpc3_1_mul #(
        .NUM_SHARES(NUM_SHARES),
        .BIT_WIDTH(BIT_WIDTH)
    ) mul2 (
        .in_a(in_c),
        .in_b(in_a),
        .in_r(in_r_ab), // .in_r(in_r_ac),
        .in_p(in_p_ac),
        .out_c(out_e),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    
endmodule
`endif // TEST_SV
