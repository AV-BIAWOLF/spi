`timescale 1ns / 1ps

//mode №   CPOL CPHA
//mode 0     0     0
//mode 1     0     1
//mode 2     1     0
//mode 3     1     1


module spi_main #(
    parameter DIV_FACTOR = 10,
    parameter DATA_WIDTH = 8,
    parameter CPOL       = 1,
    parameter CPHA       = 1
)(  
    // Control signals
    input logic clk,
    input logic reset, 
    
    // TX (MOSI) Signals
    input logic [DATA_WIDTH-1:0] i_data_in_TX,
    input logic i_data_valid_TX,  // Data ready with i_data_in
    output logic o_data_raedy_TX, // Ready to recive new data for transmite
    
    // RX (MISO) signals
    input logic i_MISO,
    
//    output logic o_SS,
    output logic o_MOSI,
    output logic o_SCLK,
    output logic o_data_done, // Ready for next data
    output logic [DATA_WIDTH-1:0] o_data_out
    
    );

    
   logic [DATA_WIDTH-1:0] r_data;
   logic [16:0] counter_clks;
   logic w_CPOL;
   logic w_CPHA;
   logic r_SCLK;
   logic w_Rise_Edge;
   logic w_Fall_Edge;
   logic [4:0] count_TX_MOSI; 
   logic [4:0] count_RX_MISO; 
   
   
   always @(posedge clk) begin
        if (reset) begin 
            counter_clks <= 0;
            r_SCLK <= w_CPOL;
            w_Fall_Edge <= 1'b0;
            w_Rise_Edge <= 1'b0;
        end
        else begin
            w_Fall_Edge <= 1'b0;
            w_Rise_Edge <= 1'b0;
            
            if (counter_clks == ((DIV_FACTOR/2)-1)) begin // -1
                w_Rise_Edge <= 1'b1;
                r_SCLK <= ~r_SCLK;
            end
            
            if (counter_clks == ((DIV_FACTOR)-1)) begin   // -1
                counter_clks <= 0;  // Сброс счетчика
                w_Fall_Edge <= 1'b1;
                r_SCLK <= ~r_SCLK;
            end
            else begin
                counter_clks <= counter_clks + 1;  // Увеличение счетчика
            end
        end
    end

   
   // This block to avoid metastability and to sync signals Pise_Edge and Fall_Edge with SCLk (o_SCLK)
    always @(posedge clk) begin
        if (reset) begin
            o_SCLK <= CPOL;
        end
        else begin
            o_SCLK <= r_SCLK;
        end
    end
    
    // MOSI
    always @(posedge clk) begin
        if (reset) begin
            count_TX_MOSI <= 0;
            o_data_raedy_TX <= 0;
            o_MOSI <= 0;
        end
        else if ((w_Rise_Edge & CPHA) | (w_Fall_Edge & ~CPHA)) begin
            
            if (count_TX_MOSI < DATA_WIDTH) begin
        
            o_MOSI <= i_data_in_TX[count_TX_MOSI];
            count_TX_MOSI <= count_TX_MOSI + 1;
            o_data_raedy_TX <= 1;
            
            end
            else begin
                o_data_raedy_TX <= 0;   
                count_TX_MOSI <= 0;      
                o_MOSI <= 0;
            end
            
            
        end
//        o_data_raedy_TX <= 0;
    end
    
    // MISO 
    always @(posedge clk) begin
        if (reset) begin
            count_RX_MISO <= 0;
            o_data_done <= 0;
        end 
        else if ((w_Rise_Edge & ~CPHA) | (w_Fall_Edge & CPHA)) begin
            if (count_RX_MISO < 10'd8) begin 
                o_data_out[count_RX_MISO] <= i_MISO;
                count_RX_MISO <= count_RX_MISO + 1;
                o_data_done <= 0;
            end
            else begin
                o_data_done <= 1;
                count_RX_MISO <= 0;
            end
       end 
    end
    
    
endmodule
