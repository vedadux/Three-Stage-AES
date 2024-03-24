
import aes128_package::*;

module test (
    input bit[9:0] in_elements,
    output bit out_xor
);
    reduce_xor #(.NUM_ELEMENTS(10), .ELEMENT_WIDTH(1)) xor_tree (.in_elements(in_elements), .out_xor(out_xor));
endmodule