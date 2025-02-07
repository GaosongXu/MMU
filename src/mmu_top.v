//! @title mmu_top
//! @author gsxu

//!The module is the top of mmu, offer the interface to the user.
//!The real mmu module can be replaced with dummy mmu first

`include "../src/mmu_tree.v"
`include "../src/sync_fifo.v"

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

input alloc_req_submit; //!submit a alloc request, make sure the submit signal is high with the request content
input [`REQ_ID_WIDTH-1:0] alloc_req_id; //!13bit request id
input [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_req_page_count; //!the page count of the request,1/2/4/8 other value will be auto aligned, over 8 will fail 

input free_req_submit; //!submit a free request,make sure the submit signal is high with the request content
input [`REQ_ID_WIDTH-1:0] free_req_id; //!13bit request id
input [`ALL_PAGE_IDX_WIDTH-1:0] free_req_page_idx; //!15 bit the page index of the request, 0~3276-1
input [`REQ_SIZE_TYPE_WIDTH-1:0] free_req_page_count; //!the page count of the request,1/2/4/8 other value will be auto aligned, over 8 will fail

input alloc_rsp_pop; //!pop a alloc response,the value will on the next cycle
input free_rsp_pop; //!pop a free response ,the value will on the next cycle

output [`REQ_ID_WIDTH-1:0] alloc_rsp_id; //!13 bit the response id
output [`ALL_PAGE_IDX_WIDTH-1:0] alloc_rsp_page_idx; //!15 bit the page index of the response, 0~3276-1
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
wire mmu_alloc_req_pop;
wire [`REQ_ID_WIDTH-1:0] mmu_alloc_req_id; 
wire [`REQ_SIZE_TYPE_WIDTH-1:0] mmu_alloc_req_page_count; 
wire mmu_alloc_fifo_empty; 

wire mmu_free_req_pop;
wire [`REQ_ID_WIDTH-1:0] mmu_free_req_id;
wire [`ALL_PAGE_IDX_WIDTH-1:0] mmu_free_req_page_idx; 
wire [`REQ_SIZE_TYPE_WIDTH-1:0] mmu_free_req_page_count; 
wire mmu_free_fifo_empty; 


wire mmu_alloc_rsp_write_en;
wire [`REQ_ID_WIDTH-1:0] mmu_alloc_rsp_id;
wire [`ALL_PAGE_IDX_WIDTH-1:0] mmu_alloc_rsp_page_idx;
wire mmu_alloc_rsp_fail;
wire [`FAIL_REASON_WIDTH-1:0] mmu_alloc_rsp_fail_reason;


wire mmu_free_rsp_write_en;
wire [`REQ_ID_WIDTH-1:0] mmu_free_rsp_id;
wire mmu_free_rsp_fail;
wire [`FAIL_REASON_WIDTH-1:0] mmu_free_rsp_fail_reason;

wire mmu_alloc_req_fifo_almost_full;
wire mmu_free_req_fifo_almost_full;
wire mmu_alloc_rsp_fifo_almost_full;
wire mmu_free_rsp_fifo_almost_full;
wire mmu_alloc_req_fifo_almost_empty;
wire mmu_free_req_fifo_almost_empty;
wire mmu_alloc_rsp_fifo_almost_empty;
wire mmu_free_rsp_fifo_almost_empty;

wire [`FIFO_PTR_WIDTH:0] mmu_free_req_fifo_data_count;
//*******************************************************module instantiation

//!the dummy mmu module
`ifdef MMU_FIFO_MODE
  mmu_dummy  mmu_dummy_inst (
      .clk(clk),
      .rst_n(rst_n),
      .alloc_req_pop(mmu_alloc_req_pop),
      .alloc_req_id(mmu_alloc_req_id),
      .alloc_req_page_count(mmu_alloc_req_page_count),
      .alloc_fifo_empty(mmu_alloc_fifo_empty),
      .free_req_pop(mmu_free_req_pop),
      .free_req_id(mmu_free_req_id),
      .free_req_page_idx(mmu_free_req_page_idx),
      .free_req_page_count(mmu_free_req_page_count),
      .free_fifo_empty(mmu_free_fifo_empty),
      .alloc_rsp_write_en(mmu_alloc_rsp_write_en),
      .alloc_rsp_id(mmu_alloc_rsp_id),
      .alloc_rsp_page_idx(mmu_alloc_rsp_page_idx),
      .alloc_rsp_fail(mmu_alloc_rsp_fail),
      .alloc_rsp_fail_reason(mmu_alloc_rsp_fail_reason),
      .free_rsp_write_en(mmu_free_rsp_write_en),
      .free_rsp_id(mmu_free_rsp_id),
      .free_rsp_fail(mmu_free_rsp_fail),
      .free_rsp_fail_reason(mmu_free_rsp_fail_reason)
    );
//!the real mmu module
`else
  mmu_tree  mmu_tree_inst (
      .clk(clk),
      .rst_n(rst_n),
      .alloc_req_pop(mmu_alloc_req_pop),
      .alloc_req_id(mmu_alloc_req_id),
      .alloc_req_page_count(mmu_alloc_req_page_count),
      .alloc_fifo_empty(mmu_alloc_fifo_empty),
      .free_req_pop(mmu_free_req_pop),
      .free_req_id(mmu_free_req_id),
      .free_req_page_idx(mmu_free_req_page_idx),
      .free_req_page_count(mmu_free_req_page_count),
      .free_fifo_empty(mmu_free_fifo_empty),
      .free_fifo_data_count(mmu_free_req_fifo_data_count),
      .alloc_rsp_write_en(mmu_alloc_rsp_write_en),
      .alloc_rsp_id(mmu_alloc_rsp_id),
      .alloc_rsp_page_idx(mmu_alloc_rsp_page_idx),
      .alloc_rsp_fail(mmu_alloc_rsp_fail),
      .alloc_rsp_fail_reason(mmu_alloc_rsp_fail_reason),
      .alloc_rsp_fifo_almost_full(mmu_alloc_rsp_fifo_almost_full),
      .free_rsp_write_en(mmu_free_rsp_write_en),
      .free_rsp_id(mmu_free_rsp_id),
      .free_rsp_fail(mmu_free_rsp_fail),
      .free_rsp_fail_reason(mmu_free_rsp_fail_reason),
      .free_rsp_fifo_almost_full(mmu_free_rsp_fifo_almost_full)
      );
`endif




//!the fifo for the alloc request 
 sync_fifo    #(
  .FIFO_PTR(`FIFO_PTR_WIDTH),
  .FIFO_WIDTH(`REQ_ID_WIDTH+`REQ_SIZE_TYPE_WIDTH),
  .FIFO_DEPTH(`FIFO_DEPTH)
 ) alloc_request_fifo 
 (
     .clk(clk),
     .rst_n(rst_n),
     .write_en(alloc_req_submit),
     .write_data({alloc_req_page_count,alloc_req_id}),
     .read_en(mmu_alloc_req_pop),
     .read_data({mmu_alloc_req_page_count,mmu_alloc_req_id}),
     .fifo_full(alloc_req_fifo_full),
     .fifo_empty(mmu_alloc_fifo_empty),//!for dispater
     .fifo_almost_full(mmu_alloc_req_fifo_almost_full),
     .fifo_almost_empty(mmu_alloc_req_fifo_almost_empty),
     .fifo_data_count(),
     .fifo_free_count()
   ); 

