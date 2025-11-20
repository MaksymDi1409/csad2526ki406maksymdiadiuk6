// --------------------------------------------------------------------------
// spi_master_top_tb.v (FINAL CORRECTED TIMING)
// --------------------------------------------------------------------------
`timescale 1ns / 1ps

module spi_master_top_tb;

    parameter CLK_PERIOD = 10; 
    parameter TEST_TX_DATA = 8'h5A; 
    parameter TEST_RX_DATA = 8'hC3; 

    reg clk;
    reg reset_n;
    reg start_transfer;
    reg [7:0] tx_data_in;
    reg MISO_in; 

    wire [7:0] rx_data_out;
    wire data_transfer_done; 
    wire SCK;
    wire MOSI;
    wire SS_n;

    reg [3:0] slave_bit_counter; 
    reg [7:0] slave_tx_reg;

    spi_master_top DUT (
        .clk(clk), .reset_n(reset_n), .start_transfer(start_transfer),
        .tx_data_in(tx_data_in), .rx_data_out(rx_data_out),
        .data_transfer_done(data_transfer_done), .SCK(SCK),
        .MOSI(MOSI), .SS_n(SS_n), .MISO(MISO_in) 
    );

    // 1. System Clock Generation
    initial begin
        clk = 0;
        forever # (CLK_PERIOD/2) clk = ~clk;
    end

    // 2. Slave Imitation Logic (Slave changes data on NEGEDGE for CPHA=0)
    // FIX: Triggered on negedge SCK to avoid race condition
    always @(negedge SCK or negedge reset_n) begin 
        if (!reset_n) begin
            MISO_in <= 1'b1; 
            slave_bit_counter <= 0;
            slave_tx_reg <= TEST_RX_DATA;
        end else if (SS_n == 0) begin
            // Slave sets data on SCK negedge 
            // (so it's stable for Master's posedge sample)
            MISO_in <= slave_tx_reg[7]; 
            slave_tx_reg <= slave_tx_reg << 1;
            slave_bit_counter <= slave_bit_counter + 1;
        end else begin
            slave_bit_counter <= 0;
            slave_tx_reg <= TEST_RX_DATA;
        end
    end

    // 3. Test Scenario
    initial begin
        reset_n = 0; start_transfer = 0; tx_data_in = 8'h00; MISO_in = 1'b1; 
        # (2 * CLK_PERIOD);
        reset_n = 1;
        # (5 * CLK_PERIOD);
        
        tx_data_in = TEST_TX_DATA; 
        start_transfer = 1;
        # (2 * CLK_PERIOD);
        start_transfer = 0;

        wait(data_transfer_done); 

        $display("-----------------------------------------");
        $display("Transfer completed.");
        $display("TX Data (from Master): %h", TEST_TX_DATA);
        $display("RX Data (received by Master): %h", rx_data_out);
        
        if (rx_data_out == TEST_RX_DATA) begin
            $display("VERIFICATION SUCCESSFUL: Received data is correct: %h.", rx_data_out);
        end else begin
            $display("VERIFICATION FAILED: Expected %h, received %h", TEST_RX_DATA, rx_data_out);
        end
        $display("-----------------------------------------");
        # (10 * CLK_PERIOD);
        $finish; 
    end
endmodule
