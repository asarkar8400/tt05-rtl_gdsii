// Processing Element for Systolic Array
// Performs MAC operation: acc = acc + (a * b)

module systolic_pe #(
    parameter DATA_WIDTH = 8
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    enable,
    
    // Input data from left neighbor
    input  logic [DATA_WIDTH-1:0]   a_in,
    // Input data from top neighbor  
    input  logic [DATA_WIDTH-1:0]   b_in,
    
    // Pass-through to right neighbor
    output logic [DATA_WIDTH-1:0]   a_out,
    // Pass-through to bottom neighbor
    output logic [DATA_WIDTH-1:0]   b_out,
    
    // Accumulated result
    output logic [2*DATA_WIDTH-1:0] result
);

    logic [2*DATA_WIDTH-1:0] accumulator;
    logic [2*DATA_WIDTH-1:0] product;
    
    // Multiply inputs
    assign product = a_in * b_in;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accumulator <= '0;
            a_out <= '0;
            b_out <= '0;
        end else if (enable) begin
            // MAC operation
            accumulator <= accumulator + product;
            
            // Pipeline data to neighbors
            a_out <= a_in;
            b_out <= b_in;
        end
    end
    
    assign result = accumulator;

endmodule
