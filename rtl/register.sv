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

`ifndef REGISTER_SV
`define REGISTER_SV

`include "aes128_package.sv"

module register (
    in_value, out_value, in_clock, in_reset
);
    import aes128_package::*;
    parameter type T = bit;
    parameter dff_type_t DFF_TYPE = DFF;

    input  T in_value;
    output T out_value;
    input in_clock;
    input in_reset;

    T reg_value_d;
    T reg_value_q;
    always_ff @(posedge in_clock) begin : gen_regs
        if (DFF_TYPE == DFF) begin
            reg_value_q <= reg_value_d;
        end else if (DFF_TYPE == DFF_R) begin
            if (in_reset) reg_value_q <= 0;
            else          reg_value_q <= reg_value_d;
        end
    end

    assign reg_value_d = in_value;
    assign out_value = reg_value_q;
endmodule : register
`endif // REGISTER_SV
