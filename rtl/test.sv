
import aes128_package::*;

module test #(
    parameter NUM_SHARES = 3,
    parameter BIT_WIDTH = 1
)(
    in_a, in_b, in_c, in_r_ab, in_r_ac, in_p_ab, in_p_ac, out_d, out_e, in_clock, in_reset
);
    localparam NUM_QUADRATIC = num_quad(NUM_SHARES);
    typedef bit[BIT_WIDTH-1:0] T;

    input  T[NUM_SHARES-1:0] in_a;
    input  T[NUM_SHARES-1:0] in_b;
    input  T[NUM_SHARES-1:0] in_c;
    input  T[NUM_QUADRATIC-1:0] in_r_ab;
    input  T[NUM_QUADRATIC-1:0] in_r_ac;
    input  T[NUM_QUADRATIC-1:0] in_p_ab;
    input  T[NUM_QUADRATIC-1:0] in_p_ac;
    output T[NUM_SHARES-1:0] out_d;
    output T[NUM_SHARES-1:0] out_e;
    input in_clock;
    input in_reset;
    
    // Multiply A and B
    hpc3_mul #(
        .NUM_SHARES(NUM_SHARES),
        .BIT_WIDTH(BIT_WIDTH)
    ) mul1 (
        .in_a(in_b),
        .in_b(in_a),
        .in_r(in_r_ab),
        .in_p(in_p_ab),
        .out_c(out_d),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    // Multiply A and C
    hpc3_mul #(
        .NUM_SHARES(NUM_SHARES),
        .BIT_WIDTH(BIT_WIDTH)
    ) mul2 (
        .in_a(in_c),
        .in_b(in_a),
        .in_r(in_r_ab),
        .in_p(in_p_ac),
        .out_c(out_e),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
    
endmodule