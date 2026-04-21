// 2x2 Systolic Array for Matrix Multiplication
// Computes C = A * B (all 2x2 matrices)

module systolic_array_2x2 #(
    parameter DATA_WIDTH = 8
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    enable,
    
    // A matrix inputs (rows fed from left)
    input  logic [DATA_WIDTH-1:0]   a_row0,
    input  logic [DATA_WIDTH-1:0]   a_row1,
    
    // B matrix inputs (columns fed from top)
    input  logic [DATA_WIDTH-1:0]   b_col0,
    input  logic [DATA_WIDTH-1:0]   b_col1,
    
    // Result outputs (C matrix, accumulated)
    output logic [2*DATA_WIDTH-1:0] c00, c01,
    output logic [2*DATA_WIDTH-1:0] c10, c11
);

    // Internal wiring between PEs
    logic [DATA_WIDTH-1:0] pe00_a_out, pe01_a_out;
    logic [DATA_WIDTH-1:0] pe00_b_out, pe10_b_out;
    logic [DATA_WIDTH-1:0] pe10_a_out, pe11_a_out;
    logic [DATA_WIDTH-1:0] pe01_b_out, pe11_b_out;
    
    // PE(0,0) - top-left
    systolic_pe #(.DATA_WIDTH(DATA_WIDTH)) pe00 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .a_in(a_row0),
        .b_in(b_col0),
        .a_out(pe00_a_out),
        .b_out(pe00_b_out),
        .result(c00)
    );
    
    // PE(0,1) - top-right
    systolic_pe #(.DATA_WIDTH(DATA_WIDTH)) pe01 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .a_in(pe00_a_out),
        .b_in(b_col1),
        .a_out(pe01_a_out),
        .b_out(pe01_b_out),
        .result(c01)
    );
    
    // PE(1,0) - bottom-left
    systolic_pe #(.DATA_WIDTH(DATA_WIDTH)) pe10 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .a_in(a_row1),
        .b_in(pe00_b_out),
        .a_out(pe10_a_out),
        .b_out(pe10_b_out),
        .result(c10)
    );
    
    // PE(1,1) - bottom-right
    systolic_pe #(.DATA_WIDTH(DATA_WIDTH)) pe11 (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .a_in(pe10_a_out),
        .b_in(pe01_b_out),
        .a_out(pe11_a_out),
        .b_out(pe11_b_out),
        .result(c11)
    );

endmodule
