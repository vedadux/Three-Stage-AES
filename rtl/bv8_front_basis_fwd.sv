`ifndef BV8_FRONT_BASIS_FWD_SV
`define BV8_FRONT_BASIS_FWD_SV

`include "aes128_package.sv"

// Compute the basis change in front of AES Sbox
module bv8_front_basis_fwd (
    in_x, out_fwd
);
    import aes128_package::*;
    input  bv8_t in_x;
    output bv8_t out_fwd;
    
    bit x0, x1, x2, x3, x4, x5, x6, x7;
    assign {x7, x6, x5, x4, x3, x2, x1, x0} = in_x;

    bit x8 ; assign x8  = x4 ^ x7; // depth 1
    bit x9 ; assign x9  = x0 ^ x1; // depth 1
    bit x10; assign x10 = x0 ^ x6; // depth 1
    bit x11; assign x11 = x5 ^ x10; // depth 2
    bit x12; assign x12 = x1 ^ x11; // depth 3
    bit x13; assign x13 = x1 ^ x2; // depth 1
    bit x14; assign x14 = x4 ^ x11; // depth 3
    bit x15; assign x15 = x10 ^ x13; // depth 2
    bit x16; assign x16 = x8 ^ x9; // depth 2
    bit x17; assign x17 = x7 ^ x11; // depth 3
    bit x18; assign x18 = x13 ^ x17; // depth 4
    bit x19; assign x19 = x3 ^ x15; // depth 3
    bit x20; assign x20 = x3 ^ x16; // depth 3

    bit y0; assign y0 = x19; // depth 3
    bit y1; assign y1 = x11; // depth 2
    bit y2; assign y2 = x0; // depth 0
    bit y3; assign y3 = x20; // depth 3
    bit y4; assign y4 = x17; // depth 3
    bit y5; assign y5 = x12; // depth 3
    bit y6; assign y6 = x14; // depth 3
    bit y7; assign y7 = x18; // depth 4

    assign out_fwd = {y7, y6, y5, y4, y3, y2, y1, y0};
endmodule : bv8_front_basis_fwd
`endif // BV8_FRONT_BASIS_FWD_SV
