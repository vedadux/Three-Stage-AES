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

`ifndef BV4_POW4_SV
`define BV4_POW4_SV

`include "aes128_package.sv"

// Compute Theta = (Gamma_1 * Gamma_0 + (Gamma_1 + Gamma_0)^{2} * Sigma)^{-1}
module bv4_pow4 (
    in_a, out_b
);
    import aes128_package::*;
    input  bv4_t in_a;
    output bv4_t out_b;

    bv2_t[1:0] a;
    assign a = in_a;

    assign out_b = {a[0], a[1]};
endmodule : bv4_pow4
`endif // BV4_POW4_SV
