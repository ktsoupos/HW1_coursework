module alu (
  input signed [31:0] op1,
  input signed [31:0] op2, 
  input [3:0] alu_op,
  output reg zero,
  output reg signed [31:0] result,
  output reg ovf
);
  
  // ALU Operation Parameters
  parameter [3:0] ALUOP_LSR  = 4'b0000;  // Logical right shift
  parameter [3:0] ALUOP_LSL  = 4'b0001;  // Logical left shift
  parameter [3:0] ALUOP_ASR  = 4'b0010;  // Arithmetic right shift
  parameter [3:0] ALUOP_ASL  = 4'b0011;  // Arithmetic left shift
  parameter [3:0] ALUOP_ADD  = 4'b0100;  // Addition
  parameter [3:0] ALUOP_SUB  = 4'b0110;  // Subtraction
  parameter [3:0] ALUOP_MUL  = 4'b0111;  // Multiplication
  parameter [3:0] ALUOP_AND  = 4'b1000;  // Logical AND
  parameter [3:0] ALUOP_OR   = 4'b1001;  // Logical OR
  parameter [3:0] ALUOP_NOR  = 4'b1010;  // Logical NOR
  parameter [3:0] ALUOP_NAND = 4'b1011;  // Logical NAND
  parameter [3:0] ALUOP_XOR  = 4'b1100;  // Logical XOR
  
  reg signed [63:0] temp_result;
  
  always @(*) begin
    case(alu_op)
      ALUOP_LSR: begin  
        result = op1 >> op2;
        ovf = 0;
      end
      
      ALUOP_LSL: begin  
        result = op1 << op2;
        ovf = 0;
      end
      
      ALUOP_ASR: begin 
        result = op1 >>> op2;
        ovf = 0;
      end
      
      ALUOP_ASL: begin  
        result = op1 <<< op2;
        ovf = 0;
      end
      
      ALUOP_ADD: begin  
        result = op1 + op2;
        ovf = (op1[31] == op2[31]) && (result[31] != op1[31]);
      end
      
      ALUOP_SUB: begin 
        result = op1 - op2;
        ovf = (op1[31] != op2[31]) && (result[31] != op1[31]);
      end
      
      ALUOP_MUL: begin  
        temp_result = op1 * op2;
        result = temp_result[31:0];
        ovf = (temp_result[63:32] != {32{temp_result[31]}});
      end
      
      ALUOP_AND: begin  
        result = op1 & op2;
        ovf = 0;
      end
      
      ALUOP_OR: begin
        result = op1 | op2;
        ovf = 0;
      end
      
      ALUOP_NOR: begin  
        result = ~(op1 | op2);
        ovf = 0;
      end
      
      ALUOP_NAND: begin  
        result = ~(op1 & op2);
        ovf = 0;
      end
      
      ALUOP_XOR: begin 
        result = op1 ^ op2;
        ovf = 0;
      end
      
      default: begin
        result = 32'b0;
        ovf = 0;
      end
    endcase
    
    zero = (result == 0);
  end

endmodule