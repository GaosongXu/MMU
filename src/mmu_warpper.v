`include "../src/mmu_top.v"
module mmu_wapper(
    clk,
    rst_n
);
input clk;
input rst_n;

wire alloc_req_submit; //!submit a alloc request, make sure the submit signal is high with the request content
wire [`REQ_ID_WIDTH-1:0] alloc_req_id; //!13bit request id
wire [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_req_page_count; //!the page count of the request,1/2/4/8 other value will be auto aligned, over 8 will fail 
wire free_req_submit; //!submit a free request,make sure the submit signal is high with the request content
wire [`REQ_ID_WIDTH-1:0] free_req_id; //!13bit request id
wire [`ALL_PAGE_IDX_WIDTH-1:0] free_req_page_idx; //!15 bit the page index of the request, 0~3276-1
wire [`REQ_SIZE_TYPE_WIDTH-1:0] free_req_page_count; //!the page count of the request,1/2/4/8 other value will be auto aligned, over 8 will fail
wire alloc_rsp_pop; //!pop a alloc response,the value will on the next cycle
wire free_rsp_pop; //!pop a free response ,the value will on the next cycle
wire [`REQ_ID_WIDTH-1:0] alloc_rsp_id; //!13 bit the response id
wire [`ALL_PAGE_IDX_WIDTH-1:0] alloc_rsp_page_idx; //!15 bit the page index of the response, 0~3276-1
wire alloc_rsp_fail;  //!if fail, then the value will be 1
wire [`FAIL_REASON_WIDTH-1:0] alloc_rsp_fail_reason; //!the reason of the fail 
wire [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_rsp_origin_size; //!the origin size of the request
wire [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_rsp_actual_size; //!the actual size of the request
wire [`REQ_ID_WIDTH-1:0] free_rsp_id; //!13 bit the response id
wire free_rsp_fail; //!if fail, then the value will be 1
wire [`FAIL_REASON_WIDTH-1:0] free_rsp_fail_reason; //!the reason of the fail
wire [`REQ_SIZE_TYPE_WIDTH-1:0] free_rsp_origin_size; //!the origin size of the request
wire [`REQ_SIZE_TYPE_WIDTH-1:0] free_rsp_actual_size; //!the actual size of the request
wire alloc_req_fifo_full; //!if the alloc request fifo is full,dont submit the request
wire free_req_fifo_full; //!if the free request fifo is full,dont submit the request
wire alloc_rsp_fifo_not_empty; //!if the alloc response fifo is not empty,able to pop the response
wire free_rsp_fifo_not_empty;  //!if the free response fifo is not empty,able to pop the response


//assign all wire to 0
mmu_top top(
    .clk(clk),
    .rst_n(rst_n),
    //input
    .alloc_req_submit(alloc_req_submit),
    .alloc_req_id(alloc_req_id),
    .alloc_req_page_count(alloc_req_page_count),

    .free_req_submit(free_req_submit),
    .free_req_id(free_req_id),
    .free_req_page_idx(free_req_page_idx),
    .free_req_page_count(free_req_page_count),

    .alloc_rsp_pop(alloc_rsp_pop),
    .free_rsp_pop(free_rsp_pop),

    //output
    .alloc_rsp_id(alloc_rsp_id),
    .alloc_rsp_page_idx(alloc_rsp_page_idx),
    .alloc_rsp_fail(alloc_rsp_fail),
    .alloc_rsp_fail_reason(alloc_rsp_fail_reason),
    .alloc_rsp_origin_size(alloc_rsp_origin_size),
    .alloc_rsp_actual_size(alloc_rsp_actual_size),

    .free_rsp_id(free_rsp_id),
    .free_rsp_fail(free_rsp_fail),
    .free_rsp_fail_reason(free_rsp_fail_reason),
    .free_rsp_origin_size(free_rsp_origin_size),
    .free_rsp_actual_size(free_rsp_actual_size),

    .alloc_req_fifo_full(alloc_req_fifo_full),
    .free_req_fifo_full(free_req_fifo_full),

    .alloc_rsp_fifo_not_empty(alloc_rsp_fifo_not_empty),
    .free_rsp_fifo_not_empty(free_rsp_fifo_not_empty)
);


endmodule
    
