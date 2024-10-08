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

`ifndef MASKED_3STAGE_BV8_INV_STAGE2_HPC3_SV
`define MASKED_3STAGE_BV8_INV_STAGE2_HPC3_SV

`include "aes128_package.sv"
`include "masked_bv4_comp_theta.sv"
`include "masked_hpc3_1_mul.sv"

// Compute second stage of masked GF(2^8) Inverse
module masked_3stage_bv8_inv_stage2_hpc3 (
    in_a0_t1, in_a1_t1, in_pow4_t1, in_random, out_theta_t2, out_mul_a0_t2, out_mul_a1_t2, in_clock, in_reset
);
    import aes128_package::*;
    parameter NUM_SHARES = 2;
    localparam NUM_QUARDATIC = num_quad(NUM_SHARES);
    localparam NUM_RANDOM = stage_2_hpc3_randoms(NUM_SHARES);
    
    input  bv4_t[NUM_SHARES-1:0] in_a0_t1;
    input  bv4_t[NUM_SHARES-1:0] in_a1_t1;
    input  bv4_t[NUM_SHARES-1:0] in_pow4_t1;
    input    bit[NUM_RANDOM-1:0] in_random;
    output bv2_t[NUM_SHARES-1:0] out_theta_t2;
    output bv4_t[NUM_SHARES-1:0] out_mul_a0_t2;
    output bv4_t[NUM_SHARES-1:0] out_mul_a1_t2;
    input                    bit in_clock;
    input                    bit in_reset;

    bv4_t[NUM_QUARDATIC-1:0] joint_r;
    bv2_t[NUM_QUARDATIC-1:0] theta_p;
    bv4_t[NUM_QUARDATIC-1:0] right_p;
    bv4_t[NUM_QUARDATIC-1:0] left_p;
    
    assign {left_p, right_p, theta_p, joint_r} = in_random;

    /* verilator lint_off UNUSEDSIGNAL */
    bv2_t[1:0][NUM_QUARDATIC-1:0] joint_split;
    /* verilator lint_on UNUSEDSIGNAL */

    masked_split_bv #(
        .NUM_SHARES(NUM_QUARDATIC),
        .HALF_WIDTH(2)
    ) split (
        .in_a(joint_r),
        .out_b(joint_split)
    );

    bv2_t[1:0][NUM_QUARDATIC-1:0] theta_random;
    assign theta_random = {theta_p, joint_split[0]};

    masked_bv4_comp_theta #(
        .NUM_SHARES(NUM_SHARES)
    ) c_theta (
        .in_a(in_pow4_t1), 
        .in_random(theta_random), 
        .out_b(out_theta_t2),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    
    masked_hpc3_1_mul #(
        .NUM_SHARES(NUM_SHARES), 
        .BIT_WIDTH(4)
    ) mul_left (
        .in_a(in_a0_t1), 
        .in_b(in_pow4_t1),
        .in_r(joint_r),
        .in_p(left_p), 
        .out_c(out_mul_a0_t2),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    
    masked_hpc3_1_mul #(
        .NUM_SHARES(NUM_SHARES), 
        .BIT_WIDTH(4)
    ) mul_right (
        .in_a(in_a1_t1), 
        .in_b(in_pow4_t1),
        .in_r(joint_r),
        .in_p(right_p), 
        .out_c(out_mul_a1_t2),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
endmodule : masked_3stage_bv8_inv_stage2_hpc3
`endif // MASKED_3STAGE_BV8_INV_STAGE2_HPC3_SV
