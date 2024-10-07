`ifndef TEST_BV4_THETA_MUL
`define TEST_BV4_THETA_MUL

`include "aes128_package.sv"
`include "bv4_comp_theta.sv"
`include "bv2_mul.sv"

// Compute Theta = (Gamma_1 * Gamma_0 + (Gamma_1 + Gamma_0)^{2} * Sigma)^{-1}
module test_bv4_theta_mul (
    in_a, in_b, out_c
);
    import aes128_package::*;
    input  bv4_t in_a;
    input  bv2_t in_b;
    output bv2_t out_c;

    bv2_t th;
    bv4_comp_theta theta(.in_a(in_a), .out_b(th));
    bv2_mul mul(.in_a(th), .in_b(in_b), .out_c(out_c));
endmodule : test_bv4_theta_mul
`endif // TEST_BV4_THETA_MUL
