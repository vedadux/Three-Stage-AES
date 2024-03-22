
import aes128_package::*;

module test (
    input bit [(NUM_QUARDATIC - 1):0] in,
    output bit [(NUM_SHARES * NUM_SHARES - 1):0] out,
    input sh_bv8_t in2,
    output sh_bv8_t out2
);
    genvar i, j;
    generate
        for(i = 0; i < NUM_SHARES; i++)
            for (j = 0; j < NUM_SHARES; j++)
            begin
                if (i == j) assign out[NUM_SHARES * i + j] = 0;
                else        assign out[NUM_SHARES * i + j] = in[qindex(i,j)];
            end
    endgenerate

    assign out2[0] = 8'h12;
    assign out2[1] = 8'h34;
    assign out2[2] = 8'h56;

endmodule