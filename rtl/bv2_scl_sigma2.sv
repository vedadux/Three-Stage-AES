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

`ifndef BV2_SCL_SIGMA2_SV
`define BV2_SCL_SIGMA2_SV

`include "aes128_package.sv"

// Scale input by Sigma^2 = W
module bv2_scl_sigma2 (
    in_a, out_b
);
    import aes128_package::*;
    input  bv2_t in_a;
    output bv2_t out_b;

    assign out_b[0] = in_a[1];
    assign out_b[1] = in_a[0] ^ in_a[1];
endmodule : bv2_scl_sigma2
`endif // BV2_SCL_SIGMA2_SV
