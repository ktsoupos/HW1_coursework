module nn(
    input [31:0] input_1,
    input [31:0] input_2,
    input clk,
    input resetn,
    input enable,
    output reg [31:0] final_output,
    output reg total_ovf,
    output reg total_zero,
    output reg [2:0] ovf_fsm_stage,
    output reg [2:0] zero_fsm_stage
);


// FSM State Encoding (3 bits for 7 states)
localparam [2:0] DEACTIVATED            = 3'b000;  // System off, waiting for enable
localparam [2:0] LOAD_WEIGHTS_BIASES    = 3'b001;  // Load ROM → Register File
localparam [2:0] PREPROCESS             = 3'b010;  // Right shift inputs
localparam [2:0] INPUT_LAYER            = 3'b011;  // Neurons 1 & 2 (parallel MACs)
localparam [2:0] OUTPUT_LAYER           = 3'b100;  // Neuron 3 computation
localparam [2:0] POSTPROCESS            = 3'b101;  // Left shift output
localparam [2:0] IDLE                   = 3'b110;  // Wait for next inputs

// ALU Operation Codes
localparam [3:0] ALUOP_ASR = 4'b0010;  // Arithmetic right shift
localparam [3:0] ALUOP_ASL = 4'b0011;  // Arithmetic left shift
localparam [3:0] ALUOP_ADD = 4'b0100;  // Addition
localparam [3:0] ALUOP_MUL = 4'b0110;  // Multiplication

// Register File Address Map
localparam [3:0] ADDR_ZERO         = 4'd0;   // Reserved (zero)
localparam [3:0] ADDR_SHIFT_BIAS_1 = 4'd2;   // shift_bias_1
localparam [3:0] ADDR_SHIFT_BIAS_2 = 4'd3;   // shift_bias_2
localparam [3:0] ADDR_WEIGHT_1     = 4'd4;   // weight_1
localparam [3:0] ADDR_BIAS_1       = 4'd5;   // bias_1
localparam [3:0] ADDR_WEIGHT_2     = 4'd6;   // weight_2
localparam [3:0] ADDR_BIAS_2       = 4'd7;   // bias_2
localparam [3:0] ADDR_WEIGHT_3     = 4'd8;   // weight_3
localparam [3:0] ADDR_WEIGHT_4     = 4'd9;   // weight_4
localparam [3:0] ADDR_BIAS_3       = 4'd10;  // bias_3
localparam [3:0] ADDR_SHIFT_BIAS_3 = 4'd11;  // shift_bias_3

// ROM Byte Address Map
localparam [7:0] ROM_SHIFT_BIAS_1 = 8'd8;
localparam [7:0] ROM_SHIFT_BIAS_2 = 8'd12;
localparam [7:0] ROM_WEIGHT_1     = 8'd16;
localparam [7:0] ROM_BIAS_1       = 8'd20;
localparam [7:0] ROM_WEIGHT_2     = 8'd24;
localparam [7:0] ROM_BIAS_2       = 8'd28;
localparam [7:0] ROM_WEIGHT_3     = 8'd32;
localparam [7:0] ROM_WEIGHT_4     = 8'd36;
localparam [7:0] ROM_BIAS_3       = 8'd40;
localparam [7:0] ROM_SHIFT_BIAS_3 = 8'd44;

// State Registers
reg [2:0] current_state, next_state;

// Internal Registers
reg signed [31:0] inter_1, inter_2;    // After preprocessing
reg signed [31:0] inter_3, inter_4;    // After input layer
reg signed [31:0] inter_5;             // After output layer
reg        weights_loaded;
reg [2:0]  load_counter;

// Latched inputs (capture when computation starts)
reg signed [31:0] latched_input_1, latched_input_2;

// ROM Signals
reg  [7:0]  rom_addr1, rom_addr2;
wire [31:0] rom_dout1, rom_dout2;

// Register File Signals
reg  [3:0]  rf_readReg1, rf_readReg2, rf_readReg3, rf_readReg4;
reg  [3:0]  rf_writeReg1, rf_writeReg2;
reg  [31:0] rf_writeData1, rf_writeData2;
reg     rf_write;
wire [31:0] rf_readData1, rf_readData2, rf_readData3, rf_readData4;

// ALU Signals(shift operations)
reg  signed [31:0] alu1_op1, alu1_op2;
reg  signed [31:0] alu2_op1, alu2_op2;
reg  [3:0]         alu1_opcode, alu2_opcode;
wire signed [31:0] alu1_result, alu2_result;
wire               alu1_zero, alu2_zero;
wire               alu1_ovf, alu2_ovf;

