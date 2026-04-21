`default_nettype none
`timescale 1ns/1ps

    // Clock and reset
    logic clk;
    logic rst_n;
    logic ena;
    
    // DUT signals
    logic [7:0] ui_in;
    logic [7:0] uo_out;
    logic [7:0] uio_in;
    logic [7:0] uio_out;
    logic [7:0] uio_oe;
    
    // Instantiate DUT
    tt_um_systolic_array dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end
    
    // Test sequence
    initial begin
        $dumpfile("systolic_array.vcd");
        $dumpvars(0, tb_systolic_array);
        
        // Initialize
        rst_n = 0;
        ena = 1;
        ui_in = 8'd0;
        uio_in = 8'd0;
        
        // Reset
        #20;
        rst_n = 1;
        #10;
        
        $display("=== Test: Matrix Multiplication ===");
        $display("Matrix A = [[2, 3], [4, 5]]");
        $display("Matrix B = [[1, 2], [3, 4]]");
        $display("Expected C = [[11, 16], [19, 28]]");
        
        // Load Matrix A
        $display("\nLoading Matrix A...");
        ui_in = 8'b0010_0001; // cmd_load_a = 1, data = 2 (A[0][0])
        #10;
        ui_in = 8'b0011_0000; // data = 3 (A[0][1])
        #10;
        ui_in = 8'b0100_0000; // data = 4 (A[1][0])
        #10;
        ui_in = 8'b0101_0000; // data = 5 (A[1][1])
        #10;
        ui_in = 8'b0000_0000; // Clear command
        #10;
        
        // Load Matrix B
        $display("Loading Matrix B...");
        ui_in = 8'b0001_0010; // cmd_load_b = 1, data = 1 (B[0][0])
        #10;
        ui_in = 8'b0010_0000; // data = 2 (B[0][1])
        #10;
        ui_in = 8'b0011_0000; // data = 3 (B[1][0])
        #10;
        ui_in = 8'b0100_0000; // data = 4 (B[1][1])
        #10;
        ui_in = 8'b0000_0000; // Clear command
        #10;
        
        // Start computation
        $display("Starting computation...");
        ui_in = 8'b0000_0100; // cmd_compute = 1
        #100; // Wait for computation to complete
        ui_in = 8'b0000_0000; // Clear command
        #10;
        
        // Read results
        $display("Reading results...");
        ui_in = 8'b0000_1000; // cmd_read = 1
        #10;
        $display("C[0][0] = %d (expected 11)", uo_out);
        #10;
        $display("C[0][1] = %d (expected 16)", uo_out);
        #10;
        $display("C[1][0] = %d (expected 19)", uo_out);
        #10;
        $display("C[1][1] = %d (expected 28)", uo_out);
        #10;
        ui_in = 8'b0000_0000; // Clear command
        #10;
        
        $display("\n=== Test Complete ===");
        #100;
        $finish;
    end
    
    // Timeout
    initial begin
        #10000;
        $display("ERROR: Timeout!");
        $finish;
    end

endmodule
