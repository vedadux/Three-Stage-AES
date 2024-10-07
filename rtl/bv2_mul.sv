`ifndef BV2_MUL_SV
`define BV2_MUL_SV

`include "aes128_package.sv"

// Multiply input A with input B
module bv2_mul (
    in_a, in_b, out_c
);
    import aes128_package::*;

    input  bv2_t in_a;
    input  bv2_t in_b;
    output bv2_t out_c;

    bv1_t front_0;  (* keep *) (* dont_touch *)  xor(front_0, in_a[0], in_a[1]);
    bv1_t front_1;  (* keep *) (* dont_touch *)  xor(front_1, in_b[0], in_b[1]);
    bv1_t middle_0; (* keep *) (* dont_touch *) nand(middle_0, in_a[0], in_b[0]);
    bv1_t middle_1; (* keep *) (* dont_touch *) nand(middle_1, in_a[1], in_b[1]);
    bv1_t middle_2; (* keep *) (* dont_touch *) nand(middle_2, front_0, front_1);
    bv1_t back_0;   (* keep *) (* dont_touch *)  xor(back_0, middle_0, middle_2);
    bv1_t back_1;   (* keep *) (* dont_touch *)  xor(back_1, middle_1, middle_2);
    
    assign out_c[0] = back_0;
    assign out_c[1] = back_1;
endmodule : bv2_mul
`endif // BV2_MUL_SV
