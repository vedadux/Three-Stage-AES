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

`ifndef MASKED_CANRIGHT_BV8_INV_STAGE4_HPC3_SV
`define MASKED_CANRIGHT_BV8_INV_STAGE4_HPC3_SV

`include "aes128_package.sv"
`include "register.sv"
`include "masked_hpc3_1_mul.sv"
`include "masked_zero.sv"

module masked_canright_bv8_inv_stage4_hpc3 #(
    parameter NUM_SHARES = 2
)(
    in_x_t3, in_a_t1, in_random, out_b_t4, in_clock, in_reset
);
    import aes128_package::*;
    localparam BIT_WIDTH = 4;
    localparam NUM_QUADRATIC = num_quad(NUM_SHARES);
    localparam NUM_RANDOM = stage_4_canright_hpc3_randoms(NUM_SHARES);
    localparam NUM_ZERO_RANDOM = num_zero_random(NUM_SHARES);
    typedef bit[BIT_WIDTH-1:0] T;

    input       T[NUM_SHARES-1:0] in_x_t3;
    input  T[1:0][NUM_SHARES-1:0] in_a_t1;
    input     bit[NUM_RANDOM-1:0] in_random;
    output T[1:0][NUM_SHARES-1:0] out_b_t4;
    input in_clock;
    input in_reset;
    
    bv4_t[NUM_QUADRATIC-1:0] joint_r;
    bv4_t[NUM_QUADRATIC-1:0] p_xa0, p_xa1;
    assign {p_xa1, p_xa0, joint_r} = in_random;

    bv4_t[1:0][NUM_SHARES-1:0] a_t2;
    register #(.T(bv4_t[1:0][NUM_SHARES-1:0])) reg_a_t2 (
        .in_value(in_a_t1), .out_value(a_t2), 
        .in_clock(in_clock), .in_reset(in_reset)
    );
    
    bv4_t[1:0][NUM_SHARES-1:0] a_t3;
    register #(.T(bv4_t[1:0][NUM_SHARES-1:0])) reg_a_t3 (
        .in_value(a_t2), .out_value(a_t3), 
        .in_clock(in_clock), .in_reset(in_reset)
    );

    masked_hpc3_1_mul #(
        .NUM_SHARES(NUM_SHARES),
        .BIT_WIDTH(BIT_WIDTH)
    ) mul_xa0 (
        .in_a(a_t3[0]),
        .in_b(in_x_t3),
        .in_r(joint_r),
        .in_p(p_xa0),
        .out_c(out_b_t4[1]),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    masked_hpc3_1_mul #(
        .NUM_SHARES(NUM_SHARES),
        .BIT_WIDTH(BIT_WIDTH)
    ) mul_xa1 (
        .in_a(a_t2[1]),
        .in_b(in_x_t3),
        .in_r(joint_r),
        .in_p(p_xa1),
        .out_c(out_b_t4[0]),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
endmodule: masked_canright_bv8_inv_stage4_hpc3
`endif // MASKED_CANRIGHT_BV8_INV_STAGE4_HPC3_SV
