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

`ifndef MASKED_HPC3_OPT_MUL_SV
`define MASKED_HPC3_OPT_MUL_SV

`include "aes128_package.sv"
`include "register.sv"
`include "generic_mul.sv"
`include "reduce_xor.sv"

module masked_hpc3_opt_mul #(
    parameter NUM_SHARES = 2,
    parameter BIT_WIDTH = 4
)(
    in_a, in_b, in_r, in_p, out_c, in_clock, in_reset
);
    import aes128_package::*;
    localparam NUM_QUARDATIC = num_quad(NUM_SHARES);
    typedef bit[BIT_WIDTH-1:0] T;

    input T[NUM_SHARES-1:0] in_a;
    input T[NUM_SHARES-1:0] in_b;
    input T[NUM_QUARDATIC-1:0] in_r;
    input T[NUM_QUARDATIC-1:0] in_p;
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

    generate
        for (i = 0; i < NUM_SHARES; i++)
        begin : gen_iter_i
            T[NUM_SHARES-2:0] us_t1;
            for (j = 0; j < NUM_SHARES; j++)
            begin : gen_iter_j
                if (i != j) begin : gen_ij_neq
                    localparam jj = (j < i) ? j : (j - 1);
                    T v_ij_t0; assign v_ij_t0 = in_r[qindex(i, j, NUM_SHARES)] ^ in_b[j];
                    
                    T v_ij_t1;
                    register #(.T(T)) reg_v_ij (
                        .in_value(v_ij_t0),
                        .out_value(v_ij_t1),
                        .in_clock(in_clock),
                        .in_reset(in_reset)
                    );

                    T mul_a_i_v_ij_t1;
                    generic_mul #(.BIT_WIDTH(BIT_WIDTH)) gen_ai_vij(
                        .in_a(reg_a_t1[i]), 
                        .in_b(v_ij_t1), 
                        .out_c(mul_a_i_v_ij_t1)
                    );

                    T mul_corr_t0;
                    if ((i == 0 && j == 1) || (i != 0 && j == 0)) 
                    begin : special_corr
                        generic_mul #(.BIT_WIDTH(BIT_WIDTH)) gen_mul_special_corr(
                            .in_a(in_a[i]), 
                            .in_b(in_b[i] ^ in_r[qindex(i, j, NUM_SHARES)]), 
                            .out_c(mul_corr_t0)
                        );
                    end else begin : usual_corr
                        generic_mul #(.BIT_WIDTH(BIT_WIDTH)) gen_mul_normal_corr(
                            .in_a(in_a[i]), 
                            .in_b(in_r[qindex(i, j, NUM_SHARES)]), 
                            .out_c(mul_corr_t0)
                        );
                    end
                    
                    T w_ij_t0; assign w_ij_t0 = in_p[qindex(i, j, NUM_SHARES)] ^ mul_corr_t0;
                    
                    T w_ij_t1;
                    register #(.T(T)) reg_w_ij (
                        .in_value(w_ij_t0),
                        .out_value(w_ij_t1),
                        .in_clock(in_clock),
                        .in_reset(in_reset)
                    );

                    assign us_t1[jj] = mul_a_i_v_ij_t1 ^ w_ij_t1;
                end
            end
            reduce_xor #(
                .ELEMENT_WIDTH(BIT_WIDTH), 
                .NUM_ELEMENTS(NUM_SHARES-1)) 
                gen_xor_corr_i (
                .in_elements(us_t1), 
                .out_xor(out_c[i])
            );
        end
    endgenerate
endmodule : masked_hpc3_opt_mul
`endif // MASKED_HPC3_OPT_MUL_SV
