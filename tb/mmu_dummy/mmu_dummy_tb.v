
`include "../../src/mmu_top.v"
`ifdef MMU_FIFO_MODE
module mmu_top_tb;

  // Parameters
  localparam MAX_4K_PAGE_COUNT = 4096;
  //Ports
  reg clk;
  reg rst_n;
  reg alloc_req_submit;
  reg [`REQ_ID_WIDTH-1:0] alloc_req_id;
  reg [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_req_page_count;
  reg free_req_submit;
  reg [`REQ_ID_WIDTH-1:0] free_req_id;
  reg [`ALL_PAGE_IDX_WIDTH-1:0] free_req_page_idx;
  reg [`REQ_SIZE_TYPE_WIDTH-1:0] free_req_page_count;
  reg alloc_rsp_pop;
  reg free_rsp_pop;
  wire [`REQ_ID_WIDTH-1:0] alloc_rsp_id;
  wire [`ALL_PAGE_IDX_WIDTH-1:0] alloc_rsp_page_idx;
  wire alloc_rsp_fail;
  wire [`FAIL_REASON_WIDTH-1:0] alloc_rsp_fail_reason;
  wire [`REQ_ID_WIDTH-1:0] free_rsp_id;
  wire free_rsp_fail;
  wire [`FAIL_REASON_WIDTH-1:0] free_rsp_fail_reason;
  wire alloc_req_fifo_full;
  wire free_req_fifo_full;
  wire alloc_rsp_fifo_not_empty;
  wire free_rsp_fifo_not_empty;



   // Clock generation , 250 MHz
    initial begin
         clk = 0;
         forever #2 clk = ~clk;
    end

    //generate reset
    initial begin
        rst_n = 0;
        #10;
        rst_n = 1;
    end
    
    //************************************ initial block
    integer j;
    integer i;
    initial begin
        #20;
        $display("mmu_dummy: fifo init begin");
        for (j=0; j<MAX_4K_PAGE_COUNT; j=j+1) begin
            mmu_top_inst.mmu_dummy_inst.page_stored_fifo.sdp_0.memory[j] = j;
        end
            mmu_top_inst.mmu_dummy_inst.page_stored_fifo.wr_ptr_next = MAX_4K_PAGE_COUNT-1;
            mmu_top_inst.mmu_dummy_inst.page_stored_fifo.wr_ptr = MAX_4K_PAGE_COUNT-1;
            mmu_top_inst.mmu_dummy_inst.page_stored_fifo.rd_ptr_next = 0;
            mmu_top_inst.mmu_dummy_inst.page_stored_fifo.rd_ptr = 0;
            mmu_top_inst.mmu_dummy_inst.page_stored_fifo.num_entries = MAX_4K_PAGE_COUNT;
            mmu_top_inst.mmu_dummy_inst.page_stored_fifo.num_entries_next = MAX_4K_PAGE_COUNT;
        $display("mmu_dummy: fifo init end");

        #80;
        //generate 1 alloc request and 1 free request
        //loop this for 10 times
        for(i=0; i<10; i=i+1) begin
            alloc_req_submit = 1;
            alloc_req_id = i;
            alloc_req_page_count = 1;
            #4;
            alloc_req_submit = 0;
        end
        for (i=0; i<10; i=i+1) begin
            free_req_submit = 1;
            free_req_id = i;
            free_req_page_idx = i<<3;
            free_req_page_count = 1;
            #4;
            free_req_submit = 0;
        end
    end

  mmu_top  mmu_top_inst (
    .clk(clk),
    .rst_n(rst_n),
    .alloc_req_submit(alloc_req_submit),
    .alloc_req_id(alloc_req_id),
    .alloc_req_page_count(alloc_req_page_count),
    .free_req_submit(free_req_submit),
    .free_req_id(free_req_id),
    .free_req_page_idx(free_req_page_idx),
    .free_req_page_count(free_req_page_count),
    .alloc_rsp_pop(alloc_rsp_pop),
    .free_rsp_pop(free_rsp_pop),
    .alloc_rsp_id(alloc_rsp_id),
    .alloc_rsp_page_idx(alloc_rsp_page_idx),
    .alloc_rsp_fail(alloc_rsp_fail),
    .alloc_rsp_fail_reason(alloc_rsp_fail_reason),
    .free_rsp_id(free_rsp_id),
    .free_rsp_fail(free_rsp_fail),
    .free_rsp_fail_reason(free_rsp_fail_reason),
    .alloc_req_fifo_full(alloc_req_fifo_full),
    .free_req_fifo_full(free_req_fifo_full),
    .alloc_rsp_fifo_not_empty(alloc_rsp_fifo_not_empty),
    .free_rsp_fifo_not_empty(free_rsp_fifo_not_empty)
  );

//always #5  clk = ! clk ;

endmodule
`endif