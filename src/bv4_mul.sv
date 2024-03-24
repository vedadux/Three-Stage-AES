import aes128_package::*;

module bv4_mul (
    input bv4_t in_a,
    input bv4_t in_b,
    output bv4_t out_c
);
    bv2_t a_xor, b_xor;
    assign a_xor = in_a[1:0] ^ in_a[3:2];
    assign b_xor = in_b[1:0] ^ in_b[3:2];

    bv2_t[2:0] a_ext, b_ext, ab_dot;
    assign a_ext = {a_xor, in_a};
    assign b_ext = {b_xor, in_b};
    bv2_mul multiplier_bv2_0 (.in_a(a_ext[0]), .in_b(b_ext[0]), .out_c(ab_dot[0]));
    bv2_mul multiplier_bv2_1 (.in_a(a_ext[1]), .in_b(b_ext[1]), .out_c(ab_dot[1]));
    bv2_mul multiplier_bv2_2 (.in_a(a_ext[2]), .in_b(b_ext[2]), .out_c(ab_dot[2]));

    bv2_t mid; bv2_scl_n scale_n_bv2 (.in_a(ab_dot[2]), .out_b(mid));
    
    assign out_c[1:0] = ab_dot[0] ^ mid;
    assign out_c[3:2] = ab_dot[1] ^ mid;
endmodule