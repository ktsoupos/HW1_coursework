module calc(input wire clk,
            input wire btnac,
            input wire btnl,
            input wire btnr,
            input wire btnc,
            input wire btnd,
            input wire [15:0] sw,
            output wire [15:0] led);

    
    // Sign-extended switch input
    wire signed [31:0] sw_extended;
    assign sw_extended = {{16{sw[15]}}, sw};
    
    // Sign-extended accumulator
    wire signed [31:0] acc_res_extended;
    assign acc_res_extended = {{16{led[15]}}, led};
    
    // ALU signals
    wire [3:0] alu_op;
    wire signed [31:0] alu_result;
    wire zero_flag;
    wire ovf_flag;
    
    // Instantiate encoder
    calc_enc alu_decoder (
        .btnl(btnl),
        .btnr(btnr),
        .btnd(btnd),
        .alu_op(alu_op)
    );
    
    // Instantiate ALU
    alu alu_inst(
        .op1(acc_res_extended),
        .op2(sw_extended),
        .alu_op(alu_op),
        .zero(zero_flag),
        .result(alu_result),
        .ovf(ovf_flag)
    );
    
    // Instantiate accumulator
    accumulator acc_inst(
        .clk(clk),
        .btnac(btnac),
        .btnc(btnc),
        .alu_result_low(alu_result[15:0]),
        .acc_low(led)
    );
endmodule