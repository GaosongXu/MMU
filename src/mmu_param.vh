`define MMU_FIFO_MODE 1 
// `define MMU_TREE_MODE 1 


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
`define FREE_FAIL_REASON_FREE_OTHER 2
`define FREE_FAIL_REASON_UNKNOWN_INTERNAL_ERROR 3


//all page idx
`define ALL_PAGE_IDX_WIDTH  15 //0~32768-1

//request related
`define REQ_ID_WIDTH 13
`define REQ_SIZE_TYPE_WIDTH 4
`define REQ_ALLOC_TYPE 0
`define REQ_FREE_TYPE 1
`define REQ_4K  0
`define REQ_2K  1
`define REQ_1K  2
`define REQ_512  3

//at tree related
`define AT_TREE_IDX 6
`define AT_TREE_COUNT 64
`define AT_TREE_BIT_SEQUENCE_WIDTH 4


//fifo related
`define FIFO_DEPTH 1024
`define FIFO_PTR_WIDTH 10