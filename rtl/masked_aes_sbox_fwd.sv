`ifndef MASKED_AES_SBOX_FWD_SV
`define MASKED_AES_SBOX_FWD_SV

`include "aes128_package.sv"
`include "bv8_front_basis_fwd.sv"
`include "bv8_back_basis_fwd.sv"
`include "masked_3stage_bv8_inv.sv"
`include "masked_4stage_bv8_inv.sv"

// Compute masked AES S-Box
module masked_aes_sbox_fwd (
    in_a, in_random, out_b, in_clock, in_reset
);
    import aes128_package::*;
    parameter NUM_SHARES = 2;
    parameter LATENCY = 4;
    parameter stage_type_t STAGE_TYPE = DEFAULT_STAGE_TYPE;
    localparam NUM_RANDOM = (LATENCY == 3) ? num_3stage_inv_random(NUM_SHARES, STAGE_TYPE)
                                           : num_4stage_inv_random(NUM_SHARES);

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
    
    generate
        if (LATENCY == 3) begin : gen_lat3
            masked_3stage_bv8_inv #(
                .NUM_SHARES(NUM_SHARES),
                .STAGE_TYPE(STAGE_TYPE)
            ) inv (
                .in_a(fwd_in), 
                .in_random(in_random), 
                .out_b(inv_out),
                .in_clock(in_clock),
                .in_reset(in_reset)
            );
        end else if (LATENCY == 4) begin : gen_lat4
            masked_4stage_bv8_inv #(
                .NUM_SHARES(NUM_SHARES)
            ) inv (
                .in_a(fwd_in), 
                .in_random(in_random), 
                .out_b(inv_out),
                .in_clock(in_clock),
                .in_reset(in_reset)
            );
        end else begin : gen_error
            $error("Unsupported latency");    
        end
    endgenerate

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
