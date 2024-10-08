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

`ifndef MASKED_ZERO_SV
`define MASKED_ZERO_SV

`include "aes128_package.sv"
`include "register.sv"

module masked_zero #(
    parameter NUM_SHARES = 2,
    parameter BIT_WIDTH = 2
)(
    in_random, out_random, in_clock, in_reset
);
    import aes128_package::*;
    localparam NUM_NEEDED = num_zero_random(NUM_SHARES);
    typedef bit[BIT_WIDTH-1:0] T;
    
    input  T[NUM_NEEDED-1:0] in_random;
    output T[NUM_SHARES-1:0] out_random;
    input  in_clock;
    input  in_reset;
    
    T[NUM_SHARES-1:0] shared_zero;
    generate
        if (NUM_SHARES == 2) begin : gen_2_shares
            assign shared_zero[0] = in_random[0];
            assign shared_zero[1] = in_random[0];
        end
        else if (NUM_SHARES == 3) begin : gen_3_shares
            assign shared_zero[0] = in_random[0];
            assign shared_zero[1] = in_random[1];
            assign shared_zero[2] = in_random[0] ^ in_random[1];
        end
        else if (NUM_SHARES == 4 || NUM_SHARES == 5) begin : gen_gt3_shares
            T[NUM_SHARES-1:0] shuffled_random = {in_random[0], in_random[NUM_SHARES-1:1]};
            assign shared_zero = in_random ^ shuffled_random;
        end
        else begin : gen_error
            $fatal("Unsuported number of shares");
        end
    endgenerate

    register #(.T(T[NUM_SHARES-1:0])) reg_stage (
        .in_value(shared_zero),
        .out_value(out_random),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
endmodule : masked_zero
`endif // MASKED_ZERO_SV
