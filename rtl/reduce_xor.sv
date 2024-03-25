module reduce_xor #(
    parameter NUM_ELEMENTS = 5,
    parameter ELEMENT_WIDTH = 4
)(
    in_elements, out_xor
);
    typedef bit[ELEMENT_WIDTH-1:0] T;
    
    input  T[NUM_ELEMENTS-1:0] in_elements;
    output T                   out_xor;

    generate
        if (NUM_ELEMENTS == 1)
            assign out_xor = in_elements[0];
        else begin
            localparam LEFT_ELEMENTS = NUM_ELEMENTS / 2;
            localparam RIGHT_ELEMENTS = NUM_ELEMENTS - LEFT_ELEMENTS;
            T left, right;
            reduce_xor #(
                .NUM_ELEMENTS(LEFT_ELEMENTS), 
                .ELEMENT_WIDTH(ELEMENT_WIDTH))
                left_tree (
                .in_elements(in_elements[LEFT_ELEMENTS-1:0]), 
                .out_xor(left)
            );
            reduce_xor #(
                .NUM_ELEMENTS(RIGHT_ELEMENTS), 
                .ELEMENT_WIDTH(ELEMENT_WIDTH))
                right_tree (
                .in_elements(in_elements[NUM_ELEMENTS-1:LEFT_ELEMENTS]), 
                .out_xor(right)
            );
            assign out_xor = left ^ right;
        end
    endgenerate
endmodule