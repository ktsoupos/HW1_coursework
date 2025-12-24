`timescale 1ns/1ps

module regfile_tb;

  // Test signals
  reg clk;
  reg resetn;
  reg [3:0] readReg1, readReg2, readReg3, readReg4;
  reg [3:0] writeReg1, writeReg2;
  reg [31:0] writeData1, writeData2;
  reg write;
  wire [31:0] readData1, readData2, readData3, readData4;

  // Test statistics
  integer passed = 0;
  integer failed = 0;
  integer total_tests = 0;

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 10ns period (100MHz)
  end

  // Instantiate register file
  regfile #(
    .DATAWIDTH(32)
  ) uut (
    .clk(clk),
    .resetn(resetn),
    .readReg1(readReg1),
    .readReg2(readReg2),
    .readReg3(readReg3),
    .readReg4(readReg4),
    .writeReg1(writeReg1),
    .writeReg2(writeReg2),
    .writeData1(writeData1),
    .writeData2(writeData2),
    .write(write),
    .readData1(readData1),
    .readData2(readData2),
    .readData3(readData3),
    .readData4(readData4)
  );

  // Task to check read result
  task check_read;
    input [3:0] reg_addr;
    input [31:0] expected_data;
    input [80*8:1] test_name;
    reg [31:0] actual_data;
    begin
      total_tests = total_tests + 1;
      readReg1 = reg_addr;
      #1;  // Small delay for combinational logic
      actual_data = readData1;

      if (actual_data === expected_data) begin
        $display("PASS: %0s", test_name);
        passed = passed + 1;
      end else begin
        $display("FAIL: %0s", test_name);
        $display("  Expected: reg[%0d] = 0x%08h", reg_addr, expected_data);
        $display("  Got:      reg[%0d] = 0x%08h", reg_addr, actual_data);
        failed = failed + 1;
      end
    end
  endtask

  // Task to check multiple reads simultaneously
  task check_multi_read;
    input [3:0] addr1, addr2, addr3, addr4;
    input [31:0] exp1, exp2, exp3, exp4;
    input [80*8:1] test_name;
    begin
      total_tests = total_tests + 1;
      readReg1 = addr1;
      readReg2 = addr2;
      readReg3 = addr3;
      readReg4 = addr4;
      #1;

      if (readData1 === exp1 && readData2 === exp2 &&
          readData3 === exp3 && readData4 === exp4) begin
        $display("PASS: %0s", test_name);
        passed = passed + 1;
      end else begin
        $display("FAIL: %0s", test_name);
        $display("  Port1: Expected=0x%08h, Got=0x%08h", exp1, readData1);
        $display("  Port2: Expected=0x%08h, Got=0x%08h", exp2, readData2);
        $display("  Port3: Expected=0x%08h, Got=0x%08h", exp3, readData3);
        $display("  Port4: Expected=0x%08h, Got=0x%08h", exp4, readData4);
        failed = failed + 1;
      end
    end
  endtask

  // Task to write to register file (single port)
  task write_reg;
    input [3:0] addr;
    input [31:0] data;
    begin
      write = 1;
      writeReg1 = addr;
      writeData1 = data;
      writeReg2 = addr;        // Point to same register
      writeData2 = data;       // Same data (so we write same value twice - no harm)
      @(posedge clk);
      #1;  // Small delay after clock edge
      write = 0;
    end
  endtask

  // Task to write two registers simultaneously
  task write_dual_reg;
    input [3:0] addr1, addr2;
    input [31:0] data1, data2;
    begin
      write = 1;
      writeReg1 = addr1;
      writeData1 = data1;
      writeReg2 = addr2;
      writeData2 = data2;
      @(posedge clk);
      #1;  // Small delay after clock edge
      write = 0;
    end
  endtask

  // Task to test write-read forwarding
  task check_forwarding;
    input [3:0] write_addr;
    input [31:0] write_data;
    input [80*8:1] test_name;
    begin
      total_tests = total_tests + 1;
      @(posedge clk);
      write = 1;
      writeReg1 = write_addr;
      writeData1 = write_data;
      readReg1 = write_addr;  // Read same address while writing
      #1;  // Wait for combinational logic

      if (readData1 === write_data) begin
        $display("PASS: %0s", test_name);
        passed = passed + 1;
      end else begin
        $display("FAIL: %0s", test_name);
        $display("  Expected forwarded data: 0x%08h", write_data);
        $display("  Got:                     0x%08h", readData1);
        failed = failed + 1;
      end

      @(posedge clk);
      write = 0;
    end
  endtask

  // Main test sequence
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, regfile_tb);

    // Initialize signals
    resetn = 1;
    write = 0;
    readReg1 = 0;
    readReg2 = 0;
    readReg3 = 0;
    readReg4 = 0;
    writeReg1 = 0;
    writeReg2 = 0;
    writeData1 = 0;
    writeData2 = 0;

    $display("\n================================================================");
    $display("||           Register File Testbench - 16x32 bits            ||");
    $display("================================================================\n");

    // ====================================================================
    // Test 1: Reset functionality
    // ====================================================================
    $display("=== Test 1: Reset Functionality ===");
    resetn = 0;  // Assert reset (active low)
    @(posedge clk);
    @(posedge clk);
    resetn = 1;  // Deassert reset
    @(posedge clk);

    // Check all registers are zero after reset
    check_read(0, 32'h00000000, "Reset: Register 0");
    check_read(5, 32'h00000000, "Reset: Register 5");
    check_read(10, 32'h00000000, "Reset: Register 10");
    check_read(15, 32'h00000000, "Reset: Register 15");

    // ====================================================================
    // Test 2: Single port write and read
    // ====================================================================
    $display("\n=== Test 2: Single Port Write/Read ===");
    write_reg(0, 32'hDEADBEEF);
    check_read(0, 32'hDEADBEEF, "Write/Read: reg[0] = 0xDEADBEEF");

    write_reg(1, 32'h12345678);
    check_read(1, 32'h12345678, "Write/Read: reg[1] = 0x12345678");

    write_reg(15, 32'hFFFFFFFF);
    check_read(15, 32'hFFFFFFFF, "Write/Read: reg[15] = 0xFFFFFFFF");

    write_reg(7, 32'hAAAABBBB);
    check_read(7, 32'hAAAABBBB, "Write/Read: reg[7] = 0xAAAABBBB");

    // ====================================================================
    // Test 3: Dual port writes
    // ====================================================================
    $display("\n=== Test 3: Dual Port Writes ===");
    write_dual_reg(2, 3, 32'h11111111, 32'h22222222);
    check_read(2, 32'h11111111, "Dual Write: reg[2] = 0x11111111");
    check_read(3, 32'h22222222, "Dual Write: reg[3] = 0x22222222");

    write_dual_reg(8, 9, 32'hABCDEF00, 32'h98765432);
    check_read(8, 32'hABCDEF00, "Dual Write: reg[8] = 0xABCDEF00");
    check_read(9, 32'h98765432, "Dual Write: reg[9] = 0x98765432");

    // ====================================================================
    // Test 4: Multiple read ports simultaneously
    // ====================================================================
    $display("\n=== Test 4: Multi-Port Read ===");
    check_multi_read(0, 1, 2, 3,
                     32'hDEADBEEF, 32'h12345678, 32'h11111111, 32'h22222222,
                     "Multi-read: reg[0-3] simultaneously");

    check_multi_read(7, 8, 9, 15,
                     32'hAAAABBBB, 32'hABCDEF00, 32'h98765432, 32'hFFFFFFFF,
                     "Multi-read: reg[7,8,9,15] simultaneously");

    // ====================================================================
    // Test 5: Write-Read forwarding (same address)
    // ====================================================================
    $display("\n=== Test 5: Write-Read Forwarding ===");
    check_forwarding(4, 32'hCAFEBABE, "Forwarding: writeReg1==readReg1");

    // Test forwarding from writeReg2 to readReg1
    total_tests = total_tests + 1;
    @(posedge clk);
    write = 1;
    writeReg1 = 5;
    writeData1 = 32'h11110000;
    writeReg2 = 6;
    writeData2 = 32'h22220000;
    readReg1 = 6;  // Should forward writeData2
    #1;
    if (readData1 === 32'h22220000) begin
      $display("PASS: Forwarding: writeReg2==readReg1");
      passed = passed + 1;
    end else begin
      $display("FAIL: Forwarding: writeReg2==readReg1");
      $display("  Expected: 0x22220000, Got: 0x%08h", readData1);
      failed = failed + 1;
    end
    @(posedge clk);
    write = 0;

    // ====================================================================
    // Test 6: Overwrite registers
    // ====================================================================
    $display("\n=== Test 6: Overwriting Registers ===");
    write_reg(0, 32'h00000000);
    check_read(0, 32'h00000000, "Overwrite: reg[0] = 0x00000000");

    write_reg(1, 32'hFFFFFFFF);
    check_read(1, 32'hFFFFFFFF, "Overwrite: reg[1] = 0xFFFFFFFF");

    write_reg(1, 32'h55555555);
    check_read(1, 32'h55555555, "Overwrite: reg[1] = 0x55555555");

    // ====================================================================
    // Test 7: Write to same register from both ports
    // ====================================================================
    $display("\n=== Test 7: Dual Write to Same Register ===");
    total_tests = total_tests + 1;
    write_dual_reg(10, 10, 32'hAAAAAAAA, 32'hBBBBBBBB);
    check_read(10, 32'hBBBBBBBB, "Dual write same addr: writeData2 should win");

    // ====================================================================
    // Test 8: All registers pattern test
    // ====================================================================
    $display("\n=== Test 8: Writing All 16 Registers ===");
    write_dual_reg(0, 1, 32'h00000000, 32'h11111111);
    write_dual_reg(2, 3, 32'h22222222, 32'h33333333);
    write_dual_reg(4, 5, 32'h44444444, 32'h55555555);
    write_dual_reg(6, 7, 32'h66666666, 32'h77777777);
    write_dual_reg(8, 9, 32'h88888888, 32'h99999999);
    write_dual_reg(10, 11, 32'hAAAAAAAA, 32'hBBBBBBBB);
    write_dual_reg(12, 13, 32'hCCCCCCCC, 32'hDDDDDDDD);
    write_dual_reg(14, 15, 32'hEEEEEEEE, 32'hFFFFFFFF);

    check_read(0, 32'h00000000, "All regs: reg[0]");
    check_read(5, 32'h55555555, "All regs: reg[5]");
    check_read(10, 32'hAAAAAAAA, "All regs: reg[10]");
    check_read(15, 32'hFFFFFFFF, "All regs: reg[15]");

    // ====================================================================
    // Test 9: Write disabled (write=0)
    // ====================================================================
    $display("\n=== Test 9: Write Signal Disabled ===");
    @(posedge clk);
    write = 0;  // Write disabled
    writeReg1 = 12;
    writeData1 = 32'h99999999;
    @(posedge clk);
    check_read(12, 32'hCCCCCCCC, "Write disabled: reg[12] unchanged");

    // ====================================================================
    // Test 10: Reset clears all registers
    // ====================================================================
    $display("\n=== Test 10: Reset After Writes ===");
    resetn = 0;
    @(posedge clk);
    @(posedge clk);
    resetn = 1;
    @(posedge clk);

    check_multi_read(0, 5, 10, 15,
                     32'h00000000, 32'h00000000, 32'h00000000, 32'h00000000,
                     "Reset clears all registers");

    // Small delay before summary
    #20;

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

  // Timeout watchdog
  initial begin
    #10000;  // 10us timeout
    $display("\n!!! TIMEOUT: Testbench exceeded maximum time !!!");
    $fatal(1, "Timeout");
  end

endmodule
