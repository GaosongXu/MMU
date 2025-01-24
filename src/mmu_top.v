//! @title mmu_top
//! @author gsxu

//!The module is the top of mmu, offer the interface to the user.
//!The real mmu module can be replaced with dummy mmu first

`include "src/mmu_param.vh"
`include "src/sync_fifo.v"
module mmu_top (
    clk,
    rst_n,
    //input
    alloc_req_submit,
    alloc_req_id,
    alloc_req_page_count,

    free_req_submit,
    free_req_id,
    free_req_page_idx,
    free_req_page_count,

    alloc_rsp_pop,
    free_rsp_pop,

    //output
    alloc_rsp_id,
    alloc_rsp_page_idx,
    alloc_rsp_fail,
    alloc_rsp_fail_reason,
    free_rsp_id,
    free_rsp_fail,
    free_rsp_fail_reason,

    alloc_req_fifo_full,
    free_req_fifo_full,

    alloc_rsp_fifo_not_empty,
    free_rsp_fifo_not_empty
);

input clk;
input rst_n;

input alloc_req_submit; //!submit a alloc request
input [`REQ_ID_WIDTH-1:0] alloc_req_id; //!13bit request id
input [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_req_page_count; //!the page count of the request,1/2/4/8 other value will be auto aligned, over 8 will fail 

input free_req_submit; //!submit a free request
input [`REQ_ID_WIDTH-1:0] free_req_id; //!13bit request id
input [`REQ_SIZE_TYPE_WIDTH-1:0] free_req_page_idx; //!the page index of the request, 0~3276-1
input [`REQ_SIZE_TYPE_WIDTH-1:0] free_req_page_count; //!the page count of the request,1/2/4/8 other value will be auto aligned, over 8 will fail

input alloc_rsp_pop; //!pop a alloc response,the value will on the next cycle
input free_rsp_pop; //!pop a free response ,the value will on the next cycle

output [`REQ_ID_WIDTH-1:0] alloc_rsp_id; //!13 bit the response id
output [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_rsp_page_idx; //!the page index of the response, 0~3276-1
output alloc_rsp_fail;  //!if fail, then the value will be 1
output [`FAIL_REASON_WIDTH-1:0] alloc_rsp_fail_reason; //!the reason of the fail 

output [`REQ_ID_WIDTH-1:0] free_rsp_id; //!13 bit the response id
output free_rsp_fail; //!if fail, then the value will be 1
output [`FAIL_REASON_WIDTH-1:0] free_rsp_fail_reason; //!the reason of the fail

output alloc_req_fifo_full; //!if the alloc request fifo is full,dont submit the request
output free_req_fifo_full; //!if the free request fifo is full,dont submit the request

output alloc_rsp_fifo_not_empty; //!if the alloc response fifo is not empty,able to pop the response
output free_rsp_fifo_not_empty;  //!if the free response fifo is not empty,able to pop the response

//*******************************************************signals





//*******************************************************combinational logic




//*******************************************************sequential logic






//*******************************************************module instantiation







endmodule




