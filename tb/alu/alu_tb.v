`timescale 1ns/1ps

module alu_tb;

  // Test signals
  reg signed [31:0] op1;
  reg signed [31:0] op2;
  reg [3:0] alu_op;
  wire signed [31:0] result;
  wire zero;
  wire ovf;

  // Test statistics
  integer passed = 0;
  integer failed = 0;
  integer total_tests = 0;

  // ALU operation codes
  localparam ALUOP_LSR  = 4'b0000;
  localparam ALUOP_LSL  = 4'b0001;
  localparam ALUOP_ASR  = 4'b0010;
  localparam ALUOP_ASL  = 4'b0011;
  localparam ALUOP_ADD  = 4'b0100;
  localparam ALUOP_SUB  = 4'b0101;
  localparam ALUOP_MUL  = 4'b0110;
  localparam ALUOP_AND  = 4'b1000;
  localparam ALUOP_OR   = 4'b1001;
  localparam ALUOP_NOR  = 4'b1010;
  localparam ALOP_NAND  = 4'b1011;
  localparam ALUOP_XOR  = 4'b1100;

  // Instantiate ALU
  alu uut (
    .op1(op1),
    .op2(op2),
    .alu_op(alu_op),
    .result(result),
    .zero(zero),
    .ovf(ovf)
  );

  // Task to check result
  task check_result;
    input signed [31:0] expected_result;
    input expected_zero;
    input expected_ovf;
    input [80*8:1] test_name;
    begin
      total_tests = total_tests + 1;
      #1;
      if (result === expected_result && zero === expected_zero && ovf === expected_ovf) begin
        $display("PASS: %0s", test_name);
        passed = passed + 1;
      end else begin
        $display("FAIL: %0s", test_name);
        $display("  Expected: result=%d, zero=%b, ovf=%b", expected_result, expected_zero, expected_ovf);
        $display("  Got:      result=%d, zero=%b, ovf=%b", result, zero, ovf);
        failed = failed + 1;
      end
    end
  endtask

  // Task for arithmetic ops
  task test_arithmetic_op;
    input [3:0] op;
    input signed [31:0] a, b;
    input signed [31:0] expected;
    input expected_ovf;
    input [80*8:1] name;
    begin
      op1 = a; op2 = b; alu_op = op;
      check_result(expected, (expected == 0), expected_ovf, name);
    end
  endtask

  // Task for logical ops
  task test_logical_op;
    input [3:0] op;
    input signed [31:0] a, b;
    input signed [31:0] expected;
    input [80*8:1] name;
    begin
      op1 = a; op2 = b; alu_op = op;
      check_result(expected, (expected == 0), 0, name);
    end
  endtask

  // Main test sequence
  initial begin

    $dumpfile("dump.vcd");
    $dumpvars(0, alu_tb);

    // ====================================================================
    $display("\n================================================================");
    $display("||                 Comprehensive ALU Testbench                ||");
    $display("================================================================\n");

    // ADD =========================================================
    $display("=== Testing Addition (ADD) ===");
    test_arithmetic_op(ALUOP_ADD, 15, 10, 25, 0, "ADD: 15 + 10 = 25");
    test_arithmetic_op(ALUOP_ADD, -5, 3, -2, 0, "ADD: -5 + 3 = -2");
    test_arithmetic_op(ALUOP_ADD, 100, -50, 50, 0, "ADD: 100 + (-50) = 50");
    test_arithmetic_op(ALUOP_ADD, 0, 0, 0, 0, "ADD: 0 + 0 = 0");
    test_arithmetic_op(ALUOP_ADD, -1, -1, -2, 0, "ADD: -1 + -1 = -2");
    test_arithmetic_op(ALUOP_ADD, 32'h7FFFFFFF, 1, 32'h80000000, 1, "ADD: overflow max+1");
    test_arithmetic_op(ALUOP_ADD, 32'h80000000, -1, 32'h7FFFFFFF, 1, "ADD: overflow min-1");
    test_arithmetic_op(ALUOP_ADD, 32'h7FFFFFFF, 32'h7FFFFFFF, 32'hFFFFFFFE, 1, "ADD: overflow max+max");

    // SUB =========================================================
    $display("\n=== Testing Subtraction (SUB) ===");
    test_arithmetic_op(ALUOP_SUB, 20, 5, 15, 0, "SUB: 20 - 5 = 15");
    test_arithmetic_op(ALUOP_SUB, 10, 10, 0, 0, "SUB: 10 - 10 = 0");
    test_arithmetic_op(ALUOP_SUB, 5, 10, -5, 0, "SUB: 5 - 10 = -5");
    test_arithmetic_op(ALUOP_SUB, -10, -5, -5, 0, "SUB: -10 - (-5) = -5");
    test_arithmetic_op(ALUOP_SUB, -10, 5, -15, 0, "SUB: -10 - 5 = -15");
    test_arithmetic_op(ALUOP_SUB, 32'h7FFFFFFF, -1, 32'h80000000, 1, "SUB: overflow max-(-1)");
    test_arithmetic_op(ALUOP_SUB, 32'h80000000, 1, 32'h7FFFFFFF, 1, "SUB: overflow min-1");
    test_arithmetic_op(ALUOP_SUB, 0, 32'h80000000, 32'h80000000, 1, "SUB: overflow 0-min");

    // MUL =========================================================
    $display("\n=== Testing Multiplication (MUL) ===");
    test_arithmetic_op(ALUOP_MUL, 5, 4, 20, 0, "MUL: 5 * 4 = 20");
    test_arithmetic_op(ALUOP_MUL, -5, 4, -20, 0, "MUL: -5 * 4 = -20");
    test_arithmetic_op(ALUOP_MUL, -5, -4, 20, 0, "MUL: -5 * -4 = 20");
    test_arithmetic_op(ALUOP_MUL, 0, 100, 0, 0, "MUL: 0 * 100 = 0");
    test_arithmetic_op(ALUOP_MUL, 1, 1, 1, 0, "MUL: 1 * 1 = 1");
    test_arithmetic_op(ALUOP_MUL, 100, 200, 20000, 0, "MUL: 100 * 200 = 20000");
    test_arithmetic_op(ALUOP_MUL, 32'h00010000, 32'h00010000, 0, 1, "MUL: overflow");
    test_arithmetic_op(ALUOP_MUL, 32'h7FFFFFFF, 2, -2, 1, "MUL: overflow large*2");

    // AND =========================================================
    $display("\n=== Testing Logical AND ===");
    test_logical_op(ALUOP_AND, 32'hFFFF, 32'h0F0F, 32'h0F0F, "AND basic");
    test_logical_op(ALUOP_AND, 32'hAAAA, 32'h5555, 32'h0000, "AND zero");
    test_logical_op(ALUOP_AND, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF, "AND all ones");
    test_logical_op(ALUOP_AND, 32'h00000000, 32'hFFFFFFFF, 32'h00000000, "AND with zero");
    test_logical_op(ALUOP_AND, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'h00000000, "AND alt bits");

    // OR =========================================================
    $display("\n=== Testing Logical OR ===");
    test_logical_op(ALUOP_OR, 32'hFF00, 32'h00FF, 32'hFFFF, "OR combine");
    test_logical_op(ALUOP_OR, 32'hAAAA, 32'h5555, 32'hFFFF, "OR full");
    test_logical_op(ALUOP_OR, 32'h0000, 32'h0000, 32'h0000, "OR zero");
    test_logical_op(ALUOP_OR, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'hFFFFFFFF, "OR alt");

    // NOR =========================================================
	$display("\n=== Testing Logical NOR ===");
	test_logical_op(ALUOP_NOR, 32'h00000000, 32'h00000000, 32'hFFFFFFFF, "NOR zero");
	test_logical_op(ALUOP_NOR, 32'h0000FFFF, 32'h00000000, 32'hFFFF0000, "NOR half");
	test_logical_op(ALUOP_NOR, 32'hAAAAAAAA, 32'h55555555, 32'h00000000, "NOR alt");
	test_logical_op(ALUOP_NOR, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h00000000, "NOR ones");

    // NAND ========================================================
	$display("\n=== Testing Logical NAND ===");
	test_logical_op(ALOP_NAND, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h00000000, "NAND full");
	test_logical_op(ALOP_NAND, 32'h00000000, 32'h0000FFFF, 32'hFFFFFFFF, "NAND zero");
	test_logical_op(ALOP_NAND, 32'hAAAAAAAA, 32'h55555555, 32'hFFFFFFFF, "NAND alt");
	test_logical_op(ALOP_NAND, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h00000000, "NAND ones");

    // XOR =========================================================
    $display("\n=== Testing Logical XOR ===");
    test_logical_op(ALUOP_XOR, 32'hAAAA, 32'h5555, 32'hFFFF, "XOR basic");
    test_logical_op(ALUOP_XOR, 32'hFFFF, 32'hFFFF, 32'h0000, "XOR same");
    test_logical_op(ALUOP_XOR, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'hFFFFFFFF, "XOR alt");
    test_logical_op(ALUOP_XOR, 32'h12345678, 32'h00000000, 32'h12345678, "XOR zero");

    // LSR =========================================================
    $display("\n=== Testing Logical Right Shift (LSR) ===");
    test_logical_op(ALUOP_LSR, 32'hF0F0F0F0, 4, 32'h0F0F0F0F, "LSR 4");
    test_logical_op(ALUOP_LSR, 32'h80000000, 1, 32'h40000000, "LSR MSB");
    test_logical_op(ALUOP_LSR, 32'hFFFFFFFF, 16, 32'h0000FFFF, "LSR 16");
    test_logical_op(ALUOP_LSR, 32'h00000001, 1, 32'h00000000, "LSR to zero");
    test_logical_op(ALUOP_LSR, 32'h12345678, 0, 32'h12345678, "LSR 0");

    // LSL =========================================================
    $display("\n=== Testing Logical Left Shift (LSL) ===");
    test_logical_op(ALUOP_LSL, 32'h0F0F0F0F, 4, 32'hF0F0F0F0, "LSL 4");
    test_logical_op(ALUOP_LSL, 32'h00000001, 1, 32'h00000002, "LSL 1");
    test_logical_op(ALUOP_LSL, 32'h0000FFFF, 16, 32'hFFFF0000, "LSL 16");
    test_logical_op(ALUOP_LSL, 32'h12345678, 0, 32'h12345678, "LSL 0");

    // ASR =========================================================
    $display("\n=== Testing Arithmetic Right Shift (ASR) ===");
    test_logical_op(ALUOP_ASR, -16, 2, -4, "ASR: -16 >> 2");
    test_logical_op(ALUOP_ASR, -8, 1, -4, "ASR: -8 >> 1");
    test_logical_op(ALUOP_ASR, 32'h80000000, 1, 32'hC0000000, "ASR MSB");
    test_logical_op(ALUOP_ASR, 16, 2, 4, "ASR: 16 >> 2");
    test_logical_op(ALUOP_ASR, -1, 16, -1, "ASR: -1 >> 16");

    // ASL =========================================================
    $display("\n=== Testing Arithmetic Left Shift (ASL) ===");
    test_logical_op(ALUOP_ASL, 4, 2, 16, "ASL 4<<2");
    test_logical_op(ALUOP_ASL, -4, 2, -16, "ASL -4<<2");
    test_logical_op(ALUOP_ASL, 1, 8, 256, "ASL 1<<8");
    test_logical_op(ALUOP_ASL, 32'h12345678, 0, 32'h12345678, "ASL 0");

    // Edge Cases ==================================================
    $display("\n=== Testing Edge Cases ===");
    test_arithmetic_op(ALUOP_ADD, 32'h7FFFFFFF, 0, 32'h7FFFFFFF, 0, "Edge: max+0");
    test_arithmetic_op(ALUOP_ADD, 32'h80000000, 0, 32'h80000000, 0, "Edge: min+0");
    test_arithmetic_op(ALUOP_SUB, 32'h7FFFFFFF, 32'h7FFFFFFF, 0, 0, "Edge: max-max");
    test_arithmetic_op(ALUOP_MUL, 1, 32'h7FFFFFFF, 32'h7FFFFFFF, 0, "Edge: 1*max");
    test_logical_op(ALUOP_LSR, 32'hFFFFFFFF, 32, 32'h00000000, "Edge: LSR 32");
    test_logical_op(ALUOP_LSL, 32'hFFFFFFFF, 32, 32'h00000000, "Edge: LSL 32");

    // SUMMARY =====================================================
    $display("\n================================================================");
    $display("||                         Test Summary                       ||");
    $display("================================================================");
    $display("||  Total Tests:  %3d                                         ||", total_tests);
    $display("||  Passed:       %3d                                         ||", passed);
    $display("||  Failed:       %3d                                         ||", failed);
    $display("================================================================");

    if (failed == 0)
      $display("||  Result: ALL TESTS PASSED                                  ||");
    else
      $display("||  Result: SOME TESTS FAILED                                 ||");

    $display("================================================================\n");

    if (failed != 0)
      $fatal(1, "Testbench failed with %0d errors", failed);

    $finish;
  end

endmodule
