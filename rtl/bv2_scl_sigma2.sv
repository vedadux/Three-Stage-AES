`ifndef BV2_SCL_SIGMA2_SV
`define BV2_SCL_SIGMA2_SV

`include "aes128_package.sv"

// Scale input by Sigma^2 = W
module bv2_scl_sigma2 (
    in_a, out_b
);
    import aes128_package::*;
    input  bv2_t in_a;
    output bv2_t out_b;

    assign out_b[0] = in_a[1];
    assign out_b[1] = in_a[0] ^ in_a[1];
endmodule : bv2_scl_sigma2
`endif // BV2_SCL_SIGMA2_SV
