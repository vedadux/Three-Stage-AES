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
