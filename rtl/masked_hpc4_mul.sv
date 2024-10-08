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

`ifndef MASKED_HPC4_MUL_SV
`define MASKED_HPC4_MUL_SV

`include "aes128_package.sv"
`include "register.sv"
`include "generic_mul.sv"
`include "reduce_xor.sv"

module masked_hpc4_mul #(
    parameter NUM_SHARES = 2,
    parameter BIT_WIDTH = 4
)(
    in_a, in_b, in_r0a, in_r0b, in_r1, in_r2, in_r3, out_c, in_clock, in_reset
);
    import aes128_package::*;
    localparam NUM_QUARDATIC = num_quad(NUM_SHARES);
    typedef bit[BIT_WIDTH-1:0] T;

    input T[NUM_SHARES-1:0] in_a;
    input T[NUM_SHARES-1:0] in_b;
    input T[NUM_QUARDATIC-1:0] in_r0a;
    input T[NUM_QUARDATIC-1:0] in_r0b;
    input T[NUM_QUARDATIC-1:0] in_r1;
    input T[NUM_QUARDATIC-1:0] in_r2;
    input T[NUM_QUARDATIC-1:0] in_r3;
    output T[NUM_SHARES-1:0] out_c;
    input in_clock;
    input in_reset;

    genvar i, j;

    T[NUM_SHARES-1:0] in_a_t0;
    T[NUM_SHARES-1:0] reg_a_t1;
    
    assign in_a_t0 = in_a;
    register #(.T(T[NUM_SHARES-1:0])) reg_in_a (
        .in_value(in_a_t0),
        .out_value(reg_a_t1),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    T[NUM_SHARES-1:0] a_mul_b_t0, a_mul_b_t1;
    generate
        for (i = 0; i < NUM_SHARES; i++)
        begin : gen_iter_i
            generic_mul #(.BIT_WIDTH(BIT_WIDTH)) gen_ai_bi(
                .in_a(in_a[i]), 
                .in_b(in_b[i]), 
                .out_c(a_mul_b_t0[i])
            );
        end
    endgenerate
    
    register #(.T(T[NUM_SHARES-1:0])) reg_a_mul_b (
        .in_value(a_mul_b_t0),
        .out_value(a_mul_b_t1),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    generate
        for (i = 0; i < NUM_SHARES; i++)
        begin : gen_iter_i
            T[NUM_SHARES-1:0] zs_t1;
            for (j = 0; j < NUM_SHARES; j++)
            begin : gen_iter_j
                if (i != j) begin : gen_ij_neq
                    T in_r0_ij = (i < j) ? in_r0a[qindex(i, j, NUM_SHARES)] :
                                           in_r0b[qindex(i, j, NUM_SHARES)];

                    T u_ij_t0; assign u_ij_t0 = in_b[j] ^ in_r0_ij ^ in_r1[qindex(i, j, NUM_SHARES)];

                    T u_ij_t1;
                    register #(.T(T)) reg_u_ij (
                        .in_value(u_ij_t0),
                        .out_value(u_ij_t1),
                        .in_clock(in_clock),
                        .in_reset(in_reset)
                    );

                    T mul_a_i_r0_ij;
                    generic_mul #(.BIT_WIDTH(BIT_WIDTH)) gen_ai_r0ij(
                        .in_a(in_a[i]), 
                        .in_b(in_r0_ij), 
                        .out_c(mul_a_i_r0_ij)
                    );

                    T mul_a_i_r1_ij;
                    generic_mul #(.BIT_WIDTH(BIT_WIDTH)) gen_ai_r1ij(
                        .in_a(in_a[i]), 
                        .in_b(in_r1[qindex(i, j, NUM_SHARES)]), 
                        .out_c(mul_a_i_r1_ij)
                    );

                    T v_ij_t0; assign v_ij_t0 = mul_a_i_r0_ij ^ in_r2[qindex(i, j, NUM_SHARES)];
                    T v_ij_t1;
                    register #(.T(T)) reg_v_ij (
                        .in_value(v_ij_t0),
                        .out_value(v_ij_t1),
                        .in_clock(in_clock),
                        .in_reset(in_reset)
                    );

                    T w_ij_t0; assign w_ij_t0 = mul_a_i_r1_ij ^ in_r3[qindex(i, j, NUM_SHARES)];
                    T w_ij_t1;
                    register #(.T(T)) reg_w_ij (
                        .in_value(w_ij_t0),
                        .out_value(w_ij_t1),
                        .in_clock(in_clock),
                        .in_reset(in_reset)
                    );

                    T mul_a_i_u_ij_t1;
                    generic_mul #(.BIT_WIDTH(BIT_WIDTH)) gen_ai_uij(
                        .in_a(reg_a_t1[i]), 
                        .in_b(u_ij_t1), 
                        .out_c(mul_a_i_u_ij_t1)
                    );

                    assign zs_t1[j] = mul_a_i_u_ij_t1 ^ v_ij_t1 ^ w_ij_t1;
                end else begin : gen_ij_eq
                    assign zs_t1[j] = a_mul_b_t1[j];
                end
            end
            reduce_xor #(
                .ELEMENT_WIDTH(BIT_WIDTH), 
                .NUM_ELEMENTS(NUM_SHARES)) 
                gen_xor_corr_i (
                .in_elements(zs_t1), 
                .out_xor(out_c[i])
            );
        end
    endgenerate
endmodule : masked_hpc4_mul
`endif // MASKED_HPC4_MUL_SV
