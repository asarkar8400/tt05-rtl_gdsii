`default_nettype none
`timescale 1ns/1ps

/*
This testbench only serves as a wrapper for Cocotb. 
The actual test logic is in test.py
*/

module tb_systolic_array;

    // These signals are driven by the Cocotb Python script
    reg clk;
    reg rst_n;
    reg ena;
    reg [7:0] ui_in;
    reg [7:0] uio_in;
    
    // These signals are read by the Cocotb Python script
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    // Instantiate the Digital Unit Under Test (DUT)
    tt_um_systolic_array dut (
        .ui_in   (ui_in),    // Dedicated inputs
        .uo_out  (uo_out),   // Dedicated outputs
        .uio_in  (uio_in),   // IOs: Input path
        .uio_out (uio_out),  // IOs: Output path
        .uio_oe  (uio_oe),   // IOs: Enable path
        .ena     (ena),      // enable
        .clk     (clk),      // clock
        .rst_n   (rst_n)     // reset_n - low to reset
    );

endmodule
