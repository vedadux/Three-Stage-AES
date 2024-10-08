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

`ifndef MASKED_JOIN_BV_SV
`define MASKED_JOIN_BV_SV

module masked_join_bv #(
    parameter NUM_SHARES = 2,
    parameter HALF_WIDTH = 15
)(
    in_a, out_b
);
    localparam BIT_WIDTH = 2 * HALF_WIDTH;
    
    input bit[1:0][NUM_SHARES-1:0][HALF_WIDTH-1:0] in_a;
    output bit[NUM_SHARES-1:0][BIT_WIDTH-1:0] out_b;

    genvar i;
    generate
        for (i = 0; i < NUM_SHARES; i += 1) begin
            assign out_b[i] = {in_a[1][i], in_a[0][i]};
        end
    endgenerate

endmodule : masked_join_bv
`endif // MASKED_JOIN_BV_SV
