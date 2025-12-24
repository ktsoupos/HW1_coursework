module regfile
    #(parameter DATAWIDTH = 32)
    (
        input wire clk,
        input wire resetn,
        input wire [3:0] readReg1,
        input wire [3:0] readReg2,
        input wire [3:0] readReg3,
        input wire [3:0] readReg4,
        input wire [3:0] writeReg1,
        input wire [3:0] writeReg2,
        input wire [DATAWIDTH-1:0] writeData1,
        input wire [DATAWIDTH-1:0] writeData2,
        input wire write,
        output wire [DATAWIDTH-1:0] readData1,   
        output wire [DATAWIDTH-1:0] readData2,   
        output wire [DATAWIDTH-1:0] readData3,
        output wire [DATAWIDTH-1:0] readData4
    );

    reg [DATAWIDTH-1:0] registers [0:15];
    integer i;  // Loop variable must be declared at module level for Verilog

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            for (i = 0; i < 16; i = i + 1) begin
                registers[i] <= {DATAWIDTH{1'b0}};
            end
        end else if (write) begin
            registers[writeReg1] <= writeData1;
            registers[writeReg2] <= writeData2;
        end
    end
    // read with forwarding
    assign readData1 = (write && (writeReg1 == readReg1)) ? writeData1 :
                (write && (writeReg2 == readReg1)) ? writeData2 :
                registers[readReg1];

    assign readData2 = (write && (writeReg1 == readReg2)) ? writeData1 :
                    (write && (writeReg2 == readReg2)) ? writeData2 :
                    registers[readReg2];

    assign readData3 = (write && (writeReg1 == readReg3)) ? writeData1 :
                    (write && (writeReg2 == readReg3)) ? writeData2 :
                    registers[readReg3];

    assign readData4 = (write && (writeReg1 == readReg4)) ? writeData1 :
                    (write && (writeReg2 == readReg4)) ? writeData2 :
                    registers[readReg4];
endmodule