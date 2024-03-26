`ifndef BV4_MUL_SV
`define BV4_MUL_SV

`include "aes128_package.sv"
`include "bv2_mul.sv"
`include "bv2_scl_sigma.sv"

// Multiply input A with input B
module bv4_mul (
    in_a, in_b, out_c
);
    import aes128_package::*;
    input  bv4_t in_a;
    input  bv4_t in_b;
    output bv4_t out_c;

    bv2_t a_xor, b_xor;
    assign a_xor = in_a[1:0] ^ in_a[3:2];
    assign b_xor = in_b[1:0] ^ in_b[3:2];

    bv2_t[2:0] a_ext, b_ext, ab_dot;
    assign a_ext = {a_xor, in_a};
    assign b_ext = {b_xor, in_b};
    bv2_mul multiplier_bv2_0 (.in_a(a_ext[0]), .in_b(b_ext[0]), .out_c(ab_dot[0]));
    bv2_mul multiplier_bv2_1 (.in_a(a_ext[1]), .in_b(b_ext[1]), .out_c(ab_dot[1]));
    bv2_mul multiplier_bv2_2 (.in_a(a_ext[2]), .in_b(b_ext[2]), .out_c(ab_dot[2]));

    bv2_t mid; bv2_scl_sigma scale_bv2 (.in_a(ab_dot[2]), .out_b(mid));
    
    bv2_t[1:0] c;
    assign c[0] = ab_dot[0] ^ mid;
    assign c[1] = ab_dot[1] ^ mid;

    assign out_c = c;
endmodule : bv4_mul
`endif // BV4_MUL_SV
