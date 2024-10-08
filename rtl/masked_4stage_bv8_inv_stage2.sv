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

`ifndef MASKED_4STAGE_BV8_INV_STAGE2_SV
`define MASKED_4STAGE_BV8_INV_STAGE2_SV

`include "aes128_package.sv"
`include "masked_zero.sv"
`include "masked_bv4_comp_theta.sv"
`include "masked_hpc1_mul.sv"

// Compute second stage of masked GF(2^8) Inverse
module masked_4stage_bv8_inv_stage2 (
    in_a0_t1, in_a1_t1, in_pow4_t1, in_random, out_theta_t2, out_mul_a0_t3, out_mul_a1_t3, in_clock, in_reset
);
    import aes128_package::*;
    parameter NUM_SHARES = 2;
    localparam NUM_QUARDATIC = num_quad(NUM_SHARES);
    localparam NUM_ZERO_RANDOM = num_zero_random(NUM_SHARES);
    localparam NUM_RANDOM = stage_2_lat4_randoms(NUM_SHARES);
    
    input  bv4_t[NUM_SHARES-1:0] in_a0_t1;
    input  bv4_t[NUM_SHARES-1:0] in_a1_t1;
    input  bv4_t[NUM_SHARES-1:0] in_pow4_t1;
    input    bit[NUM_RANDOM-1:0] in_random;
    output bv2_t[NUM_SHARES-1:0] out_theta_t2;
    output bv4_t[NUM_SHARES-1:0] out_mul_a0_t3;
    output bv4_t[NUM_SHARES-1:0] out_mul_a1_t3;
    input                    bit in_clock;
    input                    bit in_reset;

    bv2_t[NUM_QUARDATIC-1:0][1:0] theta_random;
    bv4_t[NUM_QUARDATIC-1:0]      right_p;
    bv4_t[NUM_QUARDATIC-1:0]      left_p;
    bv4_t[NUM_SHARES-1:0]         joint_r;
    
    bv4_t[NUM_ZERO_RANDOM-1:0]    joint_r_raw;
    assign {joint_r_raw, left_p, right_p, theta_random} = in_random;
    
    masked_zero #(
        .NUM_SHARES(NUM_SHARES), 
        .BIT_WIDTH(4)
    ) left_shared_0 (
        .in_random(joint_r_raw),
        .out_random(joint_r),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    
    masked_bv4_comp_theta #(
        .NUM_SHARES(NUM_SHARES)
    ) c_theta (
        .in_a(in_pow4_t1), 
        .in_random(theta_random), 
        .out_b(out_theta_t2),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    
    bv4_t[NUM_SHARES-1:0] a0_t1_d, a0_t1_q;
    bv4_t[NUM_SHARES-1:0] a1_t1_d, a1_t1_q;
    
    register #(.T(bv4_t[1:0][NUM_SHARES-1:0])) reg_a (
        .in_value({a1_t1_d, a0_t1_d}), .out_value({a1_t1_q, a0_t1_q}), 
        .in_clock(in_clock), .in_reset(in_reset)
    );
    bv4_t[NUM_SHARES-1:0] a0_t2, a1_t2;
    assign {a1_t1_d, a0_t1_d} = {in_a1_t1, in_a0_t1};
    assign {a1_t2, a0_t2} = {a1_t1_q, a0_t1_q};


    masked_hpc1_mul #(
        .NUM_SHARES(NUM_SHARES), 
        .BIT_WIDTH(4)
    ) mul_left (
        .in_a(a0_t2), 
        .in_b(in_pow4_t1),
        .in_r(joint_r),
        .in_p(left_p), 
        .out_c(out_mul_a0_t3),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    
    masked_hpc1_mul #(
        .NUM_SHARES(NUM_SHARES), 
        .BIT_WIDTH(4)
    ) mul_right (
        .in_a(a1_t2), 
        .in_b(in_pow4_t1),
        .in_r(joint_r),
        .in_p(right_p), 
        .out_c(out_mul_a1_t3),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
endmodule : masked_4stage_bv8_inv_stage2
`endif // MASKED_4STAGE_BV8_INV_STAGE2_SV
