`ifndef BV2_SCL_SIGMA_SV
`define BV2_SCL_SIGMA_SV

`include "aes128_package.sv"

// Scale input by Sigma = W^2
module bv2_scl_sigma (
    in_a, out_b
);
    import aes128_package::*;
    input  bv2_t in_a;
    output bv2_t out_b;

    assign out_b[0] = in_a[0] ^ in_a[1];
    assign out_b[1] = in_a[0];
endmodule : bv2_scl_sigma
`endif // BV2_SCL_SIGMA_SV
