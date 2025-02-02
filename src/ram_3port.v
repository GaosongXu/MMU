
//Module:       Ram_3Port.v
//Usage:        A simple wallper ram module with 1 write port and 2 read port
//Introduction: The module is used to store the wallper data, and the data can 
//              be read by the read port. If write and read in same postion
//              the read data will be the write data in the same position.
//              The write data will be stored in the ram in the next clk cycle. 
//              The read data will be the data in the ram in the current clk cycle.

module ram_3port #(
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
reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];
reg [DATA_WIDTH-1:0] read_data1;
reg [DATA_WIDTH-1:0] read_data2;


//************************************ sequential logic
always @(posedge clk) begin
    if(write_en) begin
        memory[write_addr] <= write_data;
    end
end

always @(posedge clk ) begin
    read_data1 <= memory[read_addr1];    
end


always @(posedge clk ) begin
    read_data2 <= memory[read_addr2];    
end
 
endmodule

