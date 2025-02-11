
//Module:       ram_assign.v
//Usage:        get the data from the memory based on the address

module ram_assign #(
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


//************************************ sequential logic
always @(posedge clk) begin
    if(write_en) begin
        memory[write_addr] <= write_data;
    end
end

assign read_data = memory[read_addr];
    
endmodule

