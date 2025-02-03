//!mmu tree module, connect all modules together, and export the ports to interface with the top module
//!we need a little bit logic here to solve the parrallel rsp write req

`include "src/mmu_param.vh"
`include "src/dispatcher.v"
`include "src/find_table.v"
`include "src/and_tree.v"
`include "src/or_tree.v"
`include "src/rsp_arbiter.v"

module mmu_tree (
    clk,
    rst_n,
    //input
    alloc_req_pop,
    alloc_req_id,
    alloc_req_page_count,
    alloc_fifo_empty,

    free_req_pop,
    free_req_id,
    free_req_page_idx,
    free_req_page_count,
    free_fifo_empty,
    free_fifo_data_count,

    alloc_rsp_write_en,
    alloc_rsp_id,
    alloc_rsp_page_idx,
    alloc_rsp_fail,
    alloc_rsp_fail_reason,
    alloc_rsp_fifo_almost_full,

    free_rsp_write_en,
    free_rsp_id,
    free_rsp_fail,
    free_rsp_fail_reason,
    free_rsp_fifo_almost_full
);

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
input [`FIFO_PTR_WIDTH:0] free_fifo_data_count;

output alloc_rsp_write_en;
output [`REQ_ID_WIDTH-1:0] alloc_rsp_id;
output [`ALL_PAGE_IDX_WIDTH-1:0] alloc_rsp_page_idx;    
output alloc_rsp_fail;
output [`FAIL_REASON_WIDTH-1:0] alloc_rsp_fail_reason;
input alloc_rsp_fifo_almost_full;

output free_rsp_write_en;
output [`REQ_ID_WIDTH-1:0] free_rsp_id;
output free_rsp_fail;
output [`FAIL_REASON_WIDTH-1:0] free_rsp_fail_reason;
input free_rsp_fifo_almost_full;

//dsp related ports
wire alloc_req_valid_fdt_out;
wire [`REQ_ID_WIDTH-1:0] alloc_req_id_fdt_out;
wire [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_req_size_fdt_out;
wire free_req_valid_or_tree_out;
wire [`REQ_ID_WIDTH-1:0] free_req_id_or_tree_out;
wire [`ALL_PAGE_IDX_WIDTH-1:0] free_req_page_idx_or_tree_out;
wire [`REQ_SIZE_TYPE_WIDTH-1:0] free_req_size_or_tree_out;
wire dsp_alloc_rsp_write_en;
wire [`REQ_ID_WIDTH-1:0] dsp_alloc_rsp_id;
wire [`ALL_PAGE_IDX_WIDTH-1:0] dsp_alloc_rsp_page_idx;
wire dsp_alloc_rsp_fail;
wire [`FAIL_REASON_WIDTH-1:0] dsp_alloc_rsp_fail_reason;
wire dsp_free_rsp_write_en;
wire [`REQ_ID_WIDTH-1:0] dsp_free_rsp_id;
wire dsp_free_rsp_fail;
wire [`FAIL_REASON_WIDTH-1:0] dsp_free_rsp_fail_reason;
wire fdt_blocked_fdt_in;

//fdt related ports
wire alloc_valid_at_out;
wire [`REQ_ID_WIDTH-1:0] alloc_id_at_out;
wire [`AT_TREE_INDEX_WIDTH-1:0] alloc_row_index_at_out;
wire [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_size_at_out;
wire fdt_update_valid_at_in;
wire [`FDT_INDEX_WIDTH-1:0] fdt_update_idx_at_in;
wire [`FDT_BIT_WIDTH-1:0] fdt_update_bit_sequence_at_in;

//at related ports
wire alloc_valid_ort_out;
wire [`REQ_ID_WIDTH-1:0] alloc_id_ort_out;
wire [`OR_TREE_INDEX_WIDTH-1:0] alloc_tree_index_ort_out;
wire [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_size_ort_out;
wire at_tree_update_en;
wire [`AT_TREE_INDEX_WIDTH-1:0] at_tree_update_column_idx;
wire [`AT_TREE_INDEX_WIDTH-1:0] at_tree_update_row_idx;
wire [`AT_TREE_BIT_WIDTH-1:0] at_tree_update_bit_sequence;

