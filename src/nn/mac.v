module mac(
    input [31:0] op1,
    input [31:0] op2,
    input [31:0] op3,
    output signed [31:0] total_result,
    output        zero_mul,     
    output        zero_add,   
    output        ovf_mul,      
    output        ovf_add
);

wire signed [31:0] mul_result;

localparam MUL_OP = 4'b0110;  
localparam ADD_OP = 4'b0100;  

alu alu_mul(
    .alu_op(MUL_OP),  
    .op1(op1),
    .op2(op2),
    .zero(zero_mul),
    .result(mul_result),
    .ovf(ovf_mul)
);

alu alu_add(
    .alu_op(ADD_OP),  
    .op1(mul_result),
    .op2(op3),
    .zero(zero_add),
    .result(total_result),
    .ovf(ovf_add)
);

endmodule