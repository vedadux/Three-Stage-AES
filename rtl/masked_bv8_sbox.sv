`ifndef MASKED_BV8_SBOX_SV
`define MASKED_BV8_SBOX_SV

`include "aes128_package.sv"
`include "bv8_front_basis.sv"
`include "bv8_back_basis.sv"


// Compute masked AES S-Box
module masked_bv8_sbox #(
    parameter NUM_SHARES = 2
)(
    in_a, in_enc, in_random, out_b, in_clock, in_reset
);
    import aes128_package::*;
    localparam NUM_RANDOM = num_inv_random(NUM_SHARES);

    input  bv8_t[NUM_SHARES-1:0] in_a;
    input                    bit in_enc;
    input    bit[NUM_RANDOM-1:0] in_random;
    output bv8_t[NUM_SHARES-1:0] out_b;
    input                    bit in_clock;
    input                    bit in_reset;

    bv8_t[NUM_SHARES-1:0] front_fwd;
    bv8_t[NUM_SHARES-1:0] front_bwd;
    
    bv8_t[NUM_SHARES-1:0] inv_in_a;
    bv8_t[NUM_SHARES-1:0] inv_out_b;

    bv8_t[NUM_SHARES-1:0] back_fwd;
    bv8_t[NUM_SHARES-1:0] back_bwd;
    
    masked_bv8_inv #(
        .NUM_SHARES(NUM_SHARES)
    ) inv(
        .in_a(inv_in_a), 
        .in_random(in_random),
        .out_b(inv_out_b),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );

    genvar i;
    generate
        for (i = 0; i < NUM_SHARES; i += 1) begin
            bv8_front_basis front_i(.in_x(in_a[i]), .out_fwd(front_fwd[i]), .out_bwd(front_bwd[i]));
            bv8_back_basis back_i(.in_x(inv_out_b[i]), .out_fwd(back_fwd[i]), .out_bwd(back_bwd[i]));
        end
    endgenerate
    
    assign inv_in_a = in_enc ? front_fwd : front_bwd;
    assign out_b = in_enc ? back_fwd : back_bwd;
    
endmodule : masked_bv8_sbox
`endif // MASKED_BV8_SBOX_SV
