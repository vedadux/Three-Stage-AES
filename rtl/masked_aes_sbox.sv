`ifndef MASKED_AES_SBOX_SV
`define MASKED_AES_SBOX_SV

`include "aes128_package.sv"
`include "bv8_front_basis.sv"
`include "bv8_back_basis.sv"
`include "masked_3stage_bv8_inv.sv"

// Compute masked AES S-Box
module masked_aes_sbox (
    in_a, in_enc, in_random, out_b, in_clock, in_reset
);
    import aes128_package::*;
    parameter NUM_SHARES = 2;
    parameter stage_type_t STAGE_TYPE = DEFAULT_STAGE_TYPE;
    localparam NUM_RANDOM = num_3stage_inv_random(NUM_SHARES, STAGE_TYPE);

    input  bv8_t[NUM_SHARES-1:0] in_a;
    input                    bit in_enc;
    input    bit[NUM_RANDOM-1:0] in_random;
    output bv8_t[NUM_SHARES-1:0] out_b;
    input                    bit in_clock;
    input                    bit in_reset;

    genvar i;
    
    bv8_t front_xor, back_xor;
    assign front_xor = {8{~in_enc}} & 8'h63;
    assign back_xor  = {8{in_enc}}  & 8'h63;

    bv8_t[NUM_SHARES-1:0] front_in, fwd_in, bwd_in;
    assign front_in[NUM_SHARES-1:1] = in_a[NUM_SHARES-1:1];
    assign front_in[0] = in_a[0] ^ front_xor;

    generate
        for (i = 0; i < NUM_SHARES; i += 1)
            bv8_front_basis front_i(
                .in_x(front_in[i]), 
                .out_fwd(fwd_in[i]), 
                .out_bwd(bwd_in[i])
            );
    endgenerate

    bv8_t[NUM_SHARES-1:0] front_choice, inv_out;
    assign front_choice = in_enc ? fwd_in : bwd_in;
    
    masked_3stage_bv8_inv #(
        .NUM_SHARES(NUM_SHARES),
        .STAGE_TYPE(STAGE_TYPE)
    ) inv(
        .in_a(front_choice), 
        .in_random(in_random), 
        .out_b(inv_out),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    bv8_t[NUM_SHARES-1:0] fwd_out, bwd_out;

    generate
        for (i = 0; i < NUM_SHARES; i += 1)
            bv8_back_basis back(
                .in_x(inv_out[i]), 
                .out_fwd(fwd_out[i]), 
                .out_bwd(bwd_out[i])
            );
    endgenerate

    bv8_t[NUM_SHARES-1:0] back_choice;
    assign back_choice = in_enc ? fwd_out : bwd_out;
    
    assign out_b[NUM_SHARES-1:1] = back_choice[NUM_SHARES-1:1];
    assign out_b[0] = back_choice[0] ^ back_xor;
endmodule : masked_aes_sbox
`endif // MASKED_AES_SBOX_SV
