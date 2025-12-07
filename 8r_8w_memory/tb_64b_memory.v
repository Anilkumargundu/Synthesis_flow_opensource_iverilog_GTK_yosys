`timescale 1ns/1ps

module tb_64b_memory;
    parameter ADDR_WIDTH = 3;
    parameter DATA_WIDTH = 8;
    parameter DEPTH      = 8;
    reg  clk;
    reg  rst;
    reg  we;
    reg [ADDR_WIDTH-1:0]  addr;
    reg [DATA_WIDTH-1:0]  wrdata;
    wire  [DATA_WIDTH-1:0]  rddata;
    b64_memory dut (
    .clk(clk),
    .rst(rst),
    .we(we),
    .addr(addr),
    .wrdata(wrdata),
    .rddata(rddata));
    initial begin
        clk=1'b0;
        forever begin
            #5 clk=~clk;
        end
    end
    // reset task definition
    task reset_task;
    begin
        rst = 1;
        addr = 0;
        wrdata = 0;
        we = 0;
        #44;
        rst = 0;
    end
    endtask
    // write task definition
    task write_task (input [ADDR_WIDTH-1:0]  address,
    input [DATA_WIDTH-1:0] data_tmp);
    begin
        we = 1;
        rst = 0;
        addr = address;
        wrdata = data_tmp;
        @(posedge clk)
        #1;
        we = 0;
        
    end
    endtask
    
    // read task definition
    task read_task (input [ADDR_WIDTH-1:0]  address);
    begin
        addr = address;
        @(posedge clk);
    end
    endtask

    // calling the events
    initial begin
       reset_task;
       write_task (3'h0, 8'h3);
       write_task (3'h1, 8'h4);
       write_task (3'h2, 8'h5);
       write_task (3'h3, 8'h6);
       read_task (3'h0);
       read_task (3'h1);
       read_task (3'h2);
       read_task (3'h3);
       write_task (3'h3, 8'h7);
       read_task (3'h3);
       read_task (3'h1);
       read_task (3'h0);
    #500 $finish;
    end

    initial begin
    $dumpfile("SRAM.vcd");
    $dumpvars;
    //$finish;
    end

endmodule
