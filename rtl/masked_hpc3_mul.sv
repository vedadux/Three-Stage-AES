`ifndef MASKED_HPC3_MUL_SV
`define MASKED_HPC3_MUL_SV

`include "aes128_package.sv"
`include "register.sv"
`include "generic_mul.sv"
`include "reduce_xor.sv"

module masked_hpc3_mul #(
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

    // Registers for A and B
    T[NUM_SHARES-1:0] reg_in_a_d;
    T[NUM_SHARES-1:0] reg_in_a_q;

    register #(.T(T[NUM_SHARES-1:0])) reg_in_a (
        .in_value(reg_in_a_d),
        .out_value(reg_in_a_q),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    assign reg_in_a_d = in_a;

    T[NUM_SHARES-1:0] reg_in_b_d;
    T[NUM_SHARES-1:0] reg_in_b_q;

    register #(.T(T[NUM_SHARES-1:0])) reg_in_b (
        .in_value(reg_in_b_d),
        .out_value(reg_in_b_q),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    assign reg_in_b_d = in_b;

    // preform the cross multiplication
    T[NUM_SHARES-1:0][NUM_SHARES-2:0] blinded_b_d;
    T[NUM_SHARES-1:0][NUM_SHARES-2:0] blinded_b_q;
    
    register #(.T(T[NUM_SHARES-1:0][NUM_SHARES-2:0])) reg_blinded_b (
        .in_value(blinded_b_d),
        .out_value(blinded_b_q),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    T[NUM_SHARES-1:0][NUM_SHARES-2:0] blinded_corr_d;
    T[NUM_SHARES-1:0][NUM_SHARES-2:0] blinded_corr_q;
    
    register #(.T(T[NUM_SHARES-1:0][NUM_SHARES-2:0])) reg_blinded_corr (
        .in_value(blinded_corr_d),
        .out_value(blinded_corr_q),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    genvar i, j;
    generate
        for (i = 0; i < NUM_SHARES; i++)
        begin : gen_iter_i
            for (j = 0; j < NUM_SHARES; j++)
            begin : gen_iter_j
                if (i != j) begin : gen_ij_neq
                    localparam jj = (j < i) ? j : (j - 1);
                    // Compute V_{i,j} = R_{i,j} + B_j
                    assign blinded_b_d[i][jj] = in_b[j] ^ in_r[qindex(i, j, NUM_SHARES)];
                    // Compute W_{i,j} = P_{i,j} - A_i * R_{i,j}
                    T mul_ar;
                    generic_mul #(.BIT_WIDTH(BIT_WIDTH)) gen_mul_ij(
                        .in_a(in_a[i]), 
                        .in_b(in_r[qindex(i, j, NUM_SHARES)]), 
                        .out_c(mul_ar)
                    );
                    assign blinded_corr_d[i][jj] = mul_ar ^ in_p[qindex(i, j, NUM_SHARES)];
                end
            end
            
            // Compute V_i = Reg(B_i) + sum_{j=0,j != i}^{n-1} Reg(V_{i,j})
            T sum_blinded_b_i;
            reduce_xor #(
                .ELEMENT_WIDTH(BIT_WIDTH), 
                .NUM_ELEMENTS(NUM_SHARES)) 
                gen_xor_blinded_b_i (
                .in_elements({reg_in_b_q[i], blinded_b_q[i]}), 
                .out_xor(sum_blinded_b_i)
            );

            // Compute C_i' = Reg(A_i) * V_i
            T mul_ab_i;
            generic_mul #(.BIT_WIDTH(BIT_WIDTH)) gen_mul_ij(
                .in_a(reg_in_a_q[i]), 
                .in_b(sum_blinded_b_i), 
                .out_c(mul_ab_i)
            );
            
            // Compute C_i = C_i' + sum_{j=0,j!=i}^{n} Reg(W_{i,j})
            reduce_xor #(
                .ELEMENT_WIDTH(BIT_WIDTH), 
                .NUM_ELEMENTS(NUM_SHARES)) 
                gen_xor_blinded_corr_i (
                .in_elements({mul_ab_i, blinded_corr_q[i]}), 
                .out_xor(out_c[i])
            );
        end
    endgenerate
endmodule : masked_hpc3_mul
`endif // MASKED_HPC3_MUL_SV
