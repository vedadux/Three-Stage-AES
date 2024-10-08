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

`ifndef TEST_BV4_THETA_MUL
`define TEST_BV4_THETA_MUL

`include "aes128_package.sv"
`include "bv4_comp_theta.sv"
`include "bv2_mul.sv"

// Compute Theta = (Gamma_1 * Gamma_0 + (Gamma_1 + Gamma_0)^{2} * Sigma)^{-1}
module test_bv4_theta_mul (
    in_a, in_b, out_c
);
    import aes128_package::*;
    input  bv4_t in_a;
    input  bv2_t in_b;
    output bv2_t out_c;

    bv2_t th;
    bv4_comp_theta theta(.in_a(in_a), .out_b(th));
    bv2_mul mul(.in_a(th), .in_b(in_b), .out_c(out_c));
endmodule : test_bv4_theta_mul
`endif // TEST_BV4_THETA_MUL
