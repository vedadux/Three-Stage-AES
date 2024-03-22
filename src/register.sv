
module register #(
    parameter type T = bit
)(
    input T in_value,
    output T out_value,
    input in_clock,
    input in_reset
);
    T reg_value_d;
    T reg_value_q;
    always_ff @(posedge in_clock) begin : gen_regs
        if (in_reset) reg_value_q <= 0;
        else          reg_value_q <= reg_value_d;
    end

    assign in_value = reg_value_d;
    assign out_value = reg_value_q;
endmodule
