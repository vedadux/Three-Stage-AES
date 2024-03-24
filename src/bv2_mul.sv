import aes128_package::*;

module bv2_mul (
    input bv2_t in_a,
    input bv2_t in_b,
    output bv2_t out_c
);
    bv1_t a_xor, b_xor;
    assign a_xor = in_a[0] ^ in_a[1];
    assign b_xor = in_b[0] ^ in_b[1];

    bv1_t[2:0] a_ext, b_ext, ab_dot;
    assign a_ext = {a_xor, in_a};
    assign b_ext = {b_xor, in_b};
    assign ab_dot = a_ext & b_ext;

    assign out_c[0] = ab_dot[0] ^ ab_dot[2];
    assign out_c[1] = ab_dot[1] ^ ab_dot[2];
endmodule