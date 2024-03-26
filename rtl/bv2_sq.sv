import aes128_package::*;

// Square input
module bv2_sq (
    in_a, out_b
);
    input  bv2_t in_a;
    output bv2_t out_b;

    assign out_b = {in_a[0], in_a[1]};
endmodule