// MAC Signals
reg  signed [31:0] mac1_op1, mac1_op2, mac1_op3;
reg  signed [31:0] mac2_op1, mac2_op2, mac2_op3;
wire signed [31:0] mac1_result, mac2_result;
wire               mac1_zero_mul, mac1_zero_add;
wire               mac2_zero_mul, mac2_zero_add;
wire               mac1_ovf_mul, mac1_ovf_add;
wire               mac2_ovf_mul, mac2_ovf_add;

// Overflow Detection (combined for current operation)
wire any_mac_ovf = mac1_ovf_mul | mac1_ovf_add | mac2_ovf_mul | mac2_ovf_add;
wire any_alu_ovf = alu1_ovf | alu2_ovf;
wire any_zero    = mac1_zero_add | mac2_zero_add | alu1_zero | alu2_zero;

// Module Instantiations
WEIGHT_BIAS_MEMORY #(.DATAWIDTH(32)) rom_inst (
    .clk(clk),
    .addr1(rom_addr1),
    .addr2(rom_addr2),
    .dout1(rom_dout1),
    .dout2(rom_dout2)
);

regfile rf_inst (
    .clk(clk),
    .resetn(resetn),
    .readReg1(rf_readReg1),
    .readReg2(rf_readReg2),
    .readReg3(rf_readReg3),
    .readReg4(rf_readReg4),
    .writeReg1(rf_writeReg1),
    .writeReg2(rf_writeReg2),
    .writeData1(rf_writeData1),
    .writeData2(rf_writeData2),
    .write(rf_write),
    .readData1(rf_readData1),
    .readData2(rf_readData2),
    .readData3(rf_readData3),
    .readData4(rf_readData4)
);

alu alu_shift_1(
    .op1(alu1_op1),
    .op2(alu1_op2),
    .alu_op(alu1_opcode),
    .result(alu1_result),
    .zero(alu1_zero),
    .ovf(alu1_ovf)
);

alu alu_shift_2(
    .op1(alu2_op1),
    .op2(alu2_op2),
    .alu_op(alu2_opcode),
    .result(alu2_result),
    .zero(alu2_zero),
    .ovf(alu2_ovf)
);

mac mac_unit_1(
    .op1(mac1_op1),
    .op2(mac1_op2),
    .op3(mac1_op3),
    .total_result(mac1_result),
    .zero_mul(mac1_zero_mul),
    .zero_add(mac1_zero_add),
    .ovf_mul(mac1_ovf_mul),
    .ovf_add(mac1_ovf_add)
);

mac mac_unit_2(
    .op1(mac2_op1),
    .op2(mac2_op2),
    .op3(mac2_op3),
    .total_result(mac2_result),
    .zero_mul(mac2_zero_mul),
    .zero_add(mac2_zero_add),
    .ovf_mul(mac2_ovf_mul),
    .ovf_add(mac2_ovf_add)
);


// State Register
always @(posedge clk or negedge resetn) begin
    if (!resetn)
        current_state <= DEACTIVATED;
    else
        current_state <= next_state;
end

