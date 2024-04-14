`ifndef MASKED_BV8_INV_SV
`define MASKED_BV8_INV_SV

`include "aes128_package.sv"
`include "masked_split_bv.sv"
`include "masked_hpc3_mul.sv"
`include "register.sv"
`include "bv4_sq_scl_s.sv"
`include "bv4_pow4.sv"
`include "masked_bv8_inv_stage2_hpc1.sv"
`include "masked_bv8_inv_stage2_hpc3.sv"
`include "masked_join_bv.sv"

// Compute masked GF(2^8) Inverse
module masked_bv8_inv (
    in_a, in_random, out_b, in_clock, in_reset
);
    import aes128_package::*;
    parameter NUM_SHARES = 2;
    parameter stage_type_t STAGE_TYPE = DEFAULT_STAGE_TYPE;
    localparam NUM_QUARDATIC = num_quad(NUM_SHARES);
    localparam NUM_RANDOM = num_inv_random(NUM_SHARES, STAGE_TYPE);
    genvar i;

    input  bv8_t[NUM_SHARES-1:0] in_a;
    input    bit[NUM_RANDOM-1:0] in_random;
    output bv8_t[NUM_SHARES-1:0] out_b;
    input                    bit in_clock;
    input                    bit in_reset;

    bv4_t[NUM_QUARDATIC-1:0]      front_r;
    bv4_t[NUM_QUARDATIC-1:0]      front_p;
    
    localparam NUM_RANDOM_STAGE_2 = stage_2_randoms(NUM_SHARES, STAGE_TYPE);
    bit [NUM_RANDOM_STAGE_2-1:0] middle_randoms;

    bv2_t[NUM_QUARDATIC-1:0]      back_r;
    bv2_t[3:0][NUM_QUARDATIC-1:0] back_ps;
    
    assign {back_ps, back_r, middle_randoms, front_p, front_r} = in_random;
    
    bv4_t[1:0][NUM_SHARES-1:0] a_t0;
    masked_split_bv #(
        .NUM_SHARES(NUM_SHARES),
        .HALF_WIDTH(4)
    ) split_a_t0 (
        .in_a(in_a),
        .out_b(a_t0)
    );

    bv4_t[NUM_SHARES-1:0] a_mul_t1, a_xor_t1;
    masked_hpc3_mul #(
        .NUM_SHARES(NUM_SHARES), 
        .BIT_WIDTH(4)) 
    mul_front (
        .in_a(a_t0[0]), .in_b(a_t0[1]), 
        .in_r(front_r), .in_p(front_p), 
        .out_c(a_mul_t1), 
        .in_clock(in_clock), .in_reset(in_reset)
    );

    bv4_t[1:0][NUM_SHARES-1:0] a_t0_d, a_t0_q;
    register #(.T(bv4_t[1:0][NUM_SHARES-1:0])) reg_a (
        .in_value(a_t0_d), .out_value(a_t0_q), 
        .in_clock(in_clock), .in_reset(in_reset)
    );
    bv4_t[1:0][NUM_SHARES-1:0] a_t1;
    assign a_t0_d = a_t0;
    assign a_t1 = a_t0_q;

    assign a_xor_t1 = a_t1[0] ^ a_t1[1];

    bv4_t[NUM_SHARES-1:0] a_xor_sq_scl_t1;
    generate
        for (i = 0; i < NUM_SHARES; i++)
            bv4_sq_scl_s sq_scl_i (
                .in_a(a_xor_t1[i]), 
                .out_b(a_xor_sq_scl_t1[i])
            );    
    endgenerate
    
    bv4_t[NUM_SHARES-1:0] pow4_in_t1, pow4_out_t1;
    assign pow4_in_t1 = a_mul_t1 ^ a_xor_sq_scl_t1;
    generate
        for (i = 0; i < NUM_SHARES; i++)
            bv4_pow4 inv (
                .in_a(pow4_in_t1[i]), 
                .out_b(pow4_out_t1[i])
            );    
    endgenerate
    
    bv2_t[NUM_SHARES-1:0] theta_t2;
    bv4_t[NUM_SHARES-1:0] mul_a0_t2;
    bv4_t[NUM_SHARES-1:0] mul_a1_t2;

    generate
        if (STAGE_TYPE == HPC1) begin : gen_hpc1_stage
            masked_bv8_inv_stage2_hpc1 #(
                .NUM_SHARES(NUM_SHARES)
            ) stage2_hpc1 (
                .in_a0_t0(a_t0[0]),
                .in_a1_t0(a_t0[1]),
                .in_pow4_t1(pow4_out_t1),
                .in_random(middle_randoms),
                .out_theta_t2(theta_t2),
                .out_mul_a0_t2(mul_a0_t2),
                .out_mul_a1_t2(mul_a1_t2),
                .in_clock(in_clock),
                .in_reset(in_reset)
            );
        end else if (STAGE_TYPE == HPC3) begin : gen_hpc3_stage
            masked_bv8_inv_stage2_hpc3 #(
                .NUM_SHARES(NUM_SHARES)
            ) stage2_hpc3 (
                .in_a0_t1(a_t1[0]),
                .in_a1_t1(a_t1[1]),
                .in_pow4_t1(pow4_out_t1),
                .in_random(middle_randoms),
                .out_theta_t2(theta_t2),
                .out_mul_a0_t2(mul_a0_t2),
                .out_mul_a1_t2(mul_a1_t2),
                .in_clock(in_clock),
                .in_reset(in_reset)
            );
        end else begin : gen_error
            $error("Unknown stage type");
        end
    endgenerate

    bv2_t[1:0][NUM_SHARES-1:0] mul_a0_split_t2, mul_a1_split_t2;
    
    masked_split_bv #(
        .NUM_SHARES(NUM_SHARES),
        .HALF_WIDTH(2)
    ) split_a0_t2 (
        .in_a(mul_a0_t2),
        .out_b(mul_a0_split_t2)
    );
    
    masked_split_bv #(
        .NUM_SHARES(NUM_SHARES),
        .HALF_WIDTH(2)
    ) split_a1_t2 (
        .in_a(mul_a1_t2),
        .out_b(mul_a1_split_t2)
    );

    bv2_t[3:0][NUM_SHARES-1:0] mul_theta_in_t2, mul_theta_out_t3;
    
    assign mul_theta_in_t2 = {mul_a0_split_t2, mul_a1_split_t2};

    generate
        for (i = 0; i < 4; i += 1)
            masked_hpc3_mul #(
                .NUM_SHARES(NUM_SHARES),
                .BIT_WIDTH(2)
            ) mul_back_i (
                .in_a(mul_theta_in_t2[i]), 
                .in_b(theta_t2), 
                .in_r(back_r),
                .in_p(back_ps[i]),
                .out_c(mul_theta_out_t3[i]),
                .in_clock(in_clock),
                .in_reset(in_reset)
            );
    endgenerate

    bv4_t[1:0][NUM_SHARES-1:0] mul_back_joined_t3;

    generate
        for (i = 0; i < 2; i++)
            masked_join_bv #(
                .NUM_SHARES(NUM_SHARES),
                .HALF_WIDTH(2)
            ) join_back_i (
                .in_a(mul_theta_out_t3[i*2 +: 2]),
                .out_b(mul_back_joined_t3[i])
            );
    endgenerate

    masked_join_bv #(
        .NUM_SHARES(NUM_SHARES),
        .HALF_WIDTH(4)
    ) join_back_i (
        .in_a(mul_back_joined_t3),
        .out_b(out_b)
    );
endmodule : masked_bv8_inv
`endif // MASKED_BV8_INV_SV
