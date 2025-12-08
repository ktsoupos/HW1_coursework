module accumulator(input wire clk, 
                   input wire btnac,
                   input wire btnc,
                   input wire [15:0] alu_result_low,
                   output reg [15:0] acc_low);

    reg btnc_d;
    always @(posedge clk) btnc_d <= btnc;
    
    always @(posedge clk) begin
        if (btnac)
            acc_low <= 16'b0;
        else if (btnc & ~btnc_d)  // only latch on rising edge
            acc_low <= alu_result_low;
    end

endmodule