// Next State Logic
always @(*) begin
    // Default to current state
    next_state = current_state;

    case(current_state)
        DEACTIVATED:begin
            if(enable)
                next_state = LOAD_WEIGHTS_BIASES;
        end
        LOAD_WEIGHTS_BIASES: begin
            // 10 values /2 inputs + 1 cycle latency = 6 cycles to load all
            if (load_counter == 3'd5)
                next_state = PREPROCESS;
        end
        PREPROCESS: begin
            next_state = INPUT_LAYER;
        end
        INPUT_LAYER: begin
            next_state = OUTPUT_LAYER;
        end
        OUTPUT_LAYER: begin
            next_state = POSTPROCESS;
        end
        POSTPROCESS: begin
            next_state = IDLE;
        end
        IDLE: begin
            if (enable)
                next_state = PREPROCESS;
        end
        default: begin
            next_state = DEACTIVATED;  
        end
    endcase
end

// FSM Sequential Logic and Data Path Control
always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
        // Datapath
        weights_loaded   <= 1'b0;
        load_counter     <= 3'd0;
        inter_1          <= 32'd0;
        inter_2          <= 32'd0;
        inter_3          <= 32'd0;
        inter_4          <= 32'd0;
        inter_5          <= 32'd0;
        latched_input_1  <= 32'd0;
        latched_input_2  <= 32'd0;
        
        // Outputs
        final_output     <= 32'd0;
        total_ovf        <= 1'b0;
        total_zero       <= 1'b0;
        ovf_fsm_stage    <= 3'b111;
        zero_fsm_stage   <= 3'b111;
    end
    else begin
        case(current_state)
            DEACTIVATED: begin
                // Reset outputs on enable
                if (enable) begin
                        // Latch inputs
                        latched_input_1 <= input_1;
                        latched_input_2 <= input_2;
                        load_counter    <= 3'd0;
                        
                        // Clear flags
                        total_ovf       <= 1'b0;
                        total_zero      <= 1'b0;
                        ovf_fsm_stage   <= 3'b111;
                        zero_fsm_stage  <= 3'b111;
                    end
                end
            LOAD_WEIGHTS_BIASES: begin
            if(load_counter < 3'd5) begin
                    load_counter <= load_counter + 3'd1;
            end
            else begin
                    weights_loaded <= 1'b1;
            end
            end
            PREPROCESS: begin
                inter_1 <= alu1_result;  
                inter_2 <= alu2_result;
                // Check overflow
                if (alu1_ovf || alu2_ovf) begin
                    total_ovf     <= 1'b1;
                    ovf_fsm_stage <= PREPROCESS;
                    final_output  <= 32'hFFFFFFFF;
                end
                
                // Check zero
                if ((alu1_zero || alu2_zero) && !total_zero) begin
                    total_zero     <= 1'b1;
                    zero_fsm_stage <= PREPROCESS;
                end
            end
            INPUT_LAYER: begin
                inter_3 <= mac1_result;
                inter_4 <= mac2_result;
                // Check overflow
                if (any_mac_ovf) begin
                    total_ovf     <= 1'b1;
                    ovf_fsm_stage <= INPUT_LAYER;
                    final_output  <= 32'hFFFFFFFF;
                end
                
                // Check zero
                if ((mac1_zero_add || mac2_zero_add) && !total_zero) begin
                    total_zero     <= 1'b1;
                    zero_fsm_stage <= INPUT_LAYER;
                end
            end
            OUTPUT_LAYER: begin
                inter_5 <=  mac2_result; // mac_1 
                // Check overflow
                if ((mac1_ovf_mul || mac1_ovf_add || mac2_ovf_mul || mac2_ovf_add) && !total_ovf) begin
                    total_ovf     <= 1'b1;
                    ovf_fsm_stage <= OUTPUT_LAYER;
                    final_output  <= 32'hFFFFFFFF;
                end
                
                // Check zero
                if (mac2_zero_add && !total_zero) begin
                    total_zero     <= 1'b1;
                    zero_fsm_stage <= OUTPUT_LAYER;
                end
            end
            POSTPROCESS: begin
                
            // Check overflow
            if (alu1_ovf && !total_ovf) begin
                total_ovf     <= 1'b1;
                ovf_fsm_stage <= POSTPROCESS;
                final_output  <= 32'hFFFFFFFF;
            end
            else if (!total_ovf) begin
                final_output <= alu1_result;
            end
            
            // Check zero
            if (alu1_zero && !total_zero) begin
                total_zero     <= 1'b1;
                zero_fsm_stage <= POSTPROCESS;
            end
            end
            IDLE: begin
                if (enable) begin
                    // Latch new inputs
                    latched_input_1 <= input_1;
                    latched_input_2 <= input_2;
                    
                    // Clear flags
                    total_ovf       <= 1'b0;
                    total_zero      <= 1'b0;
                    ovf_fsm_stage   <= 3'b111;
                    zero_fsm_stage  <= 3'b111;
                end
            end
        
            default: ; // Hold values
        endcase
    end
end

// Control Signals Combinational Logic
always @(*) begin
    // Default values
    rom_addr1     = 8'd0;
    rom_addr2     = 8'd0;
    
    rf_readReg1   = 4'd0;
    rf_readReg2   = 4'd0;
    rf_readReg3   = 4'd0;
    rf_readReg4   = 4'd0;
    rf_writeReg1  = 4'd0;
    rf_writeReg2  = 4'd0;
    rf_writeData1 = 32'd0;
    rf_writeData2 = 32'd0;
    rf_write      = 1'b0;
    
    alu1_op1      = 32'd0;
    alu1_op2      = 32'd0;
    alu1_opcode   = ALUOP_ASR;
    alu2_op1      = 32'd0;
    alu2_op2      = 32'd0;
    alu2_opcode   = ALUOP_ASR;
    
    mac1_op1      = 32'd0;
    mac1_op2      = 32'd0;
    mac1_op3      = 32'd0;
    mac2_op1      = 32'd0;
    mac2_op2      = 32'd0;
    mac2_op3      = 32'd0;

    case(current_state)
        DEACTIVATED: begin
            if(enable) begin
                rom_addr1 = ROM_SHIFT_BIAS_1;  // 8
                rom_addr2 = ROM_SHIFT_BIAS_2;  // 12
            end
        end

        LOAD_WEIGHTS_BIASES: begin
            // ROM addresses for NEXT cycle's data
            case(load_counter)
                3'd0: begin
                    rom_addr1 = ROM_WEIGHT_1;      // 16
                    rom_addr2 = ROM_BIAS_1;        // 20
                end
                3'd1: begin
                    rom_addr1 = ROM_WEIGHT_2;      // 24
                    rom_addr2 = ROM_BIAS_2;        // 28
                end
                3'd2: begin
                    rom_addr1 = ROM_WEIGHT_3;      // 32
                    rom_addr2 = ROM_WEIGHT_4;      // 36
                end
                3'd3: begin
                    rom_addr1 = ROM_BIAS_3;        // 40
                    rom_addr2 = ROM_SHIFT_BIAS_3;  // 44
                end
                default: ;
            endcase

            // RF writes from PREVIOUS cycle's ROM data
            rf_writeData1 = rom_dout1;
            rf_writeData2 = rom_dout2;
            rf_write = 1'b1;

            case(load_counter)
                3'd0: begin                              // ← Start at 0!
                    rf_writeReg1 = ADDR_SHIFT_BIAS_1;    // 2
                    rf_writeReg2 = ADDR_SHIFT_BIAS_2;    // 3
                end
                3'd1: begin
                    rf_writeReg1 = ADDR_WEIGHT_1;        // 4
                    rf_writeReg2 = ADDR_BIAS_1;          // 5
                end
                3'd2: begin
                    rf_writeReg1 = ADDR_WEIGHT_2;        // 6
                    rf_writeReg2 = ADDR_BIAS_2;          // 7
                end
                3'd3: begin
                    rf_writeReg1 = ADDR_WEIGHT_3;        // 8
                    rf_writeReg2 = ADDR_WEIGHT_4;        // 9
                end
                3'd4: begin
                    rf_writeReg1 = ADDR_BIAS_3;          // 10
                    rf_writeReg2 = ADDR_SHIFT_BIAS_3;    // 11
                end
                default: rf_write = 1'b0;
            endcase
        end

        PREPROCESS:begin
            // ALU1: input_1 >> shift_bias_1
            alu1_op1    = latched_input_1;
            rf_readReg1 = ADDR_SHIFT_BIAS_1;
            alu1_op2    = rf_readData1;
            alu1_opcode = ALUOP_ASR;

            // ALU2: input_2 >> shift_bias_2
            alu2_op1    = latched_input_2;
            rf_readReg2 = ADDR_SHIFT_BIAS_2;
            alu2_op2    = rf_readData2;
            alu2_opcode = ALUOP_ASR;
        end

        INPUT_LAYER: begin
            // MAC1: (inter_1 * weight_1) + bias_1
            mac1_op1    = inter_1;
            rf_readReg1 = ADDR_WEIGHT_1;
            mac1_op2    = rf_readData1;
            rf_readReg2 = ADDR_BIAS_1;
            mac1_op3    = rf_readData2;

            // MAC2: (inter_2 * weight_2) + bias_2
            mac2_op1    = inter_2;
            rf_readReg3 = ADDR_WEIGHT_2;
            mac2_op2    = rf_readData3;
            rf_readReg4 = ADDR_BIAS_2;
            mac2_op3    = rf_readData4;
        end

        OUTPUT_LAYER: begin
            // MAC: (inter_3 * weight_3) + bias_3
            mac1_op1    = inter_3;
            rf_readReg1 = ADDR_WEIGHT_3;
            mac1_op2    = rf_readData1;
            rf_readReg2 = ADDR_BIAS_3;
            mac1_op3    = rf_readData2;

            // MAC: (inter_4 * weight_4) + mac1_result
            mac2_op1    = inter_4;
            rf_readReg3 = ADDR_WEIGHT_4;
            mac2_op2    = rf_readData3;
            mac2_op3    = mac1_result;
        end

        POSTPROCESS: begin
            // ALU1: inter_5 << shift_bias_3
            alu1_op1    = inter_5;
            rf_readReg1 = ADDR_SHIFT_BIAS_3;
            alu1_op2    = rf_readData1;
            alu1_opcode = ALUOP_ASL;
        end
        IDLE: begin
            if (enable) begin
                // Prepare for new inputs
                rom_addr1 = 8'd8; 
                rom_addr2 = 8'd12;
            end
        end
        default: ; // Hold values
    endcase
end

endmodule