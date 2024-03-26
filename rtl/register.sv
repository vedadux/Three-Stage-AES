`ifndef REGISTER_SV
`define REGISTER_SV

module register #(
    parameter type T = bit
)(
    in_value, out_value, in_clock, in_reset
);
    input  T in_value;
    output T out_value;
    input in_clock;
    input in_reset;

    T reg_value_d;
    T reg_value_q;
    always_ff @(posedge in_clock) begin : gen_regs
        if (in_reset) reg_value_q <= 0;
        else          reg_value_q <= reg_value_d;
    end

    assign reg_value_d = in_value;
    assign out_value = reg_value_q;
endmodule : register
`endif // REGISTER_SV
