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

`ifndef BV4_COMP_THETA_SV
`define BV4_COMP_THETA_SV

`include "aes128_package.sv"
`include "bv2_mul.sv"
`include "bv2_sq.sv"
`include "bv2_scl_sigma.sv"

// Compute Theta = (Gamma_1 * Gamma_0 + (Gamma_1 + Gamma_0)^{2} * Sigma)^{-1}
module bv4_comp_theta (
    in_a, out_b
);
    import aes128_package::*;
    input  bv4_t in_a;
    output bv2_t out_b;

    bv2_t[1:0] a;
    assign a = in_a;

    bv2_t a_mul, a_xor;
    bv2_mul mul (.in_a(a[0]), .in_b(a[1]), .out_c(a_mul));
    assign a_xor = a[0] ^ a[1];

    bv2_t a_xor_sq, a_xor_sq_scl;
    bv2_sq sq (.in_a(a_xor), .out_b(a_xor_sq));
    bv2_scl_sigma scl (.in_a(a_xor_sq), .out_b(a_xor_sq_scl));
    
    bv2_t inv_in;
    assign inv_in = a_mul ^ a_xor_sq_scl;

    bv2_sq inv(.in_a(inv_in), .out_b(out_b));
endmodule : bv4_comp_theta
`endif // BV4_COMP_THETA_SV
