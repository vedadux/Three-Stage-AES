import aes128_package::*;

module hpc1_mul #(
    parameter NUM_SHARES = 2,
    parameter type T = bit
)(
    input T[NUM_SHARES-1:0] in_a,
    input T[NUM_SHARES-1:0] in_b,
    input T[NUM_SHARES-1:0] in_r,
    input T[NUM_QUARDATIC-1:0] in_p,
    output T[NUM_SHARES-1:0] out_c,
    input in_clock,
    input in_reset
);




endmodule