//ort related ports
wire ort_alloc_rsp_write_en;
wire [`REQ_ID_WIDTH-1:0] ort_alloc_rsp_id;
wire [`ALL_PAGE_IDX_WIDTH-1:0] ort_alloc_rsp_page_idx;    
wire ort_alloc_rsp_fail;
wire [`FAIL_REASON_WIDTH-1:0] ort_alloc_rsp_fail_reason;
wire ort_free_rsp_write_en;
wire [`REQ_ID_WIDTH-1:0] ort_free_rsp_id;
wire ort_free_rsp_fail;
wire [`FAIL_REASON_WIDTH-1:0] ort_free_rsp_fail_reason;


dispatcher  dispatcher_inst (
    .clk(clk),
    .rst_n(rst_n),
    .alloc_req_pop(alloc_req_pop),
    .alloc_req_id(alloc_req_id),
    .alloc_req_page_count(alloc_req_page_count),
    .alloc_fifo_empty(alloc_fifo_empty),
    .free_req_pop(free_req_pop),
    .free_req_id(free_req_id),
    .free_req_page_idx(free_req_page_idx),
    .free_req_page_count(free_req_page_count),
    .free_fifo_empty(free_fifo_empty),
    .free_fifo_data_count(free_fifo_data_count),
    .alloc_req_valid_fdt_out(alloc_req_valid_fdt_out),
    .alloc_req_id_fdt_out(alloc_req_id_fdt_out),
    .alloc_req_size_fdt_out(alloc_req_size_fdt_out),
    .free_req_valid_or_tree_out(free_req_valid_or_tree_out),
    .free_req_id_or_tree_out(free_req_id_or_tree_out),
    .free_req_page_idx_or_tree_out(free_req_page_idx_or_tree_out),
    .free_req_size_or_tree_out(free_req_size_or_tree_out),
    .alloc_rsp_write_en(dsp_alloc_rsp_write_en),
    .alloc_rsp_id(dsp_alloc_rsp_id),
    .alloc_rsp_page_idx(dsp_alloc_rsp_page_idx),
    .alloc_rsp_fail(dsp_alloc_rsp_fail),
    .alloc_rsp_fail_reason(dsp_alloc_rsp_fail_reason),
    .alloc_rsp_fifo_almost_full(alloc_rsp_fifo_almost_full),
    .free_rsp_write_en(dsp_free_rsp_write_en),
    .free_rsp_id(dsp_free_rsp_id),
    .free_rsp_fail(dsp_free_rsp_fail),
    .free_rsp_fail_reason(dsp_free_rsp_fail_reason),
    .free_rsp_fifo_almost_full(free_rsp_fifo_almost_full),
    .fdt_blocked_fdt_in(fdt_blocked_fdt_in)
  );



  find_table  find_table_inst (
    .clk(clk),
    .rst_n(rst_n),
    .alloc_valid_dsp_in(alloc_req_valid_fdt_out),
    .alloc_id_dsp_in(alloc_req_id_fdt_out),
    .alloc_size_dsp_in(alloc_req_size_fdt_out),
    .alloc_valid_at_out(alloc_valid_at_out),
    .alloc_id_at_out(alloc_id_at_out),
    .alloc_row_index_at_out(alloc_row_index_at_out),
    .alloc_size_at_out(alloc_size_at_out),
    .fdt_update_valid_at_in(fdt_update_valid_at_in),
    .fdt_update_idx_at_in(fdt_update_idx_at_in),
    .fdt_update_bit_sequence_at_in(fdt_update_bit_sequence_at_in),
    .fdt_blocked(fdt_blocked_fdt_in)
  );


  and_tree  and_tree_inst (
    .clk(clk),
    .rst_n(rst_n),
    .alloc_valid_fdt_in(alloc_valid_at_out),
    .alloc_id_fdt_in(alloc_id_at_out),
    .alloc_pos_fdt_in(alloc_row_index_at_out),
    .alloc_size_fdt_in(alloc_size_at_out),
    .alloc_valid_ort_out(alloc_valid_ort_out),
    .alloc_id_ort_out(alloc_id_ort_out),
    .alloc_tree_index_ort_out(alloc_tree_index_ort_out),
    .alloc_size_ort_out(alloc_size_ort_out),
    .at_tree_update_en(at_tree_update_en),
    .at_tree_update_column_idx(at_tree_update_column_idx),
    .at_tree_update_row_idx(at_tree_update_row_idx),
    .at_tree_update_bit_sequence(at_tree_update_bit_sequence),
    .fdt_update_valid(fdt_update_valid_at_in),
    .fdt_update_idx(fdt_update_idx_at_in),
    .fdt_update_bit_sequence(fdt_update_bit_sequence_at_in)
  );

  or_tree  or_tree_inst (
    .clk(clk),
    .rst_n(rst_n),
    .alloc_valid(alloc_valid_ort_out),
    .alloc_id(alloc_id_ort_out),
    .alloc_tree_index(alloc_tree_index_ort_out),
    .alloc_size(alloc_size_ort_out),
    .free_valid(free_req_valid_or_tree_out),
    .free_id(free_req_id_or_tree_out),
    .free_page_index(free_req_page_idx_or_tree_out),
    .free_size(free_req_size_or_tree_out),
    .at_tree_update_en(at_tree_update_en),
    .at_tree_update_column_idx(at_tree_update_column_idx),
    .at_tree_update_row_idx(at_tree_update_row_idx),
    .at_tree_update_bit_sequence(at_tree_update_bit_sequence),
    .alloc_rsp_write_en(ort_alloc_rsp_write_en),
    .alloc_rsp_id(ort_alloc_rsp_id),
    .alloc_rsp_page_idx(ort_alloc_rsp_page_idx),
    .alloc_rsp_fail(ort_alloc_rsp_fail),
    .alloc_rsp_fail_reason(ort_alloc_rsp_fail_reason),
    .free_rsp_write_en(ort_free_rsp_write_en),
    .free_rsp_id(ort_free_rsp_id),
    .free_rsp_fail(ort_free_rsp_fail),
    .free_rsp_fail_reason(ort_free_rsp_fail_reason)
  );

  rsp_arbiter # (
    .RSP_WIDTH(`REQ_ID_WIDTH+`FAIL_REASON_WIDTH+1)
  )
  free_rsp_arbiter_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rsp_write_en_1(ort_free_rsp_write_en),
    .rsp_data_1({ort_free_rsp_fail_reason,ort_free_rsp_fail,ort_free_rsp_id}),
    .rsp_write_en_2(dsp_free_rsp_write_en),
    .rsp_data_2({dsp_free_rsp_fail_reason,dsp_free_rsp_fail,dsp_free_rsp_id}),
    .rsp_write_en(free_rsp_write_en),
    .rsp_data({free_rsp_fail_reason,free_rsp_fail,free_rsp_id})
  );

  rsp_arbiter # (
    .RSP_WIDTH (`REQ_ID_WIDTH+`ALL_PAGE_IDX_WIDTH+`FAIL_REASON_WIDTH+1)
  )
  alloc_rsp_arbiter_inst (
    .clk(clk),
    .rst_n(rst_n),
    .rsp_write_en_1(ort_alloc_rsp_write_en),
    .rsp_data_1({ort_alloc_rsp_fail_reason,ort_alloc_rsp_fail,ort_alloc_rsp_page_idx,ort_alloc_rsp_id}),
    .rsp_write_en_2(dsp_alloc_rsp_write_en),
    .rsp_data_2({dsp_alloc_rsp_fail_reason,dsp_alloc_rsp_fail,dsp_alloc_rsp_page_idx,dsp_alloc_rsp_id}),
    .rsp_write_en(alloc_rsp_write_en),
    .rsp_data({alloc_rsp_fail_reason,alloc_rsp_fail,alloc_rsp_page_idx,alloc_rsp_id})
  );


endmodule