`ifndef SHARE_ZERO_SV
`define SHARE_ZERO_SV

`include "aes128_package.sv"
`include "register.sv"

module share_zero #(
    parameter NUM_SHARES = 2,
    parameter BIT_WIDTH = 2
)(
    in_random, out_random, in_clock, in_reset
);
    import aes128_package::*;
    localparam NUM_NEEDED = num_share_0(NUM_SHARES);
    typedef bit[BIT_WIDTH-1:0] T;
    
    input  T[NUM_NEEDED-1:0] in_random;
    output T[NUM_SHARES-1:0] out_random;
    input  in_clock;
    input  in_reset;
    
    T[NUM_SHARES-1:0] shared_zero;
    generate
        if (NUM_SHARES == 2) begin
            assign shared_zero[0] = in_random[0];
            assign shared_zero[1] = in_random[0];
        end
        else if (NUM_SHARES == 3) begin
            assign shared_zero[0] = in_random[0];
            assign shared_zero[1] = in_random[1];
            assign shared_zero[2] = in_random[0] ^ in_random[1];
        end
        else if (NUM_SHARES == 4 || NUM_SHARES == 5) begin
            T[NUM_SHARES-1:0] shuffled_random = {in_random[0], in_random[NUM_SHARES-1:1]};
            assign shared_zero = in_random ^ shuffled_random;
        end
        else $error("Unsuported number of shares");
    endgenerate

    register #(.T(T[NUM_SHARES-1:0])) reg_stage (
        .in_value(shared_zero),
        .out_value(out_random),
        .in_clock(in_clock),
        .in_reset(in_reset)
    );
endmodule : share_zero
`endif // SHARE_ZERO_SV
