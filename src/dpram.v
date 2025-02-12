//!Module：      ram_true_dual_port.v
//!Usage:        a simple sumulation of the ram_true_dual_port module
//!Introduction: The module will export 2 port , every port can handle read and write operation

module dpram#(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH =  6
    )(
        clk,
        wen_a,
        addr_a,
        data_a,
        q_a,
        wen_b,
        addr_b,
        data_b,
        q_b
    );
    input clk;
    
    input wen_a;
    input [ADDR_WIDTH-1:0] addr_a;
    input [DATA_WIDTH-1:0] data_a;
    output [DATA_WIDTH-1:0] q_a;
    
    input wen_b;
    input [ADDR_WIDTH-1:0] addr_b;
    input [DATA_WIDTH-1:0] data_b;
    output [DATA_WIDTH-1:0] q_b;

    reg [DATA_WIDTH-1:0] q_a;
    reg [DATA_WIDTH-1:0] q_b;

    (* ram_style = "block" *)
    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk) begin
        if(wen_a) begin
            memory[addr_a] <= data_a;
        end
        q_a <= memory[addr_a];
    end
    
    always @(posedge clk ) begin
        if(wen_b) begin
            memory[addr_b] <= data_b;
        end
        q_b <= memory[addr_b];
    end

endmodule


