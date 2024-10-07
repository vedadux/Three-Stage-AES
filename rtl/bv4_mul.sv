`ifndef BV4_MUL_SV
`define BV4_MUL_SV

`include "aes128_package.sv"
`include "bv2_mul.sv"
`include "bv2_scl_sigma.sv"

/* Some results:
        with opt | without opt | new opt  | new no opt | opt no abc | opt simple | opt abc guided negs | opt abc guided
    2:  1576.050 |  1765.176   | 1555.036 | 1567.804   | 1540.938   | 1512.476   | 1524.180            | 1560.090
    3:  3751.132 |  3647.126   | 3468.374 | 3478.748   | 3394.958   | 3445.764   | 3368.624            | 3365.432
    4:  5661.810 |  5738.684   | 5426.134 | 5504.604   | 5460.182   | 5496.092   | 5318.670            | 5301.114
    5:  9615.634 |  9510.298   | 8967.392 | 9279.676   | 9141.356   | 9295.104   | 8756.454            | 8737.568
*/

`define USE_BV4_MUL_OPT
// Multiply input A with input B
module bv4_mul (
    in_a, in_b, out_c
);
    import aes128_package::*;
    input  bv4_t in_a;
    input  bv4_t in_b;
    output bv4_t out_c;

    `ifdef USE_BV4_MUL_OPT
        bv1_t front_0 ; (* keep *) (* dont_touch *)  xor(front_0,  in_a[2], in_a[0]);
        bv1_t front_1 ; (* keep *) (* dont_touch *)  xor(front_1,  in_a[3], in_a[1]);
        bv1_t front_2 ; (* keep *) (* dont_touch *)  xor(front_2,  in_b[2], in_b[0]);
        bv1_t front_3 ; (* keep *) (* dont_touch *)  xor(front_3,  in_b[3], in_b[1]);
        bv1_t front_4 ; (* keep *) (* dont_touch *)  xor(front_4,  front_1, front_0);
        bv1_t front_5 ; (* keep *) (* dont_touch *)  xor(front_5,  front_3, front_2);
        bv1_t front_6 ; (* keep *) (* dont_touch *)  xor(front_6,  in_a[1], in_a[0]);
        bv1_t front_7 ; (* keep *) (* dont_touch *)  xor(front_7,  in_b[1], in_b[0]);
        bv1_t front_8 ; (* keep *) (* dont_touch *)  xor(front_8,  in_a[3], in_a[2]);
        bv1_t front_9 ; (* keep *) (* dont_touch *)  xor(front_9,  in_b[3], in_b[2]);
        bv1_t middle_0; (* keep *) (* dont_touch *) nand(middle_0, in_b[0], in_a[0]);
        bv1_t middle_1; (* keep *) (* dont_touch *) nand(middle_1, front_6, front_7);
        bv1_t middle_2; (* keep *) (* dont_touch *) nand(middle_2, in_b[1], in_a[1]);
        bv1_t middle_3; (* keep *) (* dont_touch *) nand(middle_3, in_b[2], in_a[2]);
        bv1_t middle_4; (* keep *) (* dont_touch *) nand(middle_4, front_8, front_9);
        bv1_t middle_5; (* keep *) (* dont_touch *) nand(middle_5, in_b[3], in_a[3]);
        bv1_t middle_6; (* keep *) (* dont_touch *) nand(middle_6, front_2, front_0);
        bv1_t middle_7; (* keep *) (* dont_touch *) nand(middle_7, front_4, front_5);
        bv1_t middle_8; (* keep *) (* dont_touch *) nand(middle_8, front_3, front_1);
        bv1_t back_0  ; (* keep *) (* dont_touch *)  xor(back_0,   middle_6, middle_8);
        bv1_t back_1  ; (* keep *) (* dont_touch *)  xor(back_1,   middle_0, middle_1);
        bv1_t back_2  ; (* keep *) (* dont_touch *)  xor(back_2,   back_0,   back_1  );
        bv1_t back_3  ; (* keep *) (* dont_touch *)  xor(back_3,   middle_6, middle_7);
        bv1_t back_4  ; (* keep *) (* dont_touch *)  xor(back_4,   middle_1, middle_2);
        bv1_t back_5  ; (* keep *) (* dont_touch *)  xor(back_5,   middle_3, back_0  );
        bv1_t back_6  ; (* keep *) (* dont_touch *)  xor(back_6,   middle_4, back_5  );
        bv1_t back_7  ; (* keep *) (* dont_touch *)  xor(back_7,   back_3,   back_4  );
        bv1_t back_8  ; (* keep *) (* dont_touch *)  xor(back_8,   middle_5, back_3  );
        bv1_t back_9  ; (* keep *) (* dont_touch *)  xor(back_9,   middle_4, back_8  );
        
        assign out_c[0] = back_2;
        assign out_c[1] = back_7;
        assign out_c[2] = back_6;
        assign out_c[3] = back_9;
    `else // no USE_BV4_MUL_OPT
        bv2_t a_xor, b_xor;
        assign a_xor = in_a[1:0] ^ in_a[3:2];
        assign b_xor = in_b[1:0] ^ in_b[3:2];

        bv2_t[2:0] a_ext, b_ext, ab_dot;
        assign a_ext = {a_xor, in_a};
        assign b_ext = {b_xor, in_b};
        bv2_mul multiplier_bv2_0 (.in_a(a_ext[0]), .in_b(b_ext[0]), .out_c(ab_dot[0]));
        bv2_mul multiplier_bv2_1 (.in_a(a_ext[1]), .in_b(b_ext[1]), .out_c(ab_dot[1]));
        bv2_mul multiplier_bv2_2 (.in_a(a_ext[2]), .in_b(b_ext[2]), .out_c(ab_dot[2]));

        bv2_t mid; bv2_scl_sigma scale_bv2 (.in_a(ab_dot[2]), .out_b(mid));
        
        bv2_t[1:0] c;
        assign c[0] = ab_dot[0] ^ mid;
        assign c[1] = ab_dot[1] ^ mid;

        assign out_c = c;
    `endif // USE_BV4_MUL_OPT
endmodule : bv4_mul
`endif // BV4_MUL_SV
