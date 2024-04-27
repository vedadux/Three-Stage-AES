`ifndef MASKED_4STAGE_BV8_INV_SV
`define MASKED_4STAGE_BV8_INV_SV

`include "aes128_package.sv"
`include "masked_split_bv.sv"
`include "masked_hpc3_mul.sv"
`include "register.sv"
`include "bv4_sq_scl_s.sv"
`include "bv4_pow4.sv"
`include "masked_4stage_bv8_inv_stage2.sv"
`include "masked_join_bv.sv"

// Compute masked GF(2^8) Inverse
module masked_4stage_bv8_inv (
    in_a, in_random, out_b, in_clock, in_reset
);
    import aes128_package::*;
    parameter NUM_SHARES = 2;
    localparam NUM_QUARDATIC = num_quad(NUM_SHARES);
    localparam NUM_ZERO_RANDOM = num_zero_random(NUM_SHARES);
    localparam NUM_RANDOM = num_4stage_inv_random(NUM_SHARES);
    genvar i;

    input  bv8_t[NUM_SHARES-1:0] in_a;
    input    bit[NUM_RANDOM-1:0] in_random;
    output bv8_t[NUM_SHARES-1:0] out_b;
    input                    bit in_clock;
    input                    bit in_reset;

    bv4_t[NUM_QUARDATIC-1:0]      front_r;
    bv4_t[NUM_QUARDATIC-1:0]      front_p;
    
    localparam NUM_RANDOM_STAGE_2 = stage_2_lat4_randoms(NUM_SHARES);
    bit [NUM_RANDOM_STAGE_2-1:0] middle_randoms;

    bv2_t[NUM_ZERO_RANDOM-1:0]    back_r_raw;
    bv2_t[3:0][NUM_QUARDATIC-1:0] back_ps;
    
    assign {back_ps, back_r_raw, middle_randoms, front_p, front_r} = in_random;

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
    bv4_t[NUM_SHARES-1:0] mul_a0_t3;
    bv4_t[NUM_SHARES-1:0] mul_a1_t3;

    masked_4stage_bv8_inv_stage2 #(
            .NUM_SHARES(NUM_SHARES)
        ) stage2 (
            .in_a0_t1(a_t1[0]),
            .in_a1_t1(a_t1[1]),
            .in_pow4_t1(pow4_out_t1),
            .in_random(middle_randoms),
            .out_theta_t2(theta_t2),
            .out_mul_a0_t3(mul_a0_t3),
            .out_mul_a1_t3(mul_a1_t3),
            .in_clock(in_clock),
            .in_reset(in_reset)
    );
        
    bv2_t[1:0][NUM_SHARES-1:0] mul_a0_split_t3, mul_a1_split_t3;
    
    masked_split_bv #(
        .NUM_SHARES(NUM_SHARES),
        .HALF_WIDTH(2)
    ) split_a0_t3 (
        .in_a(mul_a0_t3),
        .out_b(mul_a0_split_t3)
    );
    
    masked_split_bv #(
        .NUM_SHARES(NUM_SHARES),
        .HALF_WIDTH(2)
    ) split_a1_t3 (
        .in_a(mul_a1_t3),
        .out_b(mul_a1_split_t3)
    );

    bv2_t[3:0][NUM_SHARES-1:0] mul_theta_in_t3, mul_theta_out_t4;
    
    assign mul_theta_in_t3 = {mul_a0_split_t3, mul_a1_split_t3};

    bv2_t[NUM_SHARES-1:0] back_r;
    masked_zero #(
        .NUM_SHARES(NUM_SHARES), 
        .BIT_WIDTH(2)
    ) back_shared_0 (
        .in_random(back_r_raw),
        .out_random(back_r),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    generate
        for (i = 0; i < 4; i += 1)
            masked_hpc1_mul #(
                .NUM_SHARES(NUM_SHARES),
                .BIT_WIDTH(2)
            ) mul_back_i (
                .in_a(mul_theta_in_t3[i]), 
                .in_b(theta_t2), 
                .in_r(back_r),
                .in_p(back_ps[i]),
                .out_c(mul_theta_out_t4[i]),
                .in_clock(in_clock),
                .in_reset(in_reset)
            );
    endgenerate

    bv4_t[1:0][NUM_SHARES-1:0] mul_back_joined_t4;

    generate
        for (i = 0; i < 2; i++)
            masked_join_bv #(
                .NUM_SHARES(NUM_SHARES),
                .HALF_WIDTH(2)
            ) join_back_i (
                .in_a(mul_theta_out_t4[i*2 +: 2]),
                .out_b(mul_back_joined_t4[i])
            );
    endgenerate

    masked_join_bv #(
        .NUM_SHARES(NUM_SHARES),
        .HALF_WIDTH(4)
    ) join_back_i (
        .in_a(mul_back_joined_t4),
        .out_b(out_b)
    );
endmodule : masked_4stage_bv8_inv
`endif // MASKED_4STAGE_BV8_INV_SV
