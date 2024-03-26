`ifndef GENERIC_MUL_SV
`define GENERIC_MUL_SV

`include "aes128_package.sv"
`include "bv2_mul.sv"
`include "bv4_mul.sv"

// Multiply input A with input B
module generic_mul #(
    parameter BIT_WIDTH = 2
)(
    in_a, in_b, out_c
);
    import aes128_package::*;
    typedef bit[BIT_WIDTH-1:0] T;

    input  T in_a;
    input  T in_b;
    output T out_c;

    generate
        if (BIT_WIDTH == 1)
            assign out_c = in_a & in_b;
        else if (BIT_WIDTH == 2)
            bv2_mul multiplier_bv2 (.in_a(in_a), .in_b(in_b), .out_c(out_c));
        else if (BIT_WIDTH == 4)
            bv4_mul multiplier_bv4 (.in_a(in_a), .in_b(in_b), .out_c(out_c));
        else
            $error("Unsupported type");
    endgenerate
endmodule : generic_mul
`endif // GENERIC_MUL_SV
