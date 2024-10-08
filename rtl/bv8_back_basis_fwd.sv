// 
// Copyright (C) 2024 Vedad Hadžić
// 
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
// 

`ifndef BV8_BACK_BASIS_FWD_SV
`define BV8_BACK_BASIS_FWD_SV

`include "aes128_package.sv"

// Compute the basis change in back of AES Sbox
module bv8_back_basis_fwd (
    in_x, out_fwd
);
    import aes128_package::*;
    input  bv8_t in_x;
    output bv8_t out_fwd;
    
    bit x0, x1, x2, x3, x4, x5, x6, x7;
    assign {x7, x6, x5, x4, x3, x2, x1, x0} = in_x;

    bit x8 ; assign x8  = x3 ^ x7; // depth 1
    bit x9 ; assign x9  = x1 ^ x5; // depth 1
    bit x10; assign x10 = x4 ^ x9; // depth 2
    bit x11; assign x11 = x4 ^ x6; // depth 1
    bit x12; assign x12 = x5 ^ x8; // depth 2
    bit x13; assign x13 = x3 ^ x5; // depth 1
    bit x14; assign x14 = x0 ^ x6; // depth 1
    bit x15; assign x15 = x2 ^ x14; // depth 2
    bit x16; assign x16 = x1 ^ x11; // depth 2
    bit x17; assign x17 = x13 ^ x15; // depth 3
    bit x18; assign x18 = x11 ^ x12; // depth 3

    bit y0; assign y0 = x16; // depth 2
    bit y1; assign y1 = x10; // depth 2
    bit y2; assign y2 = x17; // depth 3
    bit y3; assign y3 = x18; // depth 3
    bit y4; assign y4 = x12; // depth 2
    bit y5; assign y5 = x14; // depth 1
    bit y6; assign y6 = x8; // depth 1
    bit y7; assign y7 = x13; // depth 1

    assign out_fwd = {y7, y6, y5, y4, y3, y2, y1, y0};
endmodule : bv8_back_basis_fwd
`endif // BV8_BACK_BASIS_FWD_SV
