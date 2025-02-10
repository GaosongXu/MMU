
//Module:       Ram_3Port.v
//Usage:        A simple wallper ram module with 1 write port and 2 read port
//Introduction: The module is used to store the wallper data, and the data can 
//              be read by the read port. If write and read in same postion
//              the read data will be the write data in the same position.
//              The write data will be stored in the ram in the next clk cycle. 
//              The read data will be the data in the ram in the current clk cycle.
`ifndef RAM_3PORT_SP_H
`define RAM_3PORT_SP_H

`include "../src/spram.v"
module ram_3port_sp #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 64
) (
    clk,
    write_en,
    write_addr,
    write_data,
    read_en1,
    read_addr1,
    read_data1,
    read_en2,
    read_addr2,
    read_data2
);

//************************************ ports
input clk;

input write_en;
input [ADDR_WIDTH-1:0] write_addr;
input [DATA_WIDTH-1:0] write_data;

input read_en1;
input [ADDR_WIDTH-1:0] read_addr1;
output [DATA_WIDTH-1:0] read_data1;

input read_en2;
input [ADDR_WIDTH-1:0] read_addr2;
output [DATA_WIDTH-1:0] read_data2;

//************************************ signals
wire read_en;
wire [ADDR_WIDTH-1:0] read_addr;
wire [DATA_WIDTH-1:0] read_data;

reg [DATA_WIDTH-1:0] read_data1;
reg [DATA_WIDTH-1:0] read_data2;

assign read_en = read_en1 | read_en2;
assign read_addr = read_en1 ? read_addr1 : read_addr2;
assign read_data1 = read_data;
assign read_data2 = read_data;

spram  #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
) spram_inst (
    .clk(clk),
    .wr_en(write_en),
    .wr_ptr(write_addr),
    .wr_data(write_data),
    .rd_en(read_en),
    .rd_ptr(read_addr),
    .rd_data(read_data)
  );

endmodule


`endif