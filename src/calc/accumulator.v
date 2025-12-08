module accumulator(input wire clk, 
                   input wire btnac,
                   input wire btnc,
                   input wire [15:0] alu_result_low,
                   output reg [15:0] acc_low);

    
    always @(posedge clk) begin
        if (btnac) begin
            acc_low <= 16'b0;
        end else if (btnc) begin
            acc_low <= alu_result_low;
        end
    end
endmodule
