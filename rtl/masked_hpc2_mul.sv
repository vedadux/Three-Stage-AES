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

`ifndef MASKED_HPC2_MUL_SV
`define MASKED_HPC2_MUL_SV

`include "aes128_package.sv"
`include "register.sv"
`include "generic_mul.sv"
`include "reduce_xor.sv"

module masked_hpc2_mul #(
    parameter NUM_SHARES = 2
)(
    in_a, in_b, in_r, out_c, in_clock, in_reset
);
    import aes128_package::*;
    localparam NUM_QUARDATIC = num_quad(NUM_SHARES);
    localparam BIT_WIDTH = 1;
    typedef bit[BIT_WIDTH-1:0] T;

    input T[NUM_SHARES-1:0] in_a;
    input T[NUM_SHARES-1:0] in_b;
    input T[NUM_QUARDATIC-1:0] in_r;
    output T[NUM_SHARES-1:0] out_c;
    input in_clock;
    input in_reset;

    genvar i, j;

    T[NUM_SHARES-1:0] in_b_t0;
    T[NUM_SHARES-1:0] reg_b_t1;

    register #(.T(T[NUM_SHARES-1:0])) reg_in_b (
        .in_value(in_b_t0),
        .out_value(reg_b_t1),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    assign in_b_t0 = in_b;
    
    T[NUM_SHARES-1:0] in_a_t1;
    assign in_a_t1 = in_a;
    
    T[NUM_QUARDATIC-1:0] in_r_t0;
    T[NUM_QUARDATIC-1:0] reg_r_t1;

    register #(.T(T[NUM_QUARDATIC-1:0])) reg_in_r (
        .in_value(in_r_t0),
        .out_value(reg_r_t1),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    assign in_r_t0 = in_r;

    T[NUM_SHARES-1:0][NUM_SHARES-2:0] blinded_b_t0;
    T[NUM_SHARES-1:0][NUM_SHARES-2:0] blinded_b_t1;    

    register #(.T(T[NUM_SHARES-1:0][NUM_SHARES-2:0])) reg_blinded_b (
        .in_value(blinded_b_t0),
        .out_value(blinded_b_t1),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    T[NUM_SHARES-1:0][NUM_SHARES-1:0] blinded_mul_t1;
    T[NUM_SHARES-1:0][NUM_SHARES-1:0] blinded_mul_t2;    

    register #(.T(T[NUM_SHARES-1:0][NUM_SHARES-1:0])) reg_blinded_mul (
        .in_value(blinded_mul_t1),
        .out_value(blinded_mul_t2),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    T[NUM_SHARES-1:0][NUM_SHARES-2:0] corr_t1;
    T[NUM_SHARES-1:0][NUM_SHARES-2:0] corr_t2;

    register #(.T(T[NUM_SHARES-1:0][NUM_SHARES-2:0])) reg_corr (
        .in_value(corr_t1),
        .out_value(corr_t2),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    generate
        for (i = 0; i < NUM_SHARES; i++)
        begin : gen_iter_i
            for (j = 0; j < NUM_SHARES; j++)
            begin : gen_iter_j
                if (i != j) begin : gen_ij_neq
                    localparam jj = (j < i) ? j : (j - 1);
                    // Compute V_{i,j} = R_{i,j} + B_j
                    assign blinded_b_t0[i][jj] = in_b_t0[j] ^ in_r_t0[qindex(i, j, NUM_SHARES)];
                    // Compute U_{i,j} = A_i * Reg(R_{i,j} + B_j)
                    generic_mul #(.BIT_WIDTH(BIT_WIDTH)) gen_mul_ij(
                        .in_a(in_a_t1[i]), 
                        .in_b(blinded_b_t1[i][jj]), 
                        .out_c(blinded_mul_t1[i][j])
                    );
                    // Compute W_{i,j} = (A_i + 1) * R_{i,j}
                    generic_mul #(.BIT_WIDTH(BIT_WIDTH)) gen_corr_ij(
                        .in_a(~in_a_t1[i]), 
                        .in_b(reg_r_t1[qindex(i, j, NUM_SHARES)]), 
                        .out_c(corr_t1[i][jj])
                    );
                end
            end

            generic_mul #(.BIT_WIDTH(BIT_WIDTH)) gen_mul_ij(
                .in_a(in_a_t1[i]), 
                .in_b(reg_b_t1[i]), 
                .out_c(blinded_mul_t1[i][i])
            );
            
            // Compute C_i = C_i' + sum_{j=0,j!=i}^{n} Reg(W_{i,j})
            reduce_xor #(
                .ELEMENT_WIDTH(BIT_WIDTH), 
                .NUM_ELEMENTS(2 * NUM_SHARES - 1)) 
                gen_xor_corr_i (
                .in_elements({blinded_mul_t2[i], corr_t2[i]}), 
                .out_xor(out_c[i])
            );
        end
    endgenerate
endmodule : masked_hpc2_mul
`endif // MASKED_HPC2_MUL_SV
