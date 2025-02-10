`ifndef MMU_PARAM_H
`define MMU_PARAM_H

// `define MMU_FIFO_MODE 1 
`define MMU_TREE_MODE 1 


//fdt related
`define FDT_ADDR_WIDTH  0
`define FDT_INDEX_WIDTH   6//64
`define FTD_DATA_WIDTH 64
`define FDT_BIT_WIDTH  4 //generate 4 bit


//at tree related
`define AT_TREE_INDEX_WIDTH  6 //64
`define AT_TREE_DATA_WIDTH 64
`define AT_TREE_BIT_WIDTH 4 //generate 4 bit , the at tree is 4 * 64 = 256 bit


//or tree related
`define OR_TREE_INDEX_WIDTH  12 //4096
`define OR_TREE_COUNT 4096
`define OR_TREE_BIT_WIDTH 15


//fail reason related
`define FAIL_REASON_WIDTH 2
`define ALLOC_FAIL_REASON_SUCCESS 0
`define ALLOC_FAIL_REASON_OVER_4KB 1
`define ALLOC_FAIL_REASON_EQUAL_ZERO 2
`define ALLOC_FAIL_REASON_UNKNOWN_INTERNAL_ERROR 3  
`define FREE_FAIL_REASON_SUCCESS 0  
`define FREE_FAIL_REASON_OVER_4KB 1
`define FREE_FAIL_REASON_EQUAL_ZERO 2
`define FREE_FAIL_REASON_FREE_OTHER 3


//all page idx
`define ALL_PAGE_IDX_WIDTH  15 //0~32768-1

//request related
`define REQ_ID_WIDTH 14
`define REQ_SIZE_TYPE_WIDTH 4
`define REQ_ALLOC_TYPE 0
`define REQ_FREE_TYPE 1
`define REQ_4K  8
`define REQ_2K  4
`define REQ_1K  2
`define REQ_512  1


//fifo related
`define FIFO_DEPTH 1024
`define FIFO_PTR_WIDTH 10

`endif