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

`ifndef GENERIC_MUL_SV
`define GENERIC_MUL_SV

`include "aes128_package.sv"
`include "bv2_mul.sv"
`include "bv4_mul.sv"

// Multiply input A with input B
module generic_mul #(
    parameter BIT_WIDTH = 2
)(
    in_a, in_b, out_c
);
    import aes128_package::*;
    typedef bit[BIT_WIDTH-1:0] T;

    input  T in_a;
    input  T in_b;
    output T out_c;

    generate
        if (BIT_WIDTH == 1) begin : gen_bv1_mul
            assign out_c = in_a & in_b;
        end else if (BIT_WIDTH == 2) begin : gen_bv2_mul
            bv2_mul multiplier_bv2 (.in_a(in_a), .in_b(in_b), .out_c(out_c));
        end else if (BIT_WIDTH == 4) begin : gen_bv4_mul
            bv4_mul multiplier_bv4 (.in_a(in_a), .in_b(in_b), .out_c(out_c));
        end else begin : gen_error
            $fatal("Unsupported type");
        end
    endgenerate
endmodule : generic_mul
`endif // GENERIC_MUL_SV
