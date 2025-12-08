`timescale 1ns / 1ps

module calc_tb;
    // Inputs
    reg clk;
    reg btnac;
    reg btnl;
    reg btnr;
    reg btnc;
    reg btnd;
    reg [15:0] sw;
    
    // Outputs
    wire [15:0] led;
    
    // Instantiate the calculator
    calc uut (
        .clk(clk),
        .btnac(btnac),
        .btnl(btnl),
        .btnr(btnr),
        .btnc(btnc),
        .btnd(btnd),
        .sw(sw),
        .led(led)
    );
    
    // Clock generation (10ns period = 100MHz)
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, calc_tb);
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Task to press btnc (execute operation)
    task press_btnc;
    begin
    // Wait some time before first press
    	#50;        // wait 50 time units
    	btnc = 1; // press button
    	#20;        // hold for 20 time units
    	btnc = 0; // release button
    end
    endtask

    
    // Task to set ALU buttons
    task set_buttons(input l, input r, input d);
    begin
        btnl = l;
        btnr = r;
        btnd = d;
    end
    endtask
    
    // Main test sequence
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, calc_tb);
        // Initialize inputs
        btnac = 0; btnl = 0; btnr = 0; btnc = 0; btnd = 0; sw = 16'h0000;
        btnac = 1; @(posedge clk); btnac = 0;  // Force reset
        
        $display("Starting Calculator Testbench\n");
        $display("Time\tOperation\tSwitches\tLED");
        $display("====\t=========\t========\t===");
        
        // Wait a few clocks for initialization
        // @(posedge clk); @(posedge clk);
        
        // --- Test 1: Reset ---
        btnac = 1;
        @(posedge clk);
        btnac = 0;
        @(posedge clk);
        press_btnc();

        $display("%0t\tRESET\t\t%h\t\t%h", $time, sw, led);
        if (led !== 16'h0000) $display("ERROR: Expected 0x0000, got %h", led);
        
        // --- Test 2: ADD (btnl=0, btnr=1, btnd=0) ---
        set_buttons(0, 1, 0);
        sw = 16'h285a;
        press_btnc();
        $display("%0t\tADD\t\t%h\t\t%h", $time, sw, led);
        if (led !== 16'h285a) $display("ERROR: Expected 0x285a, got %h", led);
        
        // --- Test 3: XOR (btnl=1, btnr=1, btnd=1) ---
        set_buttons(1, 1, 1);
        sw = 16'h04c8;
        press_btnc();
        $display("%0t\tXOR\t\t%h\t\t%h", $time, sw, led);
        if (led !== 16'h2c92) $display("ERROR: Expected 0x2c92, got %h", led);
        
        // --- Test 4: Logical Shift Right (btnl=0, btnr=0, btnd=0) ---
        set_buttons(0, 0, 0);
        sw = 16'h0005;
        press_btnc();
        $display("%0t\tLSR\t\t%h\t\t%h", $time, sw, led);
        if (led !== 16'h0164) $display("ERROR: Expected 0x0164, got %h", led);
        
        // --- Test 5: NOR (btnl=1, btnr=0, btnd=1) ---
        set_buttons(1, 0, 1);
        sw = 16'ha085;
        press_btnc();
        $display("%0t\tNOR\t\t%h\t\t%h", $time, sw, led);
        if (led !== 16'h5e1a) $display("ERROR: Expected 0x5e1a, got %h", led);
        
        // --- Test 6: MULT (btnl=1, btnr=0, btnd=0) ---
        set_buttons(1, 0, 0);
        sw = 16'h07fe;
        press_btnc();
        $display("%0t\tMULT\t\t%h\t\t%h", $time, sw, led);
        if (led !== 16'h13cc) $display("ERROR: Expected 0x13cc, got %h", led);
        
        // --- Test 7: Logical Shift Left (btnl=0, btnr=0, btnd=1) ---
        set_buttons(0, 0, 1);
        sw = 16'h0004;
        press_btnc();
        $display("%0t\tLSL\t\t%h\t\t%h", $time, sw, led);
        if (led !== 16'h3cc0) $display("ERROR: Expected 0x3cc0, got %h", led);
        
        // --- Test 8: NAND (btnl=1, btnr=1, btnd=0) ---
        set_buttons(1, 1, 0);
        sw = 16'hfa65;
        press_btnc();
        $display("%0t\tNAND\t\t%h\t\t%h", $time, sw, led);
        if (led !== 16'hc7bf) $display("ERROR: Expected 0xc7bf, got %h", led);
        
        // --- Test 9: SUB (btnl=0, btnr=1, btnd=1) ---
        set_buttons(0, 1, 1);
        sw = 16'hb2e4;
        press_btnc();
        $display("%0t\tSUB\t\t%h\t\t%h", $time, sw, led);
        if (led !== 16'h14db) $display("ERROR: Expected 0x14db, got %h", led);
        
        // Final summary
        #50;
        $display("\nTestbench completed!");
        $finish;
    end
    
    // Monitor changes (optional, for debugging)
    initial begin
        $monitor("Time=%0t btnl=%b btnr=%b btnd=%b btnc=%b sw=%h led=%h", 
                 $time, btnl, btnr, btnd, btnc, sw, led);
    end

endmodule
