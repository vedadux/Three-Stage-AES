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

`ifndef BV4_SQ_SCL_S_SV
`define BV4_SQ_SCL_S_SV

`include "aes128_package.sv"
`include "bv2_sq.sv"
`include "bv2_scl_sigma2.sv"

// Scale input by s = Sigma^2 * Z
module bv4_sq_scl_s (
    in_a, out_b
);
    import aes128_package::*;
    input  bv4_t in_a;
    output bv4_t out_b;

    bv2_t[1:0] a;
    assign a = in_a;

    bv2_t[1:0] a_sq;
    bv2_sq sq0 (.in_a(a[0]), .out_b(a_sq[0]));
    bv2_sq sq1 (.in_a(a[1]), .out_b(a_sq[1]));
    
    bv2_t a0_scl;
    bv2_scl_sigma2 scl0 (.in_a(a_sq[0]), .out_b(a0_scl));

    bv2_t[1:0] b;
    
    assign b[0] = a0_scl;
    assign b[1] = a_sq[0] ^ a_sq[1];

    assign out_b = b;
endmodule : bv4_sq_scl_s
`endif // BV4_SQ_SCL_S_SV
