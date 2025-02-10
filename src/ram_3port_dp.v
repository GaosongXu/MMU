
//Module:       Ram_3Port.v
//Usage:        A simple wallper ram module with 1 write port and 2 read port
//Introduction: The module is used to store the wallper data, and the data can 
//              be read by the read port. If write and read in same postion
//              the read data will be the write data in the same position.
//              The write data will be stored in the ram in the next clk cycle. 
//              The read data will be the data in the ram in the current clk cycle.
`ifndef RAM_3PORT_DP_H
`define RAM_3PORT_DP_H

`include "../src/dpram.v"
module ram_3port_dp #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 64
) (
    clk,
    write_en,
    write_addr,
    write_data,
    read_addr1,
    read_data1,
    read_addr2,
    read_data2
);

//************************************ ports
input clk;

input write_en;
input [ADDR_WIDTH-1:0] write_addr;
input [DATA_WIDTH-1:0] write_data;

input [ADDR_WIDTH-1:0] read_addr1;
output [DATA_WIDTH-1:0] read_data1;
input [ADDR_WIDTH-1:0] read_addr2;
output [DATA_WIDTH-1:0] read_data2;

//************************************ signals
wire [ADDR_WIDTH-1:0] mux_addr;
reg [DATA_WIDTH-1:0] read_data1;
reg [DATA_WIDTH-1:0] read_data2;

assign mux_addr = write_en ? write_addr : read_addr1;

dpram #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) dpram_inst (
    .clk(clk),

    .wen_a(write_en),
    .addr_a(mux_addr),
    .data_a(write_data),
    .q_a(read_data1),

    .wen_b(1'b0),
    .addr_b(read_addr2),
    .data_b(0),
    .q_b(read_data2)
  );

endmodule


`endif