module reduce_xor #(
    parameter NUM_ELEMENTS = 5,
    parameter ELEMENT_WIDTH = 4
)(
    input T[NUM_ELEMENTS-1:0] in_elements,
    output T out_xor
);
    typedef bit[ELEMENT_WIDTH-1:0] T;
    localparam NUM_LEVELS = $clog2(NUM_ELEMENTS) + 1;

    T[NUM_ELEMENTS-1:0] xor_levels [NUM_LEVELS];

    assign xor_levels[0] = in_elements;

    genvar level;
    genvar i;
    generate
        for (level = 1; level < NUM_LEVELS; level += 1)
        begin
            for (i = 0; i < NUM_ELEMENTS; i += 1)
            begin
                if (2 * i + 1 < NUM_ELEMENTS)
                    assign xor_levels[level][i] = xor_levels[level - 1][2 * i] ^ xor_levels[level - 1][2 * i + 1];
                else if (2 * i < NUM_ELEMENTS)
                    assign xor_levels[level][i] = xor_levels[level - 1][2 * i];
                else
                    assign xor_levels[level][i] = {ELEMENT_WIDTH{1'b0}};
            end
        end
    endgenerate

    assign out_xor = xor_levels[NUM_LEVELS-1][0];
endmodule