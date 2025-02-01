
//Module:       Ram_32ort.v
//Usage:        A simple wallper ram module with 1 write port and 1 read port

module ram_2port #(
    parameter ADDR_WIDTH = 6,
    parameter DATA_WIDTH = 64
) (
    clk,
    write_en,
    write_addr,
    write_data,
    read_addr,
    read_data
);
//************************************ ports
input clk;

input write_en;
input [ADDR_WIDTH-1:0] write_addr;
input [DATA_WIDTH-1:0] write_data;

input [ADDR_WIDTH-1:0] read_addr;
output [DATA_WIDTH-1:0] read_data;


//************************************ signals
reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];
reg [DATA_WIDTH-1:0] read_data;


//************************************ sequential logic
always @(posedge clk) begin
    if(write_en) begin
        memory[write_addr] <= write_data;
    end
    if (read_addr == write_addr) begin
        read_data <= write_data;
    end
    else begin
        read_data <= memory[read_addr];
    end
end


    
endmodule

