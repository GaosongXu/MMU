//Module: sync_fifo.v
//Usage:  A simple synchronous FIFO module with 1 write port and 1 read port
//Introduction: The module is used to store the data, and the data can be read by the read port.
//              For interface to dsa.

`include "src/simple_dual_one_clock.v"

module sync_fifo #(
    parameter FIFO_PTR = 10,
    parameter FIFO_WIDTH = 32,
    parameter FIFO_DEPTH = 1024
) (
    clk,
    rst_n,
    write_en,
    write_data,
    read_en,
    read_data,
    fifo_full,
    fifo_empty,
    fifo_data_count,
    fifo_free_count
);

//************************************ ports
input clk;
input rst_n;
input write_en;
input [FIFO_WIDTH-1:0] write_data;
input read_en;
output [FIFO_WIDTH-1:0] read_data;
output fifo_full;
output fifo_empty;  
output [FIFO_PTR-1:0] fifo_data_count;
output [FIFO_PTR-1:0] fifo_free_count;

//************************************ parameters
localparam FIFO_DEPTH_MINUS1 =  FIFO_DEPTH - 1;

//************************************ signals
reg [FIFO_PTR-1:0] wr_ptr,wr_ptr_next;
reg [FIFO_PTR-1:0] rd_ptr,rd_ptr_next;
reg [FIFO_PTR-1:0] num_entries,num_entries_next;
reg fifo_full,fifo_empty;
wire fifo_full_next,fifo_empty_next;
reg [FIFO_PTR-1:0] fifo_free_count;
wire [FIFO_PTR-1:0] fifo_free_count_next;
wire [FIFO_PTR-1:0] fifo_data_count;

//************************************ combinational logic
always @(*) begin:wr_ptr_next_logic
    wr_ptr_next = wr_ptr;
    if (write_en)begin
       if (wr_ptr==FIFO_DEPTH_MINUS1)begin
           wr_ptr_next = 0;
       end
       else begin
           wr_ptr_next = wr_ptr + 1;
       end 
    end    
end

always @(*) begin
    rd_ptr_next = rd_ptr;
    if (read_en)begin
       if (rd_ptr==FIFO_DEPTH_MINUS1)begin
           rd_ptr_next = 0;
       end
       else begin
           rd_ptr_next = rd_ptr + 1;
       end 
    end    
end

always @(*) begin
    num_entries_next = num_entries;
    if (write_en && read_en)begin
        num_entries_next = num_entries;
    end
    else if (write_en)begin
        num_entries_next = num_entries + 1;
    end
    else if (read_en)begin
        num_entries_next = num_entries - 1;
    end
end

assign fifo_full_nxt = (num_entries_next == FIFO_DEPTH);
assign fifo_empty_nxt = (num_entries_next == 0);
assign fifo_data_count = num_entries;
assign fifo_free_count_next = FIFO_DEPTH - num_entries;


//*********************************************sequential logic

always @(posedge clk or negedge rst_n) begin
    if (~rst_n)begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        num_entries <= 0;
        fifo_full <= 0;
        fifo_empty <= 1;
        fifo_free_count <= FIFO_DEPTH;
    end
    else begin
        wr_ptr <= wr_ptr_next;
        rd_ptr <= rd_ptr_next;
        num_entries <= num_entries_next;
        fifo_full <= fifo_full_nxt;
        fifo_empty <= fifo_empty_nxt;
        fifo_free_count <= fifo_free_count_next;
    end
end

//build a sram here
simple_dual_one_clock  #(
    .ADDR_WIDTH(FIFO_PTR),
    .DATA_WIDTH(FIFO_WIDTH)
) sdp_0 (
    .clk(clk),
    .wr_en(write_en),
    .wr_ptr(wr_ptr),
    .wr_data(write_data),
    .rd_en(read_en),
    .rd_ptr(rd_ptr),
    .rd_data(read_data)
  );

endmodule


