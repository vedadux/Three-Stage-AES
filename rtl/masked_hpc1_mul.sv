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

    // reshare input in_b first
    T[NUM_SHARES-1:0] reg_ref_b_d;
    T[NUM_SHARES-1:0] reg_ref_b_q;

    assign reg_ref_b_d = in_b ^ in_r;
    register #(.T(T[NUM_SHARES-1:0])) reg_ref_a (
        .in_value(reg_ref_b_d),
        .out_value(reg_ref_b_q),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    // preform the cross multiplication
    T[NUM_SHARES-1:0][NUM_SHARES-1:0] cross_mul;
    T[NUM_SHARES-1:0][NUM_SHARES-1:0] c_array_d;
    T[NUM_SHARES-1:0][NUM_SHARES-1:0] c_array_q;
    
    genvar i, j;
    generate
        for (i = 0; i < NUM_SHARES; i++)
        begin
            for (j = 0; j < NUM_SHARES; j++)
            begin
                generic_mul #(.BIT_WIDTH(BIT_WIDTH)) gen_mul_ij(
                    .in_a(in_a[i]), 
                    .in_b(reg_ref_b_q[j]), 
                    .out_c(cross_mul[i][j])
                );
                if (i == j) assign c_array_d[i][j] = cross_mul[i][j];
                else        assign c_array_d[i][j] = cross_mul[i][j] ^ in_p[qindex(i, j, NUM_SHARES)];
                register #(.T(T)) gen_reg_ij(
                    .in_value(c_array_d[i][j]), 
                    .out_value(c_array_q[i][j]),
                    .in_clock(in_clock),
                    .in_reset(in_reset)
                );
            end
            reduce_xor #(
                .ELEMENT_WIDTH(BIT_WIDTH), 
                .NUM_ELEMENTS(NUM_SHARES)) 
                gen_xor_tree_i (
                .in_elements(c_array_q[i]), 
                .out_xor(out_c[i])
            );
        end
    endgenerate
endmodule : masked_hpc1_mul
`endif // MASKED_HPC1_MUL_SV
