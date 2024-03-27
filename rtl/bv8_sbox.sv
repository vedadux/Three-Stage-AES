`ifndef BV8_SBOX_SV
`define BV8_SBOX_SV

`include "aes128_package.sv"
`include "bv8_front_basis.sv"
`include "bv8_back_basis.sv"
`include "bv8_inv.sv"

// Compute AES Sbox, either forwards or backwards
module bv8_sbox (
    in_a, in_enc, out_b
);
    import aes128_package::*;
    input  bv8_t in_a;
    input  bit   in_enc;
    output bv8_t out_b;
    
    bv8_t front_xor, fwd_in, bwd_in;
    assign front_xor = {8{~in_enc}} & 8'h63;
    bv8_front_basis front(.in_x(in_a ^ front_xor), .out_fwd(fwd_in), .out_bwd(bwd_in));

    bv8_t front_choice, inv_out;
    assign front_choice = in_enc ? fwd_in : bwd_in;
    bv8_inv  inv(.in_a(front_choice), .out_b(inv_out));

    bv8_t fwd_out, bwd_out;
    bv8_back_basis back(.in_x(inv_out), .out_fwd(fwd_out), .out_bwd(bwd_out));

    bv8_t back_xor, back_choice;
    assign back_xor = {8{in_enc}} & 8'h63;
    assign back_choice = in_enc ? fwd_out : bwd_out;

    assign out_b = back_choice ^ back_xor;
endmodule : bv8_sbox
`endif // BV8_SBOX_SV
