`ifndef BV8_FRONT_BASIS_SV
`define BV8_FRONT_BASIS_SV

`include "aes128_package.sv"

// Compute GF(2^8) Inverse
module bv8_front_basis (
    in_x, out_fwd, out_bwd
);
    import aes128_package::*;
    input  bv8_t in_x;
    output bv8_t out_fwd;
    output bv8_t out_bwd;
    
    bit x0, x1, x2, x3, x4, x5, x6, x7;
    assign {x7, x6, x5, x4, x3, x2, x1, x0} = in_x;

    bit x8 = x3 ^ x6; // depth 1
    bit x9 = x0 ^ x1; // depth 1
    bit x10 = x8 ^ x9; // depth 2
    bit x11 = x6 ^ x9; // depth 2
    bit x12 = x4 ^ x7; // depth 1
    bit x13 = x5 ^ x6; // depth 1
    bit x14 = x0 ^ x4; // depth 1
    bit x15 = x0 ^ x13; // depth 2
    bit x16 = x6 ^ x12; // depth 2
    bit x17 = x10 ^ x16; // depth 3
    bit x18 = x7 ^ x16; // depth 3
    bit x19 = x7 ^ x15; // depth 3
    bit x20 = x1 ^ x15; // depth 3
    bit x21 = x13 ^ x14; // depth 2
    bit x22 = x1 ^ x21; // depth 3
    bit x23 = x4 ^ x11; // depth 3
    bit x24 = x2 ^ x5; // depth 1
    bit x25 = x3 ^ x14; // depth 2
    bit x26 = x2 ^ x10; // depth 3
    bit x27 = x7 ^ x24; // depth 2
    bit x28 = x11 ^ x27; // depth 3
    
    bit y0 = x26; // depth 3
    bit y1 = x15; // depth 2
    bit y2 = x0; // depth 0
    bit y3 = x17; // depth 3
    bit y4 = x19; // depth 3
    bit y5 = x20; // depth 3
    bit y6 = x21; // depth 2
    bit y7 = x28; // depth 3
    bit y8 = x22; // depth 3
    bit y9 = x25; // depth 2
    bit y10 = x27; // depth 2
    bit y11 = x16; // depth 2
    bit y12 = x10; // depth 2
    bit y13 = x18; // depth 3
    bit y14 = x23; // depth 3
    bit y15 = x12; // depth 1

    assign out_fwd = {y7, y6, y5, y4, y3, y2, y1, y0};
    assign out_bwd = {y15, y14, y13, y12, y11, y10, y9, y8};
endmodule : bv8_front_basis
`endif // BV8_FRONT_BASIS_SV
