import aes128_package::*;

// Scale input by Sigma^2 = W
module bv2_scl_sigma2 (
    in_a, out_b
);
    input  bv2_t in_a;
    output bv2_t out_b;

    assign out_b[0] = in_a[1];
    assign out_b[1] = in_a[0] ^ in_a[1];
endmodule