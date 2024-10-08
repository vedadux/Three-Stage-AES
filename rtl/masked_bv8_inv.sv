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

`ifndef MASKED_BV8_INV_SV
`define MASKED_BV8_INV_SV

`include "aes128_package.sv"
`include "masked_3stage_bv8_inv.sv"
`include "masked_4stage_bv8_inv.sv"
`include "masked_canright_bv8_inv.sv"

// Compute masked AES S-Box
module masked_bv8_inv (
    in_a, in_random, out_b, in_clock, in_reset
);
    import aes128_package::*;
    parameter NUM_SHARES = 2;
    parameter LATENCY = 4;
    parameter stage_type_t STAGE_TYPE = DEFAULT_STAGE_TYPE;
    parameter inverter_type_t INVERTER_TYPE = DEFAULT_INVERTER_TYPE;
    
    localparam NUM_RANDOM = num_bv8_inv_random(NUM_SHARES, LATENCY, STAGE_TYPE, INVERTER_TYPE);

    input  bv8_t[NUM_SHARES-1:0] in_a;
    input    bit[NUM_RANDOM-1:0] in_random;
    output bv8_t[NUM_SHARES-1:0] out_b;
    input                    bit in_clock;
    input                    bit in_reset;
   
    generate
        if (INVERTER_TYPE == NEW_DESIGN) begin : gen_new_design
            if (LATENCY == 3) begin : gen_lat3_new
                masked_3stage_bv8_inv #(
                    .NUM_SHARES(NUM_SHARES),
                    .STAGE_TYPE(STAGE_TYPE)
                ) inv (
                    .in_a(in_a), 
                    .in_random(in_random), 
                    .out_b(out_b),
                    .in_clock(in_clock),
                    .in_reset(in_reset)
                );
            end else if (LATENCY == 4) begin : gen_lat4_new
                if (STAGE_TYPE == HPC1) begin : gen_lat4_new_hpc1
                    masked_4stage_bv8_inv #(
                        .NUM_SHARES(NUM_SHARES)
                    ) inv (
                        .in_a(in_a), 
                        .in_random(in_random), 
                        .out_b(out_b),
                        .in_clock(in_clock),
                        .in_reset(in_reset)
                    );
                end else begin : gen_error_lat4_new
                    $fatal("Unsupported stage type");
                end
            end else begin : gen_error_new
                $fatal("Unsupported latency");
            end
        end else if (INVERTER_TYPE == CANRIGHT_DESIGN) begin : gen_canright_desing
            if (LATENCY == 4) begin : gen_canright
                masked_canright_bv8_inv #(
                    .NUM_SHARES(NUM_SHARES),
                    .STAGE_TYPE(STAGE_TYPE)
                ) inv (
                    .in_a(in_a),
                    .in_random(in_random),
                    .out_b(out_b),
                    .in_clock(in_clock),
                    .in_reset(in_reset)
                );
            end else begin : gen_error_canright
                $fatal("Unsupported latency");
            end
        end else begin : gen_error_design
            $fatal("Unsupported inverter type");
        end
    endgenerate
endmodule : masked_bv8_inv
`endif // MASKED_BV8_INV_SV
