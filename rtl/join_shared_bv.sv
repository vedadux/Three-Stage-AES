`ifndef JOIN_SHARED_BV_SV
`define JOIN_SHARED_BV_SV

module join_shared_bv #(
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

endmodule : join_shared_bv
`endif // JOIN_SHARED_BV_SV
