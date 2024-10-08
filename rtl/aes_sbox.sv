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

`ifndef AES_SBOX_SV
`define AES_SBOX_SV

`include "aes128_package.sv"
`include "bv8_front_basis.sv"
`include "bv8_back_basis.sv"
`include "bv8_inv.sv"

// Compute AES Sbox, either forwards or backwards
module aes_sbox (
    in_a, in_enc, out_b
);
    import aes128_package::*;
    input  bv8_t in_a;
    input  bit   in_enc;
    output bv8_t out_b;
    
    bv8_t front_xor, back_xor;
    assign front_xor = {8{~in_enc}} & 8'h63;
    assign back_xor  = {8{in_enc}}  & 8'h63;
    
    bv8_t fwd_in, bwd_in;

    bv8_front_basis front(
        .in_x(in_a ^ front_xor), 
        .out_fwd(fwd_in), 
        .out_bwd(bwd_in)
    );

    bv8_t front_choice, inv_out;
    assign front_choice = in_enc ? fwd_in : bwd_in;
    
    bv8_inv inv(
        .in_a(front_choice), 
        .out_b(inv_out)
    );

    bv8_t fwd_out, bwd_out;
    
    bv8_back_basis back(
        .in_x(inv_out), 
        .out_fwd(fwd_out), 
        .out_bwd(bwd_out)
    );

    bv8_t back_choice;
    assign back_choice = in_enc ? fwd_out : bwd_out;

    assign out_b = back_choice ^ back_xor;
endmodule : aes_sbox
`endif // AES_SBOX_SV
