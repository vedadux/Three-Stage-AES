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

`ifndef BV8_INV_SV
`define BV8_INV_SV

`include "aes128_package.sv"
`include "bv4_mul.sv"
`include "bv4_sq_scl_s.sv"
`include "bv4_pow4.sv"
`include "bv4_comp_theta.sv"
`include "bv2_mul.sv"

// Compute GF(2^8) Inverse
module bv8_inv (
    in_a, out_b
);
    import aes128_package::*;
    input  bv8_t in_a;
    output bv8_t out_b;

    bv4_t[1:0] a;
    assign a = in_a;

    bv4_t a_mul, a_xor;
    bv4_mul mul (.in_a(a[0]), .in_b(a[1]), .out_c(a_mul));
    assign a_xor = a[0] ^ a[1];

    bv4_t a_xor_sq_scl;
    bv4_sq_scl_s sq_scl (.in_a(a_xor), .out_b(a_xor_sq_scl));
    
    bv4_t pow4_in, pow4_out;
    assign pow4_in = a_mul ^ a_xor_sq_scl;

    bv4_pow4 inv (.in_a(pow4_in), .out_b(pow4_out));

    bv2_t theta;
    bv4_comp_theta c_theta(.in_a(pow4_out), .out_b(theta));

    bv4_t mul_a0, mul_a1;
    bv4_mul mul0 (.in_a(a[0]), .in_b(pow4_out), .out_c(mul_a0));
    bv4_mul mul1 (.in_a(a[1]), .in_b(pow4_out), .out_c(mul_a1));
    
    bv2_t[3:0] mul_theta_in, mul_theta_out;
    assign mul_theta_in = {mul_a0, mul_a1};

    genvar i;
    generate
        for (i = 0; i < 4; i++)
            bv2_mul mul_back_i (.in_a(theta), .in_b(mul_theta_in[i]), .out_c(mul_theta_out[i]));
    endgenerate

    assign out_b = mul_theta_out;
endmodule : bv8_inv
`endif // BV8_INV_SV
