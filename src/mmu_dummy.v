//!The module is used to simulate a mmu module ,**only for testing**.
//!              The internal implementation is not the same as the real mmu module.
//!              it will use fifo to store the 4K page addr, so the address always
//!              be the 4K aligned.

`include "src/sync_fifo.v"
`include "src/mmu_param.vh"
module mmu_dummy 
#(
    parameter MAX_4K_PAGE_COUNT = 4096,  //!16MB
    parameter ADDR_WIDTH = 12, //!4K page addr,0~4095
    parameter FIFO_DATA_WIDTH = 12 //!1same as ADDR_WIDTH, be used to store the 4K page addr,0~4095
)
(
    clk,
    rst_n,
    alloc_req_pop,
    alloc_req_id,
    alloc_req_page_count,
    alloc_fifo_empty,
    free_req_pop,
    free_req_id,
    free_req_page_idx,
    free_req_page_count,
    free_fifo_empty,
    alloc_rsp_write_en,
    alloc_rsp_id,
    alloc_rsp_page_idx,
    alloc_rsp_fail,
    alloc_rsp_fail_reason,
    free_rsp_write_en,
    free_rsp_id,
    free_rsp_fail,
    free_rsp_fail_reason
);
//************************************ parameters
localparam IDLE = 4'd0;
localparam ALLOC_REQ = 4'd1;
localparam FREE_REQ = 4'd2;



//************************************ ports

input clk;
input rst_n;
output alloc_req_pop;
input [`REQ_ID_WIDTH-1:0] alloc_req_id;
input [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_req_page_count;
input alloc_fifo_empty;

output free_req_pop;
input [`REQ_ID_WIDTH-1:0] free_req_id;
input [`ALL_PAGE_IDX_WIDTH-1:0] free_req_page_idx;
input [`REQ_SIZE_TYPE_WIDTH-1:0] free_req_page_count;
input free_fifo_empty;

output alloc_rsp_write_en;
output [`REQ_ID_WIDTH-1:0] alloc_rsp_id;
output [`ALL_PAGE_IDX_WIDTH-1:0] alloc_rsp_page_idx;    
output alloc_rsp_fail;
output [`FAIL_REASON_WIDTH-1:0] alloc_rsp_fail_reason;

output free_rsp_write_en;
output [`REQ_ID_WIDTH-1:0] free_rsp_id;
output free_rsp_fail;
output [`FAIL_REASON_WIDTH-1:0] free_rsp_fail_reason;

//************************************ signals
wire page_stored_fifo_full;
wire page_stored_fifo_empty;
reg page_fifo_pop ;
reg page_fifo_push;
reg [FIFO_DATA_WIDTH-1:0] page_write_data;
wire [FIFO_DATA_WIDTH-1:0] page_read_data;


reg [3:0] mmu_state,mmu_state_next;

reg alloc_req_pop;
reg free_req_pop;
reg alloc_rsp_write_en, alloc_rsp_write_en_next;
reg [`REQ_ID_WIDTH-1:0] alloc_rsp_id, alloc_rsp_id_next;
reg [`ALL_PAGE_IDX_WIDTH-1:0] alloc_rsp_page_idx, alloc_rsp_page_idx_next;
reg alloc_rsp_fail, alloc_rsp_fail_next;
reg [`FAIL_REASON_WIDTH-1:0] alloc_rsp_fail_reason, alloc_rsp_fail_reason_next;
reg free_rsp_write_en, free_rsp_write_en_next;
reg [`REQ_ID_WIDTH-1:0] free_rsp_id, free_rsp_id_next;
reg free_rsp_fail, free_rsp_fail_next;
reg [`FAIL_REASON_WIDTH-1:0] free_rsp_fail_reason, free_rsp_fail_reason_next;


//build a state machine to get the request from 
//the alloc request fifo and free request fifo


//may be we need to follow the register out here
//but no need, only for simulation :)
//************************************ combinational logic
always @(*) begin
    alloc_req_pop = 0;
    free_req_pop = 0;
    page_fifo_pop = 0;
    page_fifo_push = 0;
    alloc_rsp_write_en_next = 0;
    alloc_rsp_id_next = 0;
    alloc_rsp_page_idx_next = 0;
    alloc_rsp_fail_next = 0;
    alloc_rsp_fail_reason_next = 0;
    free_rsp_write_en_next = 0;
    free_rsp_id_next = 0;
    free_rsp_fail_next = 0;
    free_rsp_fail_reason_next = 0;
    case(mmu_state)
        IDLE:begin
            if(!alloc_fifo_empty && !page_stored_fifo_empty)begin
                alloc_req_pop = 1;
                page_fifo_pop = 1;
                mmu_state_next = ALLOC_REQ;
            end
            else if(!free_fifo_empty && !page_stored_fifo_full)begin
                free_req_pop = 1;
                mmu_state_next = FREE_REQ;
            end
            else begin
                mmu_state_next = IDLE;
            end
        end
        ALLOC_REQ:begin
            //we now get the alloc id and page count from page fifo poped
            //build a response 
            alloc_rsp_write_en_next = 1;
            alloc_rsp_id_next = alloc_req_id;
            alloc_rsp_page_idx_next = {page_read_data,3'b000};
            alloc_rsp_fail_next = 0;
            alloc_rsp_fail_reason_next = 0;
            mmu_state_next = IDLE;
        end
        FREE_REQ:begin
            //we now get the free id and page idx from free fifo poped
            //build a response
            page_fifo_push = 1;
            page_write_data = free_req_page_idx[14:3]; //4k page idx
            free_rsp_write_en_next = 1; //write back in next cycle
            free_rsp_id_next = free_req_id;
            free_rsp_fail_next = 0;
            free_rsp_fail_reason_next = 0;
            mmu_state_next = IDLE;
        end
    endcase
end


//************************************ sequential logic

always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        mmu_state <= IDLE;
    end
    else begin
        mmu_state <= mmu_state_next;
    end
end


always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        alloc_rsp_write_en <= 0;
        alloc_rsp_id <= 0;
        alloc_rsp_page_idx <= 0;
        alloc_rsp_fail <= 0;
        alloc_rsp_fail_reason <= 0;
        free_rsp_write_en <= 0;
        free_rsp_id <= 0;
        free_rsp_fail <= 0;
        free_rsp_fail_reason <= 0;
    end else begin
        alloc_rsp_write_en <= alloc_rsp_write_en_next;
        alloc_rsp_id <= alloc_rsp_id_next;
        alloc_rsp_page_idx <= alloc_rsp_page_idx_next;
        alloc_rsp_fail <= alloc_rsp_fail_next;
        alloc_rsp_fail_reason <= alloc_rsp_fail_reason_next;
        free_rsp_write_en <= free_rsp_write_en_next;
        free_rsp_id <= free_rsp_id_next;
        free_rsp_fail <= free_rsp_fail_next;
        free_rsp_fail_reason <= free_rsp_fail_reason_next;
    end
end

//************************************ module instantiation

sync_fifo #(
    .FIFO_PTR(ADDR_WIDTH),
    .FIFO_WIDTH(FIFO_DATA_WIDTH),
    .FIFO_DEPTH(MAX_4K_PAGE_COUNT)
) page_stored_fifo
(
    .clk(clk),
    .write_en(page_fifo_push),
    .write_data(page_write_data),
    .read_en(page_fifo_pop),
    .read_data(page_read_data),
    .fifo_full(page_stored_fifo_full),
    .fifo_empty(page_stored_fifo_empty),
    .fifo_data_count(),
    .fifo_free_count()
);

endmodule