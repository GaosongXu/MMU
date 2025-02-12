//Module:      sram.v
//Usage:       A simple synchronous RAM module with 1 write port and 1 read port
//Introduction: The module is used to store the data, and the data can be read by the read port.

module spram #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 64
) (
   clk,
   wr_en,
   wr_ptr,
   wr_data,
   rd_en,
   rd_ptr,
   rd_data
);

//************************************ ports
input clk;
input wr_en;
input [ADDR_WIDTH-1:0] wr_ptr;
input [DATA_WIDTH-1:0] wr_data;

input rd_en;
input [ADDR_WIDTH-1:0] rd_ptr;
output [DATA_WIDTH-1:0] rd_data;



//************************************ signals
(* ram_style = "block" *)
reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];
reg [DATA_WIDTH-1:0] rd_data;

//************************************ sequential logic
always @(posedge clk) begin
    if(wr_en) begin
        memory[wr_ptr] <= wr_data;
    end
end

always @(posedge clk) begin
    if(rd_en) begin
        rd_data <= memory[rd_ptr];
    end
end

endmodule