// --------------------------------------------------------------------------
// spi_master_top.v
// Top Module: SPI Master Controller
// --------------------------------------------------------------------------
module spi_master_top (
    // System Ports
    input wire clk,             
    input wire reset_n,         

    // User Data Ports
    input wire start_transfer,  
    input wire [7:0] tx_data_in,
    output wire [7:0] rx_data_out,
    output wire data_transfer_done, // Combined completion signal
    
    // SPI Physical Ports
    output wire SCK,             
    output wire MOSI,            
    output reg SS_n,            
    input wire MISO             
);

// Parameters (SCK speed)
parameter CLK_DIV_MAX = 4;
localparam DATA_WIDTH = 8;

// Internal FSM/Control Signals
localparam [1:0] IDLE = 2'b00, START = 2'b01, TRANSFER = 2'b10;
reg [1:0] state, next_state;
reg [$clog2(CLK_DIV_MAX):0] clk_div_counter;
reg [2:0] bit_counter; 
wire tx_done_int, rx_done_int;

assign data_transfer_done = tx_done_int & rx_done_int;

// --------------------------------------------------------------------------
// 1. SCK Clock Generation & Bit Counter
// --------------------------------------------------------------------------
reg SCK_reg; 
assign SCK = SCK_reg; // SCK is driven by a wire now

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        clk_div_counter <= 0;
        SCK_reg <= 0;
        bit_counter <= 0;
    end else begin
        if (state == TRANSFER) begin
            if (clk_div_counter == CLK_DIV_MAX) begin
                clk_div_counter <= 0;
                SCK_reg <= ~SCK_reg; 
                
                // Increment bit counter on the negative edge of SCK
                if (SCK_reg == 1) begin 
                   bit_counter <= bit_counter + 1;
                end
            end else begin
                clk_div_counter <= clk_div_counter + 1;
            end
        end else begin
            clk_div_counter <= 0;
            SCK_reg <= 0;
            bit_counter <= 0; 
        end
    end
end

// --------------------------------------------------------------------------
// 2. Main FSM (SS_n Control)
// --------------------------------------------------------------------------
always @(*) begin
    next_state = state;
    case (state)
        IDLE: if (start_transfer) next_state = START;
        START: next_state = TRANSFER;
        TRANSFER: 
            // Transfer ends when both Tx and Rx confirm completion
            if (data_transfer_done) next_state = IDLE; 
        default: next_state = IDLE;
    endcase
end

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        state <= IDLE;
        SS_n <= 1'b1; // Inactive
    end else begin
        state <= next_state;
        
        case (state)
            IDLE: SS_n <= 1'b1;
            START: SS_n <= 1'b0; // Activate SS
            TRANSFER: SS_n <= 1'b0;
        endcase
    end
end

// --------------------------------------------------------------------------
// 3. Module Instantiation (Tx and Rx are separate)
// --------------------------------------------------------------------------
spi_master_tx TX_MOD (
    .clk(clk),
    .reset_n(reset_n),
    .start_transfer(start_transfer),
    .tx_data_in(tx_data_in),
    .SS_n(SS_n),
    .SCK(SCK),
    .bit_counter_in(bit_counter),
    .MOSI(MOSI),
    .tx_done(tx_done_int)
);

spi_master_rx RX_MOD (
    .clk(clk),
    .reset_n(reset_n),
    .SS_n(SS_n),
    .SCK(SCK),
    .MISO(MISO),
    .bit_counter_in(bit_counter),
    .rx_data_out(rx_data_out),
    .rx_done(rx_done_int)
);

endmodule
