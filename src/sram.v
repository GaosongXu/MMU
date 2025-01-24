//Module:      sram.v
//Usage:       A simple synchronous RAM module with 1 write port and 1 read port
//Introduction: The module is used to store the data, and the data can be read by the read port.

module sram #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 64
) (
   wr_clk,
   wr_en,
   wr_ptr,
   wr_data,
   rd_clk,
   rd_en,
   rd_ptr,
   rd_data
);

//************************************ ports
input wr_clk;
input wr_en;
input [ADDR_WIDTH-1:0] wr_ptr;
input [DATA_WIDTH-1:0] wr_data;
input rd_clk;
input rd_en;
input [ADDR_WIDTH-1:0] rd_ptr;
output [DATA_WIDTH-1:0] rd_data;



//************************************ signals
reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];
reg [DATA_WIDTH-1:0] rd_data;

//************************************ sequential logic
always @(posedge wr_clk) begin
    if(wr_en) begin
        memory[wr_ptr] <= wr_data;
    end
end

always @(posedge rd_clk) begin
    if(rd_en) begin
        rd_data <= memory[rd_ptr];
    end
end

endmodule