//!the fifo for the free request
  sync_fifo    #(
    .FIFO_PTR(`FIFO_PTR_WIDTH),
    .FIFO_WIDTH(`REQ_ID_WIDTH+`ALL_PAGE_IDX_WIDTH+`REQ_SIZE_TYPE_WIDTH),
    .FIFO_DEPTH(`FIFO_DEPTH)
  ) free_request_fifo 
   (
       .clk(clk),
       .rst_n(rst_n),
       .write_en(free_req_submit),
       .write_data({free_req_page_count,free_req_page_idx,free_req_id}),
       .read_en(mmu_free_req_pop),
       .read_data({mmu_free_req_page_count,mmu_free_req_page_idx,mmu_free_req_id}),
       .fifo_full(free_req_fifo_full),
       .fifo_empty(mmu_free_fifo_empty),//!for dispater
       .fifo_almost_full(mmu_free_req_fifo_almost_full),
       .fifo_almost_empty(mmu_free_req_fifo_almost_empty),
       .fifo_data_count(mmu_free_req_fifo_data_count),
       .fifo_free_count()
     ); 
   

wire  alloc_resp_fifo_empty;
assign alloc_rsp_fifo_not_empty = ~alloc_resp_fifo_empty;
//!the fifo for the alloc response
 sync_fifo    #(
   .FIFO_PTR(`FIFO_PTR_WIDTH),
   .FIFO_WIDTH(`REQ_ID_WIDTH+`ALL_PAGE_IDX_WIDTH+`FAIL_REASON_WIDTH+1),
   .FIFO_DEPTH(`FIFO_DEPTH)
 ) alloc_resp_fifo 
   (
       .clk(clk),
       .rst_n(rst_n),
       .write_en(mmu_alloc_rsp_write_en),
       .write_data({mmu_alloc_rsp_id,mmu_alloc_rsp_page_idx,mmu_alloc_rsp_fail_reason,mmu_alloc_rsp_fail}),
       .read_en(alloc_rsp_pop),
       .read_data({alloc_rsp_fail_reason,alloc_rsp_fail,alloc_rsp_page_idx,alloc_rsp_id}),
       .fifo_full(mmu_alloc_rsp_fifo_full),
       .fifo_empty(alloc_resp_fifo_empty),
       .fifo_almost_full(mmu_alloc_rsp_fifo_almost_full),
       .fifo_almost_empty(mmu_alloc_rsp_fifo_almost_empty),
       .fifo_data_count(),
       .fifo_free_count()
     ); 
       



  wire free_resp_fifo_empty;
  assign free_rsp_fifo_not_empty = ~free_resp_fifo_empty;
  //!the fifo for the free response
  sync_fifo    #(
    .FIFO_PTR(`FIFO_PTR_WIDTH),
    .FIFO_WIDTH(`REQ_ID_WIDTH+`FAIL_REASON_WIDTH+1),
    .FIFO_DEPTH(`FIFO_DEPTH)
  ) free_resp_fifo 
   (
       .clk(clk),
       .rst_n(rst_n),
       .write_en(mmu_free_rsp_write_en),
       .write_data({mmu_free_rsp_id,mmu_free_rsp_fail_reason,mmu_free_rsp_fail}),
       .read_en(free_rsp_pop),
       .read_data({free_rsp_fail_reason,free_rsp_fail,free_rsp_id}),
       .fifo_full(mmu_free_rsp_fifo_full),
       .fifo_empty(free_resp_fifo_empty),
       .fifo_almost_full(mmu_free_rsp_fifo_almost_full),
       .fifo_almost_empty(mmu_free_rsp_fifo_almost_empty),
       .fifo_data_count(),
       .fifo_free_count()
     ); 
   




endmodule




