`timescale 1ns / 1ps

module spi_main_tb;

    parameter CLK_PERIOD = 10;
    parameter DIV_FACTOR = 10;
    parameter DATA_WIDTH = 8;
    parameter CPOL       = 1;
    parameter CPHA       = 0;
    
    logic clk;
    logic reset;
    logic [DATA_WIDTH-1:0] i_data_in_TX;
    logic i_data_valid_TX;
    logic o_data_raedy_TX;
    logic i_MISO;
    logic o_SS;
    logic o_MOSI;
    logic o_SCLK;
    logic o_data_done;
    logic [DATA_WIDTH-1:0] o_data_out;
    

    spi_main #(
        .DIV_FACTOR(DIV_FACTOR)
        ,.DATA_WIDTH(DATA_WIDTH)
        ,.CPOL(CPOL)
        ,.CPHA(CPHA)
    ) spi_main_inst (
        .clk(clk)
        ,.reset(reset)
        ,.i_data_in_TX(i_data_in_TX)
        ,.o_data_raedy_TX(o_data_raedy_TX)
        ,.i_MISO(i_MISO)
        ,.o_SS(o_SS)
        ,.o_MOSI(o_MOSI)
        ,.o_SCLK(o_SCLK)
        ,.o_data_done(o_data_done)
        ,.o_data_out(o_data_out)
    );
    
    
    // Clock signal generation
    initial begin
        clk <= 0;
        forever begin
            #(CLK_PERIOD/2) clk <= ~clk;
        end
    end
    
    initial begin
        i_data_in_TX = 8'b10101010;
        i_MISO = 1'b0;
        
        reset = 1;
        // Reset signals
        i_data_valid_TX = 1'b0;
        //
        #(CLK_PERIOD*2)
        reset = 0;
        
        #(CLK_PERIOD*2);
        i_data_valid_TX = 1;
        #(CLK_PERIOD*2);
        i_data_valid_TX = 0;
        
        #(CLK_PERIOD*2);
        i_MISO = 1;
        #(CLK_PERIOD*10);
        i_MISO = 0;
        #(CLK_PERIOD*10);
        i_MISO = 1;
        #(CLK_PERIOD*10);
        i_MISO = 1;
        #(CLK_PERIOD*10);
        i_MISO = 1;
        #(CLK_PERIOD*10);
        i_MISO = 1;
        #(CLK_PERIOD*10);
        i_MISO = 1;
        #(CLK_PERIOD*10);
        i_MISO = 0;
        
        
    end
    

endmodule
