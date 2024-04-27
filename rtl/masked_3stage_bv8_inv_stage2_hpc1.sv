`ifndef MASKED_3STAGE_BV8_INV_STAGE2_HPC1_SV
`define MASKED_3STAGE_BV8_INV_STAGE2_HPC1_SV

`include "aes128_package.sv"
`include "masked_zero.sv"
`include "masked_bv4_comp_theta.sv"
`include "masked_hpc1_mul.sv"

// Compute second stage of masked GF(2^8) Inverse
module masked_3stage_bv8_inv_stage2_hpc1 (
    in_a0_t0, in_a1_t0, in_pow4_t1, in_random, out_theta_t2, out_mul_a0_t2, out_mul_a1_t2, in_clock, in_reset
);
    import aes128_package::*;
    parameter NUM_SHARES = 2;
    localparam NUM_QUARDATIC = num_quad(NUM_SHARES);
    localparam NUM_ZERO_RANDOM = num_zero_random(NUM_SHARES);
    localparam NUM_RANDOM = stage_2_hpc1_randoms(NUM_SHARES);
    
    input  bv4_t[NUM_SHARES-1:0] in_a0_t0;
    input  bv4_t[NUM_SHARES-1:0] in_a1_t0;
    input  bv4_t[NUM_SHARES-1:0] in_pow4_t1;
    input    bit[NUM_RANDOM-1:0] in_random;
    output bv2_t[NUM_SHARES-1:0] out_theta_t2;
    output bv4_t[NUM_SHARES-1:0] out_mul_a0_t2;
    output bv4_t[NUM_SHARES-1:0] out_mul_a1_t2;
    input                    bit in_clock;
    input                    bit in_reset;

    bv2_t[NUM_QUARDATIC-1:0][1:0] theta_random;
    bv4_t[NUM_QUARDATIC-1:0]      right_p;
    bv4_t[NUM_QUARDATIC-1:0]      left_p;
    bv4_t[NUM_SHARES-1:0]         right_r;
    bv4_t[NUM_SHARES-1:0]         left_r;
    
    generate
        if (NUM_SHARES == 2) begin : gen_2_shares
            bv4_t[NUM_ZERO_RANDOM-1:0] joint_r_raw;
            bv4_t[NUM_SHARES-1:0]      joint_r;
            assign {joint_r_raw, left_p, right_p, theta_random} = in_random;
            masked_zero #(
                .NUM_SHARES(NUM_SHARES), 
                .BIT_WIDTH(4)
            ) joint_shared_0 (
                .in_random(joint_r_raw),
                .out_random(joint_r),
                .in_clock(in_clock),
                .in_reset(in_reset)
            );
            assign left_r = joint_r;
            assign right_r = joint_r;
        end else begin : gen_gt2_shares
            bv4_t[NUM_ZERO_RANDOM-1:0]    right_r_raw;
            bv4_t[NUM_ZERO_RANDOM-1:0]    left_r_raw;
            assign {left_r_raw, right_r_raw, left_p, right_p, theta_random} = in_random;
            masked_zero #(
                .NUM_SHARES(NUM_SHARES), 
                .BIT_WIDTH(4)
            ) right_shared_0 (
                .in_random(right_r_raw),
                .out_random(right_r),
                .in_clock(in_clock),
                .in_reset(in_reset)
            );
            masked_zero #(
                .NUM_SHARES(NUM_SHARES), 
                .BIT_WIDTH(4)
            ) left_shared_0 (
                .in_random(left_r_raw),
                .out_random(left_r),
                .in_clock(in_clock),
                .in_reset(in_reset)
            );
        end
    endgenerate
    
    masked_bv4_comp_theta #(
        .NUM_SHARES(NUM_SHARES)
    ) c_theta (
        .in_a(in_pow4_t1), 
        .in_random(theta_random), 
        .out_b(out_theta_t2),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    
    masked_hpc1_mul #(
        .NUM_SHARES(NUM_SHARES), 
        .BIT_WIDTH(4)
    ) mul_left (
        .in_a(in_pow4_t1), 
        .in_b(in_a0_t0),
        .in_r(left_r),
        .in_p(left_p), 
        .out_c(out_mul_a0_t2),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    
    masked_hpc1_mul #(
        .NUM_SHARES(NUM_SHARES), 
        .BIT_WIDTH(4)
    ) mul_right (
        .in_a(in_pow4_t1), 
        .in_b(in_a1_t0),
        .in_r(right_r),
        .in_p(right_p), 
        .out_c(out_mul_a1_t2),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
endmodule : masked_3stage_bv8_inv_stage2_hpc1
`endif // MASKED_3STAGE_BV8_INV_STAGE2_HPC1_SV
