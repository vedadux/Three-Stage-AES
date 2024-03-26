`ifndef BV4_POW4_SV
`define BV4_POW4_SV

`include "aes128_package.sv"

// Compute Theta = (Gamma_1 * Gamma_0 + (Gamma_1 + Gamma_0)^{2} * Sigma)^{-1}
module bv4_pow4 (
    in_a, out_b
);
    import aes128_package::*;
    input  bv4_t in_a;
    output bv4_t out_b;

    bv2_t[1:0] a;
    assign a = in_a;

    assign out_b = {a[0], a[1]};
endmodule : bv4_pow4
`endif // BV4_POW4_SV
