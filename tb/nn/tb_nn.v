`timescale 1ns/1ps
module tb_nn;

    // Testbench signals
    reg [31:0] input_1, input_2;
    reg clk;
    reg resetn;
    reg enable;
    wire [31:0] final_output;
    wire total_ovf;
    wire total_zero;
    wire [2:0] ovf_fsm_stage;
    wire [2:0] zero_fsm_stage;

    // Reference model output
    reg [31:0] ref_output;

    // Test counters
    integer pass_count;
    integer total_tests;
    integer i;

    // Max/min values for 32-bit signed numbers
    localparam signed [31:0] MAX_POSITIVE = 32'h7FFFFFFF;  // 2147483647
    localparam signed [31:0] MAX_NEGATIVE = 32'h80000000;  // -2147483648

    // Include the reference model function
    `include "src/nn/nn_model.vh"

    // Instantiate the neural network module
    nn uut (
        .input_1(input_1),
        .input_2(input_2),
        .clk(clk),
        .resetn(resetn),
        .enable(enable),
        .final_output(final_output),
        .total_ovf(total_ovf),
        .total_zero(total_zero),
        .ovf_fsm_stage(ovf_fsm_stage),
        .zero_fsm_stage(zero_fsm_stage)
    );

    // Clock generation: 10ns period, 50% duty cycle
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Task to run a single test case
    task run_test;
        input [31:0] in1;
        input [31:0] in2;
        input integer is_first_test;  // Flag to indicate if weights need loading
        begin
            input_1 = in1;
            input_2 = in2;

            // Get reference model output
            ref_output = nn_model(in1, in2);

            @(posedge clk);
            enable = 1;
            @(posedge clk);
            enable = 0;

            // Wait for computation
            // First test needs weight loading (6 cycles) + computation (5 cycles) = 11 cycles
            // Subsequent tests only need computation (5 cycles): PREPROCESS -> INPUT_LAYER -> OUTPUT_LAYER -> POSTPROCESS -> IDLE
            if (is_first_test)
                repeat(11) @(posedge clk);
            else
                repeat(5) @(posedge clk);

            // Compare results
            total_tests = total_tests + 1;
            if (final_output === ref_output) begin
                pass_count = pass_count + 1;
                $display("PASS: input_1=%0d, input_2=%0d, output=%h",
                         $signed(input_1), $signed(input_2), final_output);
            end else begin
                $display("MISMATCH at time %0t: input_1=%0d, input_2=%0d, DUT output=%h, REF output=%h",
                         $time, $signed(input_1), $signed(input_2), final_output, ref_output);
            end
        end
    endtask

    // Main test sequence
    initial begin
        // Waveform dump
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_nn);

        // Initialize signals
        input_1 = 0;
        input_2 = 0;
        resetn = 0;
        enable = 0;
        pass_count = 0;
        total_tests = 0;

        // Apply reset
        #20;
        resetn = 1;
        @(posedge clk);

        $display("========================================");
        $display("Starting Neural Network Testbench");
        $display("100 iterations x 3 test cases = 300 total tests");
        $display("========================================");

        // Run 100 iterations
        for (i = 0; i < 100; i = i + 1) begin
            $display("\n----- Iteration %0d -----", i);

            // Test 1: Random inputs in range [-4096, 4095]
            $display("Test 1: Small range [-4096, 4095]");
            run_test(
                $signed($urandom_range(0, 8191)) - 4096,  // Range: [-4096, 4095]
                $signed($urandom_range(0, 8191)) - 4096,  // Range: [-4096, 4095]
                (i == 0) ? 1 : 0  // First test of first iteration needs weight loading
            );

            // Test 2: Positive overflow test [max_positive/2, max_positive]
            $display("Test 2: Positive overflow range [%0d, %0d]", MAX_POSITIVE/2, MAX_POSITIVE);
            run_test(
                $urandom_range(MAX_POSITIVE/2, MAX_POSITIVE),
                $urandom_range(MAX_POSITIVE/2, MAX_POSITIVE),
                0
            );

            // Test 3: Negative overflow test [max_negative, max_negative/2]
            $display("Test 3: Negative overflow range [%0d, %0d]", $signed(MAX_NEGATIVE), $signed(MAX_NEGATIVE/2));
            run_test(
                $urandom_range(0, MAX_POSITIVE/2) | MAX_NEGATIVE,  // Creates values in [max_negative, max_negative/2]
                $urandom_range(0, MAX_POSITIVE/2) | MAX_NEGATIVE,  // Creates values in [max_negative, max_negative/2]
                0
            );
        end

        // Print final results
        $display("\n========================================");
        $display("Testbench completed!");
        $display("PASS: %0d / %0d test cases", pass_count, total_tests);
        $display("========================================");

        $finish;
    end

endmodule