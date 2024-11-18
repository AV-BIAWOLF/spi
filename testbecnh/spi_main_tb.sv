`timescale 1ns / 1ps

module top_spi_main_tb;

    // Parameters
    parameter CLK_PERIOD = 10;  
    parameter DATA_WIDTH = 8;

    // Signals
    logic clk;
    logic reset;

    // TX (MOSI) Signals
    logic [DATA_WIDTH-1:0] i_data_in_TX;
    logic i_data_valid_TX;
    logic o_data_raedy_TX;

    // RX (MISO) Signals
    logic i_MISO;
    logic [DATA_WIDTH-1:0] o_data_out;

    // SPI interface
    logic o_SS;
    logic o_MOSI;
    logic o_SCLK;
    logic o_data_done;

    // Test variables
    logic transfer_done; 
    logic error;
    logic success;

    // Instantiation DUT
    top_spi_main #(
        .DATA_WIDTH(DATA_WIDTH)
    ) top_spi_dut (
        .clk(clk),
        .reset(reset),
        .i_data_in_TX(i_data_in_TX),
        .i_data_valid_TX(i_data_valid_TX),
        .o_data_raedy_TX(o_data_raedy_TX),
        .i_MISO(i_MISO),
        .o_SS(o_SS),
        .o_MOSI(o_MOSI),
        .o_SCLK(o_SCLK),
        .o_data_done(o_data_done),
        .o_data_out(o_data_out),
        .transfer_done(transfer_done)
    );

    // Clock signal generation
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Reset generation
    task apply_reset;
        begin
            reset = 1'b1;
            #(CLK_PERIOD * 2);
            reset = 1'b0;
            #(CLK_PERIOD);
        end
    endtask

    logic [DATA_WIDTH-1:0] data_MOSI;

    // Transfer of one byte to the master
    task SendSingleByte_MOSI(input [DATA_WIDTH-1:0] data);
        begin
        
            success = 0;
            error = 0;
        
            @(posedge clk);
            i_data_in_TX = data;
            i_data_valid_TX = 1'b1; // Set the data validation signal
            @(posedge clk);
            i_data_valid_TX = 1'b0; // Resetting the validation signal
            @(posedge clk);
            
            Check_MOSI(data_MOSI);
            
            wait(transfer_done);      // Waiting for the transfer to complete
            
            if (data == data_MOSI) begin
                success = 1;
                @(posedge clk);
            end else begin 
                error = 1;
                @(posedge clk);
                $display("\nMOSI MISSMATCH");
                $display("Sent: 0x%h = %b", data, data);
                $display("RECIEVED 0x%h = %b", data_MOSI, data_MOSI);
            end
            
        end
    endtask
    
    // Check the data from MOSI
    task Check_MOSI(output [DATA_WIDTH-1:0] data_MOSI);
        begin
            for (int i = 0; i < DATA_WIDTH; i++) begin
                @(posedge o_SCLK);
                data_MOSI[i] = o_MOSI;
            end
        end
    endtask 
    
    // Generate data for MISO 
    task Generate_MISO(input [DATA_WIDTH-1:0] data);
        begin
            for (int i=0; i<DATA_WIDTH; i++) begin
                @(negedge o_SCLK);
                i_MISO = data[i];
            end
            wait(transfer_done);      // Waiting for the transfer to complete
            Check_MISO(data); // Вызов Check_MISO после передачи данных по MISO
        end
    endtask 
    
    task Check_MISO(input [DATA_WIDTH-1:0] data);
        begin
            success = 0;
            error = 0;
            if (data == o_data_out) begin
                success = 1;
                @(posedge clk);
            end else begin
                error = 1;
                @(posedge clk);
                $display("\nMISO MISSMATCH");
                $display("Sent: 0x%h = %b", data, data);
                $display("RECIEVED 0x%h = %b", o_data_out, o_data_out);
            end
        end
    endtask 

    // Task for paralel execution 
    task ParallelTask (input [DATA_WIDTH-1:0] data_to_send, input [DATA_WIDTH-1:0] data_to_receive);
        begin 
            fork // fork-join -- construction for paralel execution 
                begin 
                    Generate_MISO(data_to_receive);
                end
                begin 
                    SendSingleByte_MOSI(data_to_send);
                end
            join
        end
    endtask 

    // Basic test
    initial begin
    
        logic [DATA_WIDTH-1:0] data_to_send;
        logic [DATA_WIDTH-1:0] data_to_receive;
        
//        error = 0;
//        success = 0;
   
        // Reset all inputs
        i_data_in_TX = 8'b0;
        i_data_valid_TX = 1'b0;
        i_MISO = 1'b0;

        // Applying the reset
        apply_reset();

        // Test scenario
        $display("Starting SPI Master transmission test...");
        
        // Byte transfer 
        repeat(10) begin
            data_to_receive = $urandom % 256;
            data_to_send = $urandom % 256;
            ParallelTask(data_to_send, data_to_receive);
        end
        
        $finish;
    end

endmodule
