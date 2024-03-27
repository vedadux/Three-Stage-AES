`ifndef BV8_BACK_BASIS_SV
`define BV8_BACK_BASIS_SV

`include "aes128_package.sv"

// Compute the basis change in front of AES Sbox
module bv8_back_basis (
    in_x, out_fwd, out_bwd
);
    import aes128_package::*;
    input  bv8_t in_x;
    output bv8_t out_fwd;
    output bv8_t out_bwd;
    
    bit x0, x1, x2, x3, x4, x5, x6, x7;
    assign {x7, x6, x5, x4, x3, x2, x1, x0} = in_x;

    bit x8 ; assign x8  = x1 ^ x6; // depth 1
    bit x9 ; assign x9  = x0 ^ x6; // depth 1
    bit x10; assign x10 = x3 ^ x5; // depth 1
    bit x11; assign x11 = x2 ^ x10; // depth 2
    bit x12; assign x12 = x1 ^ x4; // depth 1
    bit x13; assign x13 = x3 ^ x7; // depth 1
    bit x14; assign x14 = x9 ^ x11; // depth 3
    bit x15; assign x15 = x7 ^ x10; // depth 2
    bit x16; assign x16 = x2 ^ x9; // depth 2
    bit x17; assign x17 = x5 ^ x12; // depth 2
    bit x18; assign x18 = x7 ^ x17; // depth 3
    bit x19; assign x19 = x4 ^ x8; // depth 2
    bit x20; assign x20 = x11 ^ x19; // depth 3
    bit x21; assign x21 = x15 ^ x16; // depth 3
    bit x22; assign x22 = x1 ^ x5; // depth 1
    bit x23; assign x23 = x13 ^ x22; // depth 2
    bit x24; assign x24 = x19 ^ x23; // depth 3
    bit x25; assign x25 = x9 ^ x23; // depth 3
    
    bit y0 ; assign y0  = x19; // depth 2
    bit y1 ; assign y1  = x17; // depth 2
    bit y2 ; assign y2  = x14; // depth 3
    bit y3 ; assign y3  = x24; // depth 3
    bit y4 ; assign y4  = x15; // depth 2
    bit y5 ; assign y5  = x9; // depth 1
    bit y6 ; assign y6  = x13; // depth 1
    bit y7 ; assign y7  = x10; // depth 1
    bit y8 ; assign y8  = x2; // depth 0
    bit y9 ; assign y9  = x22; // depth 1
    bit y10; assign y10 = x18; // depth 3
    bit y11; assign y11 = x20; // depth 3
    bit y12; assign y12 = x8; // depth 1
    bit y13; assign y13 = x21; // depth 3
    bit y14; assign y14 = x25; // depth 3
    bit y15; assign y15 = x12; // depth 1

    assign out_fwd = {y7, y6, y5, y4, y3, y2, y1, y0};
    assign out_bwd = {y15, y14, y13, y12, y11, y10, y9, y8};
endmodule : bv8_back_basis
`endif // BV8_BACK_BASIS_SV
