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

`ifndef MASKED_AES_SBOX_FWD_SV
`define MASKED_AES_SBOX_FWD_SV

`include "aes128_package.sv"
`include "bv8_front_basis_fwd.sv"
`include "bv8_back_basis_fwd.sv"
`include "masked_bv8_inv.sv"

// Compute masked AES S-Box
module masked_aes_sbox_fwd (
    in_a, in_random, out_b, in_clock, in_reset
);
    import aes128_package::*;
    parameter NUM_SHARES = 2;
    parameter LATENCY = 3;
    parameter bit[0:0] CHOSEN_STAGE_TYPE = bit'(DEFAULT_STAGE_TYPE);
    parameter bit[0:0] CHOSEN_INVERTER_TYPE = bit'(DEFAULT_INVERTER_TYPE);
    localparam stage_type_t STAGE_TYPE = stage_type_t'(CHOSEN_STAGE_TYPE);
    localparam inverter_type_t INVERTER_TYPE = inverter_type_t'(CHOSEN_INVERTER_TYPE);
    localparam NUM_RANDOM = num_bv8_inv_random(NUM_SHARES, LATENCY, STAGE_TYPE, INVERTER_TYPE);

    input  bv8_t[NUM_SHARES-1:0] in_a;
    input    bit[NUM_RANDOM-1:0] in_random;
    output bv8_t[NUM_SHARES-1:0] out_b;
    input                    bit in_clock;
    input                    bit in_reset;

    genvar i;
    
    bv8_t[NUM_SHARES-1:0] fwd_in;
    
    generate
        for (i = 0; i < NUM_SHARES; i += 1)
            bv8_front_basis_fwd front_i(
                .in_x(in_a[i]), 
                .out_fwd(fwd_in[i])
            );
    endgenerate

    bv8_t[NUM_SHARES-1:0] inv_out;
    
    masked_bv8_inv #(
        .NUM_SHARES(NUM_SHARES),
        .STAGE_TYPE(STAGE_TYPE),
        .LATENCY(LATENCY),
        .INVERTER_TYPE(INVERTER_TYPE)
    ) inv (
        .in_a(fwd_in), 
        .in_random(in_random), 
        .out_b(inv_out),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    bv8_t[NUM_SHARES-1:0] fwd_out;

    generate
        for (i = 0; i < NUM_SHARES; i += 1)
            bv8_back_basis_fwd back(
                .in_x(inv_out[i]), 
                .out_fwd(fwd_out[i])
            );
    endgenerate

    assign out_b[NUM_SHARES-1:1] = fwd_out[NUM_SHARES-1:1];
    assign out_b[0] = fwd_out[0] ^ 8'h63;
endmodule : masked_aes_sbox_fwd
`endif // MASKED_AES_SBOX_FWD_SV
