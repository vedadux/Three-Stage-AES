`ifndef MASKED_TEST_PARALLEL_HPC1_LS_SV
`define MASKED_TEST_PARALLEL_HPC1_LS_SV

`include "aes128_package.sv"
`include "masked_hpc1_mul.sv"
`include "masked_zero.sv"


module masked_test_parallel_hpc1_ls #(
    parameter NUM_SHARES = 2,
    parameter BIT_WIDTH = 4
)(
    in_a_t1, in_b_t0, in_c_t0, in_r_raw_ab, in_r_raw_ac, in_p_ab, in_p_ac, out_d, out_e, in_clock, in_reset
);
    import aes128_package::*;
    localparam NUM_QUADRATIC = num_quad(NUM_SHARES);
    localparam NUM_ZERO_RANDOM = num_zero_random(NUM_SHARES);
    typedef bit[BIT_WIDTH-1:0] T;

    input  T[NUM_SHARES-1:0] in_a_t1;
    input  T[NUM_SHARES-1:0] in_b_t0;
    input  T[NUM_SHARES-1:0] in_c_t0;
    input  T[NUM_ZERO_RANDOM-1:0] in_r_raw_ab;
    input  T[NUM_ZERO_RANDOM-1:0] in_r_raw_ac;
    input  T[NUM_QUADRATIC-1:0] in_p_ab;
    input  T[NUM_QUADRATIC-1:0] in_p_ac;
    output T[NUM_SHARES-1:0] out_d;
    output T[NUM_SHARES-1:0] out_e;
    input in_clock;
    input in_reset;
    
    T[NUM_SHARES-1:0] r_ab;
    T[NUM_SHARES-1:0] r_ac;

    masked_zero #(
        .NUM_SHARES(NUM_SHARES), 
        .BIT_WIDTH(BIT_WIDTH)
    ) shared_0_b (
        .in_random(in_r_raw_ab),
        .out_random(r_ab),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    
    masked_zero #(
        .NUM_SHARES(NUM_SHARES), 
        .BIT_WIDTH(BIT_WIDTH)
    ) shared_0_c (
        .in_random(in_r_raw_ac),
        .out_random(r_ac),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    // Multiply B and A
    masked_hpc1_mul #(
        .NUM_SHARES(NUM_SHARES),
        .BIT_WIDTH(BIT_WIDTH)
    ) mul1 (
        .in_a(in_a_t1),
        .in_b(in_b_t0),
        .in_r(r_ab),
        .in_p(in_p_ab),
        .out_c(out_d),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    // Multiply C and A
    masked_hpc1_mul #(
        .NUM_SHARES(NUM_SHARES),
        .BIT_WIDTH(BIT_WIDTH)
    ) mul2 (
        .in_a(in_a_t1),
        .in_b(in_c_t0),
        .in_r(r_ac),
        .in_p(in_p_ac),
        .out_c(out_e),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    
endmodule: masked_test_parallel_hpc1_ls
`endif // MASKED_TEST_PARALLEL_HPC1_LS_SV
