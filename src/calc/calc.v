module calc(input wire clk,
            input wire btnac,
            input wire btnl,
            input wire btnr,
            input wire btnc,
            input wire btnd,
            input wire [15:0] sw,
            output wire [15:0] led);

    
    wire signed [31:0] sw_extended = {{16{sw[15]}}, sw};
    wire signed [31:0] acc_res_extended;
    wire [3:0] alu_op;
    wire ovf_flag = 0;
    wire zero_flag = 0;
    wire signed [31:0] alu_result;
    
    alu alu_inst

endmodule
