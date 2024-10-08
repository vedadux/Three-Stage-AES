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

`ifndef MASKED_BV4_COMP_THETA_SV
`define MASKED_BV4_COMP_THETA_SV

`include "aes128_package.sv"
`include "masked_hpc3_1_mul.sv"
`include "masked_split_bv.sv"
`include "bv2_sq.sv"
`include "bv2_scl_sigma.sv"

// Compute Masked Theta = (Gamma_1 * Gamma_0 + (Gamma_1 + Gamma_0)^{2} * Sigma)^{-1}
module masked_bv4_comp_theta #(
    parameter NUM_SHARES = 2
)(
    in_a, in_random, out_b, in_clock, in_reset
);
    import aes128_package::*;
    localparam NUM_QUADRATIC = num_quad(NUM_SHARES);
    localparam NUM_RANDOM = 2 * (NUM_QUADRATIC * 2);

    input  bv4_t[NUM_SHARES-1:0] in_a;
    input    bit[NUM_RANDOM-1:0] in_random;
    output bv2_t[NUM_SHARES-1:0] out_b;
    input                    bit in_clock;
    input                    bit in_reset;
    genvar i;

    bv2_t[NUM_QUADRATIC-1:0] random_r, random_p;
    assign {random_p, random_r} = in_random;

    bv2_t[1:0][NUM_SHARES-1:0] a_t0;
    masked_split_bv #(
        .NUM_SHARES(NUM_SHARES),
        .HALF_WIDTH(2)
    ) split (
        .in_a(in_a),
        .out_b(a_t0)
    );

    bv2_t[NUM_SHARES-1:0] a_mul_t1, a_xor_t1;
    masked_hpc3_1_mul #(.NUM_SHARES(NUM_SHARES), .BIT_WIDTH(2)) mul (
        .in_a(a_t0[1]), 
        .in_b(a_t0[0]),
        .in_r(random_r),
        .in_p(random_p),
        .out_c(a_mul_t1),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    
    bv2_t[1:0][NUM_SHARES-1:0] a_t0_d, a_t0_q;
    register #(.T(bv2_t[1:0][NUM_SHARES-1:0])) reg_a (
        .in_value(a_t0_d), .out_value(a_t0_q), 
        .in_clock(in_clock), .in_reset(in_reset)
    );
    bv2_t[1:0][NUM_SHARES-1:0] a_t1;
    assign a_t0_d = a_t0;
    assign a_t1 = a_t0_q;

    assign a_xor_t1 = a_t1[0] ^ a_t1[1];
    
    bv2_t[NUM_SHARES-1:0] a_xor_sq_t1, a_xor_sq_scl_t1;
    generate
        for (i = 0; i < NUM_SHARES; i += 1) begin
            bv2_sq sq (
                .in_a(a_xor_t1[i]), 
                .out_b(a_xor_sq_t1[i])
            );
            bv2_scl_sigma scl (
                .in_a(a_xor_sq_t1[i]), 
                .out_b(a_xor_sq_scl_t1[i])
            );
        end    
    endgenerate
    
    bv2_t[NUM_SHARES-1:0] inv_in_t1;
    assign inv_in_t1 = a_mul_t1 ^ a_xor_sq_scl_t1;

    generate
        for (i = 0; i < NUM_SHARES; i += 1)
            bv2_sq inv(
                .in_a(inv_in_t1[i]), 
                .out_b(out_b[i])
            );    
    endgenerate
endmodule : masked_bv4_comp_theta
`endif // MASKED_BV4_COMP_THETA_SV
