`ifndef BV2_SQ_SV
`define BV2_SQ_SV

`include "aes128_package.sv"

// Square input
module bv2_sq (
    in_a, out_b
);
    import aes128_package::*;
    input  bv2_t in_a;
    output bv2_t out_b;

    assign out_b = {in_a[0], in_a[1]};
endmodule : bv2_sq
`endif // BV2_SQ_SV
