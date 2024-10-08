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

`ifndef MASKED_BV4_INV_SV
`define MASKED_BV4_INV_SV

`include "aes128_package.sv"
`include "masked_split_bv.sv"
`include "register.sv"
`include "masked_hpc3_1_mul.sv"
`include "masked_hpc2_mul.sv"
`include "masked_join_bv.sv"

// Compute Lambda = Gamma^{-1}
module masked_bv4_inv #(
    parameter NUM_SHARES = 2
)(
    in_x, in_random, out_y, in_clock, in_reset
);
    import aes128_package::*;
    localparam NUM_QUADRATIC = num_quad(NUM_SHARES);
    localparam NUM_ZERO_RANDOM = num_zero_random(NUM_SHARES);
    localparam NUM_RANDOM = masked_bv4_inv_randoms(NUM_SHARES);

    input  bv4_t[NUM_SHARES-1:0] in_x;
    input    bit[NUM_RANDOM-1:0] in_random;
    output bv4_t[NUM_SHARES-1:0] out_y;
    input                    bit in_clock;
    input                    bit in_reset;
    
    genvar i;

    bv2_t[NUM_SHARES-1:0] xh_t0, xl_t0;

    bit[NUM_SHARES-1:0] x0_t0, x1_t0, x2_t0, x3_t0;
    masked_split_bv #(
        .NUM_SHARES(NUM_SHARES),
        .HALF_WIDTH(2)
    ) split_x (
        .in_a(in_x),
        .out_b({xh_t0, xl_t0})
    );

    masked_split_bv #(
        .NUM_SHARES(NUM_SHARES),
        .HALF_WIDTH(1)
    ) split_xl (
        .in_a(xl_t0),
        .out_b({x1_t0, x0_t0})
    );

    masked_split_bv #(
        .NUM_SHARES(NUM_SHARES),
        .HALF_WIDTH(1)
    ) split_xh (
        .in_a(xh_t0),
        .out_b({x3_t0, x2_t0})
    );
    
    bit[1:0][NUM_QUADRATIC-1:0] front_r, front_p; 

    bit[3:0][NUM_SHARES-1:0] back_r;
    bit[3:0][NUM_QUADRATIC-1:0] back_p;
    
    generate
        if (NUM_SHARES == 2) begin : zero_2_shares
            bit[NUM_ZERO_RANDOM-1:0] back_r_raw;
            bit[NUM_SHARES-1:0] back_r_shared;
            assign {back_p, back_r_raw, front_p, front_r} = in_random;
            masked_zero #(
                .NUM_SHARES(NUM_SHARES), 
                .BIT_WIDTH(1)
            ) shared_0 (
                .in_random(back_r_raw),
                .out_random(back_r_shared),
                .in_clock(in_clock),
                .in_reset(in_reset)
            );
            for (i = 0; i < 4; i++) begin : gen_eqs
                assign back_r[i] = back_r_shared;
            end
        end else begin : zero_more_shares
            bit[3:0][NUM_ZERO_RANDOM-1:0] back_r_raws;
            assign {back_p, back_r_raws, front_p, front_r} = in_random;
            for (i = 0; i < 4; i++) begin : gen_zeros    
                masked_zero #(
                    .NUM_SHARES(NUM_SHARES), 
                    .BIT_WIDTH(1)
                ) shared_0_i (
                    .in_random(back_r_raws[i]),
                    .out_random(back_r[i]),
                    .in_clock(in_clock),
                    .in_reset(in_reset)
                );
            end
        end
    endgenerate
    
    bit[NUM_SHARES-1:0] a0_t0, a1_t0;
    assign a0_t0 = x1_t0 ^ x0_t0;
    assign a1_t0 = x3_t0 ^ x2_t0;

    bit[NUM_SHARES-1:0] b0_t1, b1_t1;
    // b0 = x2 & x0;
    masked_hpc3_1_mul #(
        .NUM_SHARES(NUM_SHARES), 
        .BIT_WIDTH(1)
    ) mul_b0 (
        .in_a(x2_t0), .in_b(x0_t0), 
        .in_r(front_r[0]), .in_p(front_p[0]), 
        .out_c(b0_t1), 
        .in_clock(in_clock), .in_reset(in_reset)
    );
    // b1 = x3 & x1;
    masked_hpc3_1_mul #(
        .NUM_SHARES(NUM_SHARES), 
        .BIT_WIDTH(1)
    ) mul_b1 (
        .in_a(x3_t0), .in_b(x1_t0), 
        .in_r(front_r[1]), .in_p(front_p[1]), 
        .out_c(b1_t1), 
        .in_clock(in_clock), .in_reset(in_reset)
    );

    bit[NUM_SHARES-1:0] x0_t1, x1_t1, x2_t1, x3_t1;
    register #(.T(bit[3:0][NUM_SHARES-1:0])) reg_x (
        .in_value( {x3_t0, x2_t0, x1_t0, x0_t0}), 
        .out_value({x3_t1, x2_t1, x1_t1, x0_t1}), 
        .in_clock(in_clock), .in_reset(in_reset)
    );

    bit[NUM_SHARES-1:0] a0_t1, a1_t1;
    assign a0_t1 = x1_t1 ^ x0_t1;
    assign a1_t1 = x3_t1 ^ x2_t1;
    
    bit[NUM_SHARES-1:0] c0_t1, c1_t1;
    assign c0_t1 = a0_t1 ^ b0_t1;
    assign c1_t1 = a1_t1 ^ b0_t1;
    
    bit[NUM_SHARES-1:0] d0_t1, d1_t1;
    assign d0_t1 = x0_t1 ^ b1_t1;
    assign d1_t1 = x2_t1 ^ b1_t1;
    
    bit[NUM_SHARES-1:0] e0_t2, e1_t2;
    // e0 = x3 & c0;
    masked_hpc1_mul #(
        .NUM_SHARES(NUM_SHARES),
        .BIT_WIDTH(1)
    ) mul_e0 (
        .in_a(c0_t1), .in_b(x3_t0), 
        .in_r(back_r[0]),
        .in_p(back_p[0]),
        .out_c(e0_t2), 
        .in_clock(in_clock), .in_reset(in_reset)
    );
    // e1 = x1 & c1;
    masked_hpc1_mul #(
        .NUM_SHARES(NUM_SHARES),
        .BIT_WIDTH(1)
    ) mul_e1 (
        .in_a(c1_t1), .in_b(x1_t0), 
        .in_r(back_r[1]),
        .in_p(back_p[1]),
        .out_c(e1_t2), 
        .in_clock(in_clock), .in_reset(in_reset)
    );

    bit[NUM_SHARES-1:0] f0_t2, f1_t2;
    // f0 = a1 & d0;
    masked_hpc1_mul #(
        .NUM_SHARES(NUM_SHARES),
        .BIT_WIDTH(1)
    ) mul_f0 (
        .in_a(d0_t1), .in_b(a1_t0), 
        .in_r(back_r[2]),
        .in_p(back_p[2]),
        .out_c(f0_t2), 
        .in_clock(in_clock), .in_reset(in_reset)
    );
    // f1 = a0 & d1;
    masked_hpc1_mul #(
        .NUM_SHARES(NUM_SHARES),
        .BIT_WIDTH(1)
    ) mul_f1 (
        .in_a(d1_t1), .in_b(a0_t0), 
        .in_r(back_r[3]),
        .in_p(back_p[3]),
        .out_c(f1_t2), 
        .in_clock(in_clock), .in_reset(in_reset)
    );

    bit[NUM_SHARES-1:0] a0_t2, a1_t2, x0_t2, x2_t2;
    register #(.T(bit[3:0][NUM_SHARES-1:0])) reg_ax (
        .in_value( {a0_t1, a1_t1, x0_t1, x2_t1}), 
        .out_value({a0_t2, a1_t2, x0_t2, x2_t2}), 
        .in_clock(in_clock), .in_reset(in_reset)
    );

    bit[NUM_SHARES-1:0] y0_t2, y1_t2, y2_t2, y3_t2;
    
    assign y3_t2 = a0_t2 ^ e1_t2;
    assign y2_t2 = x0_t2 ^ f1_t2;
    assign y1_t2 = a1_t2 ^ e0_t2;
    assign y0_t2 = x2_t2 ^ f0_t2;

    bv2_t[NUM_SHARES-1:0] yl_t2, yh_t2;
    
    masked_join_bv #(
        .NUM_SHARES(NUM_SHARES),
        .HALF_WIDTH(1)
    ) join_yl (
        .in_a({y1_t2, y0_t2}),
        .out_b(yl_t2)
    );
    masked_join_bv #(
        .NUM_SHARES(NUM_SHARES),
        .HALF_WIDTH(1)
    ) join_yh (
        .in_a({y3_t2, y2_t2}),
        .out_b(yh_t2)
    );
    masked_join_bv #(
        .NUM_SHARES(NUM_SHARES),
        .HALF_WIDTH(2)
    ) join_y (
        .in_a({yh_t2, yl_t2}),
        .out_b(out_y)
    );
endmodule : masked_bv4_inv
`endif // MASKED_BV4_INV_SV
