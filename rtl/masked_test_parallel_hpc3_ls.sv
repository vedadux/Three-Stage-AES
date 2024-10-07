`ifndef MASKED_TEST_PARALLEL_HPC3_LS_SV
`define MASKED_TEST_PARALLEL_HPC1_LS_SV

`include "aes128_package.sv"
`include "masked_hpc3_1_mul.sv"

module masked_test_parallel_hpc3_ls #(
    parameter NUM_SHARES = 2,
    parameter BIT_WIDTH = 4
)(
    in_a_t1, in_b_t0, in_c_t0, in_r, in_p_ab, in_p_ac, out_d, out_e, in_clock, in_reset
);
    import aes128_package::*;
    localparam NUM_QUADRATIC = num_quad(NUM_SHARES);
    typedef bit[BIT_WIDTH-1:0] T;

    input  T[NUM_SHARES-1:0] in_a_t1;
    input  T[NUM_SHARES-1:0] in_b_t0;
    input  T[NUM_SHARES-1:0] in_c_t0;
    input  T[NUM_QUADRATIC-1:0] in_r;
    input  T[NUM_QUADRATIC-1:0] in_p_ab;
    input  T[NUM_QUADRATIC-1:0] in_p_ac;
    output T[NUM_SHARES-1:0] out_d;
    output T[NUM_SHARES-1:0] out_e;
    input in_clock;
    input in_reset;
    
    T[NUM_SHARES-1:0] reg_b_t1;
    T[NUM_SHARES-1:0] reg_c_t1;
    
    register #(.T(T[NUM_SHARES-1:0])) reg_in_b (
        .in_value(in_b_t0),
        .out_value(reg_b_t1),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    register #(.T(T[NUM_SHARES-1:0])) reg_in_c (
        .in_value(in_c_t0),
        .out_value(reg_c_t1),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    // Multiply B and A
    masked_hpc3_1_mul #(
        .NUM_SHARES(NUM_SHARES),
        .BIT_WIDTH(BIT_WIDTH)
    ) mul1 (
        .in_a(reg_b_t1),
        .in_b(in_a_t1),
        .in_r(in_r),
        .in_p(in_p_ab),
        .out_c(out_d),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    // Multiply C and A
    masked_hpc3_1_mul #(
        .NUM_SHARES(NUM_SHARES),
        .BIT_WIDTH(BIT_WIDTH)
    ) mul2 (
        .in_a(reg_c_t1),
        .in_b(in_a_t1),
        .in_r(in_r),
        .in_p(in_p_ac),
        .out_c(out_e),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    
endmodule: masked_test_parallel_hpc3_ls
`endif // MASKED_TEST_PARALLEL_HPC1_LS_SV
