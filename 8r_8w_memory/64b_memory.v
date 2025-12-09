// 8 × 8 RAM RTL code. The depth and width can be changed below
module b64_memory (
    clk,
    rst,
    we,
    addr,
    wrdata,
    rddata,
    VPWR,
    VGND
);
    parameter ADDR_WIDTH = 3;
    parameter DATA_WIDTH = 8;
    parameter DEPTH      = 8;
    input  wire  clk;
    input  wire  rst;
    input  wire  we;
    input  wire [ADDR_WIDTH-1:0]  addr;
    input  wire [DATA_WIDTH-1:0]  wrdata;
    output reg  [DATA_WIDTH-1:0]  rddata;
    inout wire VPWR;
    inout wire VGND;
    reg [DATA_WIDTH-1:0] rem_memory_temp [0:DEPTH-1];
    integer i;  // procedural loop variable
    //wire power_ok;
    //assign power_ok = VDD & ~VSS;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < DEPTH; i = i + 1)
                rem_memory_temp[i] <= 8'b0;
        end
        else if (we) begin
            rem_memory_temp[addr] <= wrdata;
        end
        else begin
            rddata <= rem_memory_temp[addr];
        end
    end
endmodule
