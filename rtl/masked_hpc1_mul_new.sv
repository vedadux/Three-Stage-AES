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

`ifndef MASKED_HPC1_MUL_SV
`define MASKED_HPC1_MUL_SV

`include "aes128_package.sv"
`include "register.sv"
`include "generic_mul.sv"
`include "reduce_xor.sv"

module masked_hpc1_mul #(
    parameter NUM_SHARES = 2,
    parameter BIT_WIDTH = 1
)(
    in_a, in_b, in_r, in_p, out_c, in_clock, in_reset
);
    import aes128_package::*;
    localparam NUM_QUARDATIC = num_quad(NUM_SHARES);
    typedef bit[BIT_WIDTH-1:0] T;

    input T[NUM_SHARES-1:0] in_a;
    input T[NUM_SHARES-1:0] in_b;
    input T[NUM_SHARES-1:0] in_r;
    input T[NUM_QUARDATIC-1:0] in_p;
    output T[NUM_SHARES-1:0] out_c;
    input in_clock;
    input in_reset;
    genvar i, j;

    // reshare input in_b first
    T[NUM_SHARES-1:0] reg_ref_b_t0;
    T[NUM_SHARES-1:0] reg_ref_b_t1;
    T[NUM_SHARES-1:0] reg_ref_b_t2;

    assign reg_ref_b_t0 = in_b ^ in_r;
    register #(.T(T[NUM_SHARES-1:0])) reg_ref_b0 (
        .in_value(reg_ref_b_t0),
        .out_value(reg_ref_b_t1),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    register #(.T(T[NUM_SHARES-1:0])) reg_ref_b1 (
        .in_value(reg_ref_b_t1),
        .out_value(reg_ref_b_t2),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    // pipeline input in_a as well
    T[NUM_SHARES-1:0] reg_a_t1;
    T[NUM_SHARES-1:0] reg_a_t2;
    assign reg_a_t1 = in_a;
    register #(.T(T[NUM_SHARES-1:0])) reg_pipe_a (
        .in_value(reg_a_t1),
        .out_value(reg_a_t2),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    // preform the cross multiplication
    
    T[NUM_SHARES-1:0] same_domain;
    T[NUM_SHARES-1:0][NUM_SHARES-2:0] cross_domain;

    generate
        for (i = 0; i < NUM_SHARES; i++)
        begin : same_domain_muls
            generic_mul #(
                .BIT_WIDTH(BIT_WIDTH)) 
            mul_ii(
                .in_a(reg_a_t2[i]), 
                .in_b(reg_ref_b_t2[i]), 
                .out_c(same_domain[i])
            );
        end
        for (i = 0; i < NUM_SHARES; i++)
        begin : cross_domain_iter_i
            for (j = 0; j < NUM_SHARES; j++)
            begin : cross_domain_iter_j
                if (i != j) begin : gen_ij_neq
                    localparam jj = (j < i) ? j : (j - 1);
                    T mul_ij_res;
                    T mul_ij_res_ref;
                    generic_mul #(
                        .BIT_WIDTH(BIT_WIDTH)) 
                    mul_ij(
                        .in_a(in_a[i]), 
                        .in_b(reg_ref_b_t1[j]), 
                        .out_c(mul_ij_res)
                    );
                    assign mul_ij_res_ref = mul_ij_res ^ in_p[qindex(i, j, NUM_SHARES)];
                    register #(.T(T)) reg_ij (
                        .in_value(mul_ij_res_ref), 
                        .out_value(cross_domain[i][jj]),
                        .in_clock(in_clock),
                        .in_reset(in_reset)
                    );
                end
            end
        end
        for (i = 0; i < NUM_SHARES; i++)
        begin : reduce_iter_i
            reduce_xor #(
                .ELEMENT_WIDTH(BIT_WIDTH), 
                .NUM_ELEMENTS(NUM_SHARES)) 
                reduce_i (
                .in_elements({cross_domain[i], same_domain[i]}), 
                .out_xor(out_c[i])
            );
        end
    endgenerate
endmodule : masked_hpc1_mul
`endif // MASKED_HPC1_MUL_SV
