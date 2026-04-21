`default_nettype none
// Tiny Tapeout Wrapper for 2x2 Systolic Array
// Provides serial interface to load matrices and read results

module tt_um_systolic_array (
    input  logic [7:0] ui_in,    // Dedicated inputs
    output logic [7:0] uo_out,   // Dedicated outputs
    input  logic [7:0] uio_in,   // IOs: Input path
    output logic [7:0] uio_out,  // IOs: Output path
    output logic [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  logic       ena,      // Enable - goes high when design is selected
    input  logic       clk,      // Clock
    input  logic       rst_n     // Reset (active low)
);

    // Use 4-bit data width to save area
    localparam DATA_WIDTH = 4;
    localparam RESULT_WIDTH = 2 * DATA_WIDTH;
    
    // Command interface from ui_in
    logic [3:0] data_in = ui_in[7:4];
    logic cmd_load_a    = ui_in[0];
    logic cmd_load_b    = ui_in[1];
    logic cmd_compute   = ui_in[2];
    logic cmd_read      = ui_in[3];
    
    // State machine
    typedef enum logic [2:0] {
        IDLE        = 3'b000,
        LOAD_A      = 3'b001,
        LOAD_B      = 3'b010,
        COMPUTE     = 3'b011,
        READ_RESULT = 3'b100
    } state_t;
    
    state_t state, next_state;
    
    // Matrix storage
    logic [DATA_WIDTH-1:0] matrix_a [0:1][0:1]; // 2x2 matrix A
    logic [DATA_WIDTH-1:0] matrix_b [0:1][0:1]; // 2x2 matrix B
    logic [RESULT_WIDTH-1:0] matrix_c [0:1][0:1]; // 2x2 result matrix C
    
    // Load/read counters
    logic [2:0] load_counter;
    logic [2:0] read_counter;
    logic [3:0] compute_counter;
    
    // Systolic array signals
    logic systolic_enable;
    logic [DATA_WIDTH-1:0] a_row0, a_row1;
    logic [DATA_WIDTH-1:0] b_col0, b_col1;
    logic [RESULT_WIDTH-1:0] c00, c01, c10, c11;
    
    // Output register
    logic [7:0] output_reg;
    
    // Bidirectional pins unused - set as inputs
    assign uio_oe = 8'b0;
    assign uio_out = 8'b0;
    
    // Instantiate the 2x2 systolic array
    systolic_array_2x2 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) array (
        .clk(clk),
        .rst_n(rst_n),
        .enable(systolic_enable),
        .a_row0(a_row0),
        .a_row1(a_row1),
        .b_col0(b_col0),
        .b_col1(b_col1),
        .c00(c00),
        .c01(c01),
        .c10(c10),
        .c11(c11)
    );
    
    // State machine - next state logic
    always_comb begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (cmd_load_a)
                    next_state = LOAD_A;
                else if (cmd_load_b)
                    next_state = LOAD_B;
                else if (cmd_compute)
                    next_state = COMPUTE;
                else if (cmd_read)
                    next_state = READ_RESULT;
            end
            
            LOAD_A: begin
                if (load_counter == 3'd3)
                    next_state = IDLE;
            end
            
            LOAD_B: begin
                if (load_counter == 3'd3)
                    next_state = IDLE;
            end
            
            COMPUTE: begin
                // Run for enough cycles to fill the pipeline
                // For 2x2, need about 8 cycles
                if (compute_counter >= 4'd8)
                    next_state = IDLE;
            end
            
            READ_RESULT: begin
                // Output all 4 results (each 8 bits)
                if (read_counter == 3'd3)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // State machine - state register
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else if (ena)
            state <= next_state;
    end
    
    // Counter and data loading
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_counter <= 3'd0;
            read_counter <= 3'd0;
            compute_counter <= 4'd0;
            matrix_a <= '{default: '0};
            matrix_b <= '{default: '0};
            output_reg <= 8'd0;
        end else if (ena) begin
            
            case (state)
                IDLE: begin
                    load_counter <= 3'd0;
                    read_counter <= 3'd0;
                    compute_counter <= 4'd0;
                end
                
                LOAD_A: begin
                    // Load matrix A in row-major order: A00, A01, A10, A11
                    case (load_counter)
                        3'd0: matrix_a[0][0] <= data_in;
                        3'd1: matrix_a[0][1] <= data_in;
                        3'd2: matrix_a[1][0] <= data_in;
                        3'd3: matrix_a[1][1] <= data_in;
                    endcase
                    load_counter <= load_counter + 1'd1;
                end
                
                LOAD_B: begin
                    // Load matrix B in row-major order: B00, B01, B10, B11
                    case (load_counter)
                        3'd0: matrix_b[0][0] <= data_in;
                        3'd1: matrix_b[0][1] <= data_in;
                        3'd2: matrix_b[1][0] <= data_in;
                        3'd3: matrix_b[1][1] <= data_in;
                    endcase
                    load_counter <= load_counter + 1'd1;
                end
                
                COMPUTE: begin
                    compute_counter <= compute_counter + 1'd1;
                    // Capture results when done
                    if (compute_counter == 4'd7) begin
                        matrix_c[0][0] <= c00;
                        matrix_c[0][1] <= c01;
                        matrix_c[1][0] <= c10;
                        matrix_c[1][1] <= c11;
                    end
                end
                
                READ_RESULT: begin
                    // Output lower 8 bits of each result
                    case (read_counter)
                        3'd0: output_reg <= matrix_c[0][0][7:0];
                        3'd1: output_reg <= matrix_c[0][1][7:0];
                        3'd2: output_reg <= matrix_c[1][0][7:0];
                        3'd3: output_reg <= matrix_c[1][1][7:0];
                    endcase
                    read_counter <= read_counter + 1'd1;
                end
                
                default: begin
                    output_reg <= 8'd0;
                end
            endcase
        end
    end
    
    // Systolic array control
    always_comb begin
        systolic_enable = 1'b0;
        a_row0 = 4'd0;
        a_row1 = 4'd0;
        b_col0 = 4'd0;
        b_col1 = 4'd0;
        
        if (state == COMPUTE) begin
            systolic_enable = 1'b1;
            
            // Feed data in proper sequence for systolic array
            case (compute_counter)
                // Cycle 0: Feed A[0,0] and B[0,0]
                4'd0: begin
                    a_row0 = matrix_a[0][0];
                    b_col0 = matrix_b[0][0];
                end
                // Cycle 1: Feed A[0,1], A[1,0], B[0,1], B[1,0]
                4'd1: begin
                    a_row0 = matrix_a[0][1];
                    a_row1 = matrix_a[1][0];
                    b_col0 = matrix_b[1][0];
                    b_col1 = matrix_b[0][1];
                end
                // Cycle 2: Feed A[1,1], B[1,1]
                4'd2: begin
                    a_row1 = matrix_a[1][1];
                    b_col1 = matrix_b[1][1];
                end
                default: begin
                    // Let data propagate through pipeline
                    a_row0 = 4'd0;
                    a_row1 = 4'd0;
                    b_col0 = 4'd0;
                    b_col1 = 4'd0;
                end
            endcase
        end
    end
    
    // Output assignment
    assign uo_out = output_reg;

endmodule
