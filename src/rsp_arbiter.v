//!a common arbiter for the response write 
module rsp_arbiter #(
    parameter RSP_WIDTH = 32
) (
    clk,
    rst_n,
    rsp_write_en_1,
    rsp_data_1,
    rsp_write_en_2,
    rsp_data_2,
    rsp_write_en,
    rsp_data
);
//************************************ parameters
localparam RSP_FIRST = 2'd0;
localparam RSP_SECOND = 2'd1;

//************************************ ports
input clk;
input rst_n;
input rsp_write_en_1;
input [RSP_WIDTH-1:0] rsp_data_1;
input rsp_write_en_2;
input [RSP_WIDTH-1:0] rsp_data_2;
output rsp_write_en;
output [RSP_WIDTH-1:0] rsp_data;

reg rsp_write_en;
reg [RSP_WIDTH-1:0] rsp_data;
reg [1:0] state,state_next;
reg [RSP_WIDTH-1:0] rsp_data_buf, rsp_data_buf_next;

//************************************ combinational logic
always @(*) begin
    state_next = state;
    rsp_write_en = 0;
    rsp_data = 0;
    rsp_data_buf_next = rsp_data_buf;
    case(state)
        RSP_FIRST:begin
            if (rsp_write_en_1 || rsp_write_en_2)begin
                rsp_write_en = 1;
            end
            if(rsp_write_en_1)begin
                rsp_data = rsp_data_1;
                rsp_data_buf_next = rsp_data_2;
            end else if(rsp_write_en_2)begin
                rsp_data = rsp_data_2;
            end
            if(rsp_write_en_1 && rsp_write_en_2)begin
                state_next = RSP_SECOND; //write the second data
            end
        end
        RSP_SECOND:begin
            rsp_write_en = 1;
            rsp_data = rsp_data_buf;
            state_next = RSP_FIRST;
        end
        default:begin
            state_next = RSP_FIRST;
        end
    endcase 
end



//************************************ sequential logic
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        state <= RSP_FIRST;
        rsp_data_buf <= 0;
    end
    else begin
        state <= state_next;
        rsp_data_buf <= rsp_data_buf_next;
    end
end

endmodule
    