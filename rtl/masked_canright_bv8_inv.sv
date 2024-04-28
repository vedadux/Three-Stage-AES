`ifndef MASKED_CANRIGHT_BV8_INV_SV
`define MASKED_CANRIGHT_BV8_INV_SV

`include "aes128_package.sv"
`include "masked_split_bv.sv"
`include "masked_hpc3_mul.sv"
`include "register.sv"
`include "bv4_sq_scl_s.sv"
`include "masked_bv4_inv.sv"
`include "masked_canright_bv8_inv_stage4_hpc1.sv"
`include "masked_canright_bv8_inv_stage4_hpc3.sv"
`include "masked_join_bv.sv"

// Compute masked GF(2^8) Inverse
module masked_canright_bv8_inv (
    in_a, in_random, out_b, in_clock, in_reset
);
    import aes128_package::*;
    parameter NUM_SHARES = 2;
    parameter stage_type_t STAGE_TYPE = DEFAULT_STAGE_TYPE;
    localparam NUM_QUARDATIC = num_quad(NUM_SHARES);
    localparam NUM_ZERO_RANDOM = num_zero_random(NUM_SHARES);
    localparam NUM_RANDOM = num_canright_inv_random(NUM_SHARES, STAGE_TYPE);
    genvar i;

    input  bv8_t[NUM_SHARES-1:0] in_a;
    input    bit[NUM_RANDOM-1:0] in_random;
    output bv8_t[NUM_SHARES-1:0] out_b;
    input                    bit in_clock;
    input                    bit in_reset;

    bv4_t[NUM_QUARDATIC-1:0]      front_r;
    bv4_t[NUM_QUARDATIC-1:0]      front_p;
    
    localparam NUM_RANDOM_BV4_INV = masked_bv4_inv_randoms(NUM_SHARES);
    bit [NUM_RANDOM_BV4_INV-1:0] middle_randoms;
    localparam NUM_RANDOM_STAGE_4 = stage_4_canright_randoms(NUM_SHARES, STAGE_TYPE);
    bit [NUM_RANDOM_STAGE_4-1:0] back_randoms;
    
    assign {back_randoms, middle_randoms, front_p, front_r} = in_random;

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
    
    bv4_t[NUM_SHARES-1:0] inv_in_t1, inv_out_t3;
    assign inv_in_t1 = a_mul_t1 ^ a_xor_sq_scl_t1;
    masked_bv4_inv #(
        .NUM_SHARES(NUM_SHARES)
    ) bv4_inv (
        .in_x(inv_in_t1), 
        .in_random(middle_randoms), 
        .out_y(inv_out_t3), 
        .in_clock(in_clock), 
        .in_reset(in_reset)
    );
    
    bv4_t[1:0][NUM_SHARES-1:0] b_t4;
    generate
        if (STAGE_TYPE == HPC1) begin : stage4_hpc1
            masked_canright_bv8_inv_stage4_hpc1 #(
                .NUM_SHARES(NUM_SHARES)
            ) bv4_inv (
                .in_x_t3(inv_out_t3),
                .in_a_t1(a_t1), 
                .in_random(back_randoms), 
                .out_b_t4(b_t4), 
                .in_clock(in_clock), 
                .in_reset(in_reset)
            );
        end else if (STAGE_TYPE == HPC3) begin : stage4_hpc3
            masked_canright_bv8_inv_stage4_hpc3 #(
                .NUM_SHARES(NUM_SHARES)
            ) bv4_inv (
                .in_x_t3(inv_out_t3),
                .in_a_t1(a_t1), 
                .in_random(back_randoms), 
                .out_b_t4(b_t4), 
                .in_clock(in_clock), 
                .in_reset(in_reset)
            );
        end else begin : stage4_error
        $error("No known stage type");
        end
    endgenerate

    masked_join_bv #(
        .NUM_SHARES(NUM_SHARES),
        .HALF_WIDTH(4)
    ) join_back_i (
        .in_a(b_t4),
        .out_b(out_b)
    );
endmodule : masked_canright_bv8_inv
`endif // MASKED_CANRIGHT_BV8_INV_SV
