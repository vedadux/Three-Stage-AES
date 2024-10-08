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

`ifndef MASKED_HPC3_OLD_MUL_SV
`define MASKED_HPC3_OLD_MUL_SV

`include "aes128_package.sv"
`include "register.sv"
`include "generic_mul.sv"
`include "reduce_xor.sv"

module masked_hpc3_old_mul #(
    parameter NUM_SHARES = 2
)(
    in_a, in_b, in_r, in_p, out_c, in_clock, in_reset
);
    import aes128_package::*;
    localparam NUM_QUARDATIC = num_quad(NUM_SHARES);
    localparam BIT_WIDTH = 1;
    typedef bit[BIT_WIDTH-1:0] T;

    input T[NUM_SHARES-1:0] in_a;
    input T[NUM_SHARES-1:0] in_b;
    input T[NUM_QUARDATIC-1:0] in_r;
    input T[NUM_QUARDATIC-1:0] in_p;
    output T[NUM_SHARES-1:0] out_c;
    input in_clock;
    input in_reset;

    genvar i, j;

    T[NUM_SHARES-1:0] neg_a;
    assign neg_a = ~in_a;

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
    assign a_mul_b_t0 = in_a & in_b;

    register #(.T(T[NUM_SHARES-1:0])) reg_a_mul_b (
        .in_value(a_mul_b_t0),
        .out_value(a_mul_b_t1),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    generate
        for (i = 0; i < NUM_SHARES; i++)
        begin : gen_iter_i
            T[NUM_SHARES-1:0] us_t1;
            for (j = 0; j < NUM_SHARES; j++)
            begin : gen_iter_j
                if (i != j) begin : gen_ij_neq
                    T v_ij_t0; assign v_ij_t0 = in_r[qindex(i, j, NUM_SHARES)] ^ in_b[j];
                    T w_ij_t0; assign w_ij_t0 = in_p[qindex(i, j, NUM_SHARES)] ^ (neg_a[i] & in_r[qindex(i, j, NUM_SHARES)]);
                    
                    T v_ij_t1;
                    T w_ij_t1;

                    register #(.T(T)) reg_v_ij (
                        .in_value(v_ij_t0),
                        .out_value(v_ij_t1),
                        .in_clock(in_clock),
                        .in_reset(in_reset)
                    );

                    register #(.T(T)) reg_w_ij (
                        .in_value(w_ij_t0),
                        .out_value(w_ij_t1),
                        .in_clock(in_clock),
                        .in_reset(in_reset)
                    );
                    assign us_t1[j] = (reg_a_t1[i] & v_ij_t1) ^ w_ij_t1;
                end else begin : gen_ij_eq
                    assign us_t1[j] = a_mul_b_t1[j];
                end
            end
            reduce_xor #(
                .ELEMENT_WIDTH(BIT_WIDTH), 
                .NUM_ELEMENTS(NUM_SHARES)) 
                gen_xor_corr_i (
                .in_elements(us_t1), 
                .out_xor(out_c[i])
            );
        end
    endgenerate
endmodule : masked_hpc3_old_mul
`endif // MASKED_HPC3_OLD_MUL_SV
