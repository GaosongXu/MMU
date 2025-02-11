//!connect to the fifo, and filter the invalid requests
//!do a dispatcher and control the switch between the alloc and free mode
//!it will maintain a fsm to control the dispatch logic
`include "../src/mmu_param.vh"
module dispatcher  #(
    parameter FREE_THRESHOLD = 128 //the threshold of the free fifo
)
(
    clk,
    rst_n,
    //1.alloc request fifo related 
    alloc_req_pop,
    alloc_req_id,
    alloc_req_page_count,
    alloc_fifo_empty,
    //2.free request fifo related
    free_req_pop,
    free_req_id,
    free_req_page_idx,
    free_req_page_count,
    free_fifo_empty,
    free_fifo_data_count,
    //3.alloc request out to fdt related
    alloc_req_valid_fdt_out,
    alloc_req_id_fdt_out,
    alloc_req_size_fdt_out, //aligned 0:4k,1:2m,2:1g 
    alloc_req_origin_size_fdt_out,//not aligned size
    //4.free request out to or_tree related
    free_req_valid_or_tree_out,
    free_req_id_or_tree_out,
    free_req_page_idx_or_tree_out,
    free_req_size_or_tree_out, //aligned 0:4k,1:2m,2:1g
    free_req_origin_size_or_tree_out,//not aligned size
    //5.rsp to alloc rsp fifo related
    alloc_rsp_write_en,
    alloc_rsp_id,
    alloc_rsp_page_idx,
    alloc_rsp_fail,
    alloc_rsp_fail_reason,
    alloc_rsp_origin_size,
    alloc_rsp_actual_size, //just zero in dispatcher out here
    alloc_rsp_fifo_almost_full,
    //6.rsp to free rsp fifo related
    free_rsp_write_en,
    free_rsp_id,
    free_rsp_fail,
    free_rsp_fail_reason,
    free_rsp_origin_size,
    free_rsp_actual_size, //just zero in dispatcher out here
    free_rsp_fifo_almost_full,
    //7.other input signals to get the mmu status,such as fdt_blocked, free_valid from or_tree
    fdt_blocked_fdt_in
);
//************************************ parameters
//we need 1 idle, 3 free state, 2 alloc state, 2 spin state, use one hot encoding
localparam  IDLE           = 4'd1;
localparam  FREE_FETCH_REQ = 4'd2;
localparam  FREE_CHECK_REQ = 4'd3;
localparam  FREE_WAIT_VALID= 4'd4;
localparam  ALLOC_FETCH_REQ= 4'd5;
localparam  ALLOC_CHECK_REQ= 4'd6;
localparam  ALLOC_NON_POP  = 4'd9;
localparam  ALLOC_WAIT_VALID = 4'd10;
localparam  SPIN_WAIT_1    = 4'd7;
localparam  SPIN_WAIT_2    = 4'd8;

localparam  FREE_WAIT_VALID_COUNT = 5;
localparam  ALLOC_WAIT_VALID_COUNT = 5;

//************************************ ports
input clk;
input rst_n;
//1.alloc request fifo related
output alloc_req_pop;
input [`REQ_ID_WIDTH-1:0] alloc_req_id;
input [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_req_page_count;
input alloc_fifo_empty;
//2.free request fifo related
output free_req_pop;
input [`REQ_ID_WIDTH-1:0] free_req_id;
input [`ALL_PAGE_IDX_WIDTH-1:0] free_req_page_idx;
input [`REQ_SIZE_TYPE_WIDTH-1:0] free_req_page_count;
input free_fifo_empty;
input [`FIFO_PTR_WIDTH:0] free_fifo_data_count; //tell the free request count
//3.alloc request out to fdt related
output alloc_req_valid_fdt_out;
output [`REQ_ID_WIDTH-1:0] alloc_req_id_fdt_out;
output [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_req_size_fdt_out; //aligned 0:4k,1:2m,2:1g
output [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_req_origin_size_fdt_out; //not aligned size
//4.free request out to or_tree related
output free_req_valid_or_tree_out;
output [`REQ_ID_WIDTH-1:0] free_req_id_or_tree_out;
output [`ALL_PAGE_IDX_WIDTH-1:0] free_req_page_idx_or_tree_out;
output [`REQ_SIZE_TYPE_WIDTH-1:0] free_req_size_or_tree_out; //aligned 0:4k,1:2m,2:1g
output [`REQ_SIZE_TYPE_WIDTH-1:0] free_req_origin_size_or_tree_out; //not aligned size
//5.rsp to alloc rsp fifo related
output alloc_rsp_write_en;
output [`REQ_ID_WIDTH-1:0] alloc_rsp_id;
output [`ALL_PAGE_IDX_WIDTH-1:0] alloc_rsp_page_idx;
output alloc_rsp_fail;
output [`FAIL_REASON_WIDTH-1:0] alloc_rsp_fail_reason;
output [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_rsp_origin_size;
output [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_rsp_actual_size; //just zero in dispatcher out here

input alloc_rsp_fifo_almost_full;
//6.rsp to free rsp fifo related
output free_rsp_write_en; //some one will handle the conflict, dont care the conflict
output [`REQ_ID_WIDTH-1:0] free_rsp_id;
output free_rsp_fail;
output [`FAIL_REASON_WIDTH-1:0] free_rsp_fail_reason;
output [`REQ_SIZE_TYPE_WIDTH-1:0] free_rsp_origin_size;
output [`REQ_SIZE_TYPE_WIDTH-1:0] free_rsp_actual_size; //just zero in dispatcher out here

input free_rsp_fifo_almost_full;
//7.other input signals to get the mmu status,such as fdt_blocked, free_valid from or_tree
input fdt_blocked_fdt_in;

//************************************ signals
reg alloc_req_pop;
reg free_req_pop;
reg alloc_req_valid_fdt_out, alloc_req_valid_fdt_out_next;
reg [`REQ_ID_WIDTH-1:0] alloc_req_id_fdt_out, alloc_req_id_fdt_out_next;
reg [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_req_size_fdt_out, alloc_req_size_fdt_out_next;
reg [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_req_origin_size_fdt_out, alloc_req_origin_size_fdt_out_next;
reg free_req_valid_or_tree_out, free_req_valid_or_tree_out_next;
reg [`REQ_ID_WIDTH-1:0] free_req_id_or_tree_out, free_req_id_or_tree_out_next;
reg [`ALL_PAGE_IDX_WIDTH-1:0] free_req_page_idx_or_tree_out, free_req_page_idx_or_tree_out_next;
reg [`REQ_SIZE_TYPE_WIDTH-1:0] free_req_size_or_tree_out, free_req_size_or_tree_out_next;
reg [`REQ_SIZE_TYPE_WIDTH-1:0] free_req_origin_size_or_tree_out, free_req_origin_size_or_tree_out_next;
reg alloc_rsp_write_en, alloc_rsp_write_en_next;
reg [`REQ_ID_WIDTH-1:0] alloc_rsp_id, alloc_rsp_id_next;
reg [`ALL_PAGE_IDX_WIDTH-1:0] alloc_rsp_page_idx, alloc_rsp_page_idx_next;
reg alloc_rsp_fail, alloc_rsp_fail_next;
reg [`FAIL_REASON_WIDTH-1:0] alloc_rsp_fail_reason, alloc_rsp_fail_reason_next;
reg [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_rsp_origin_size, alloc_rsp_origin_size_next;
reg [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_rsp_actual_size, alloc_rsp_actual_size_next;
reg free_rsp_write_en, free_rsp_write_en_next;
reg [`REQ_ID_WIDTH-1:0] free_rsp_id, free_rsp_id_next;
reg free_rsp_fail, free_rsp_fail_next;
reg [`FAIL_REASON_WIDTH-1:0] free_rsp_fail_reason, free_rsp_fail_reason_next;
reg [`REQ_SIZE_TYPE_WIDTH-1:0] free_rsp_origin_size, free_rsp_origin_size_next;
reg [`REQ_SIZE_TYPE_WIDTH-1:0] free_rsp_actual_size, free_rsp_actual_size_next;

reg [3:0] prev_state,state, state_next;

reg alloc_free_switch,alloc_free_switch_next;
reg free_alloc_switch,free_alloc_switch_next;
reg [2:0] free_waiting_count,free_waiting_count_next;
reg [2:0] alloc_waiting_count,alloc_waiting_count_next;
reg invalid_req_meet,invalid_req_meet_next;

//************************************ combinational logic
always @(*) begin
    state_next = state;
    alloc_free_switch_next = 0;
    free_alloc_switch_next = 0;
    free_req_pop = 0;
    free_rsp_write_en_next = 0;
    free_rsp_fail_next = 0;
    free_rsp_fail_reason_next = 0;
    free_rsp_origin_size_next = 0;
    free_rsp_actual_size_next = 0;
    free_rsp_id_next = 0;
    free_req_size_or_tree_out_next = free_req_size_or_tree_out; 
    free_req_origin_size_or_tree_out_next = free_req_origin_size_or_tree_out;
    free_req_id_or_tree_out_next = free_req_id_or_tree_out; 
    free_req_page_idx_or_tree_out_next = free_req_page_idx_or_tree_out; 
    free_req_valid_or_tree_out_next = 0;
    free_waiting_count_next = free_waiting_count;
    alloc_waiting_count_next = alloc_waiting_count;
    alloc_req_pop = 0;
    alloc_rsp_write_en_next = 0;
    alloc_rsp_fail_next = 0;
    alloc_rsp_fail_reason_next = 0;
    alloc_rsp_origin_size_next = 0;
    alloc_rsp_actual_size_next = 0;
    alloc_rsp_id_next = 0;
    alloc_req_size_fdt_out_next = alloc_req_size_fdt_out;
    alloc_req_origin_size_fdt_out_next = alloc_req_origin_size_fdt_out;
    alloc_req_id_fdt_out_next = alloc_req_id_fdt_out;
    alloc_req_valid_fdt_out_next = 0;
    invalid_req_meet_next = 0;

    case (state)
        IDLE:begin
            //in this state, we can not dispatch the request, just wait for the next round
            if ((alloc_fifo_empty && !fdt_blocked_fdt_in && free_fifo_empty) || (alloc_rsp_fifo_almost_full && free_rsp_fifo_almost_full)) begin
                state_next = SPIN_WAIT_1;
            end else if (prev_state == ALLOC_CHECK_REQ || prev_state == ALLOC_WAIT_VALID || prev_state == ALLOC_NON_POP)begin
                if (free_fifo_data_count >= FREE_THRESHOLD && !free_rsp_fifo_almost_full) begin
                    alloc_free_switch_next = 1;
                    state_next = FREE_FETCH_REQ;
                end else if ((fdt_blocked_fdt_in || alloc_fifo_empty|| alloc_rsp_fifo_almost_full ) && !free_fifo_empty && !free_rsp_fifo_almost_full) begin
                    alloc_free_switch_next = 1;
                    state_next = FREE_FETCH_REQ;
                end else begin
                    state_next = ALLOC_FETCH_REQ;
                end
            end else if (prev_state == FREE_CHECK_REQ || prev_state == FREE_WAIT_VALID)begin
                if (free_fifo_empty || free_rsp_fifo_almost_full) begin
                    free_alloc_switch_next = 1; //switch to alloc
                    state_next = ALLOC_FETCH_REQ;
                end else begin
                    state_next = FREE_FETCH_REQ;
                end
            end else if((!alloc_fifo_empty||fdt_blocked_fdt_in) && !alloc_rsp_fifo_almost_full)begin
                state_next = ALLOC_FETCH_REQ;
            end else if(!free_fifo_empty && !free_rsp_fifo_almost_full)begin
                state_next = FREE_FETCH_REQ;
            end else begin
                state_next = SPIN_WAIT_1;
            end
        end
        FREE_FETCH_REQ:begin
            alloc_free_switch_next = alloc_free_switch; //keep the switch
            free_req_pop = 1;            //make sure current free_fifo not empty and free_rsp_fifo not full
            state_next = FREE_CHECK_REQ;
        end
        FREE_CHECK_REQ:begin
            //1. check the size
            if (free_req_page_count > 8 || free_req_page_count == 0) begin
                free_rsp_write_en_next = 1;
                free_rsp_fail_next = 1;
                free_rsp_fail_reason_next = free_req_page_count ==0 ? `FREE_FAIL_REASON_EQUAL_ZERO : `FREE_FAIL_REASON_OVER_4KB;
                free_rsp_origin_size_next = free_req_page_count;
                free_rsp_actual_size_next = 0;
                free_rsp_id_next = free_req_id;
                invalid_req_meet_next = 1;
            end else begin
                //2. aligned the page size
                case (free_req_page_count)
                    1:free_req_size_or_tree_out_next = `REQ_512;
                    2:free_req_size_or_tree_out_next = `REQ_1K;
                    3:free_req_size_or_tree_out_next = `REQ_2K;
                    4:free_req_size_or_tree_out_next = `REQ_2K;
                    5:free_req_size_or_tree_out_next = `REQ_4K;
                    6:free_req_size_or_tree_out_next = `REQ_4K;
                    7:free_req_size_or_tree_out_next = `REQ_4K;
                    8:free_req_size_or_tree_out_next = `REQ_4K;
                endcase
                free_req_id_or_tree_out_next = free_req_id;
                free_req_page_idx_or_tree_out_next = free_req_page_idx;
                free_req_origin_size_or_tree_out_next = free_req_page_count;
                //if dont need switch , just start
                if (!alloc_free_switch) begin
                    free_req_valid_or_tree_out_next = 1;
                end 
            end
            if (alloc_free_switch) begin
                state_next = FREE_WAIT_VALID;
            end else begin
                state_next = IDLE;
            end
        end
        FREE_WAIT_VALID:begin
            //wait for a counter here, if counter equal 5,change to idle,and reset the counter
            //make free_req_valid_or_tree_out_next high
            free_waiting_count_next = free_waiting_count + 1;
            invalid_req_meet_next = invalid_req_meet;
            if (free_waiting_count == FREE_WAIT_VALID_COUNT) begin
                if (invalid_req_meet) begin
                    free_req_valid_or_tree_out_next = 0;
                end else begin
                    free_req_valid_or_tree_out_next = 1;
                end
                free_waiting_count_next = 0;
                state_next = IDLE;
            end else begin
                state_next = FREE_WAIT_VALID;
            end
        end
        ALLOC_FETCH_REQ:begin
            //we can pop new only we not block and the alloc fifo not empty
            free_alloc_switch_next = free_alloc_switch; //keep the switch
            if(!fdt_blocked_fdt_in && !alloc_fifo_empty && !alloc_rsp_fifo_almost_full) begin
                alloc_req_pop = 1;
                state_next = ALLOC_CHECK_REQ;
            end else begin
                if(!fdt_blocked_fdt_in)begin //only fdt block in ,we can redispatch the request
                    invalid_req_meet_next = 1;
                end
                state_next = ALLOC_NON_POP;
            end
        end
        ALLOC_NON_POP:begin 
            invalid_req_meet_next = invalid_req_meet;//keep it
            if (fdt_blocked_fdt_in && !free_alloc_switch) begin
                alloc_req_valid_fdt_out_next = 1;
            end 
            if (free_alloc_switch) begin
                state_next = ALLOC_WAIT_VALID;//in here may be fdt_blocked_fdt_in or alloc_rsp_fifo_almost_full
            end else begin
                state_next = IDLE;
            end
        end
        ALLOC_CHECK_REQ:begin
            if (alloc_req_page_count > 8 || alloc_req_page_count == 0) begin
                alloc_rsp_write_en_next = 1;
                alloc_rsp_fail_next = 1;
                alloc_rsp_fail_reason_next = alloc_req_page_count ==0 ? `ALLOC_FAIL_REASON_EQUAL_ZERO : `ALLOC_FAIL_REASON_OVER_4KB;
                alloc_rsp_origin_size_next = alloc_req_page_count;
                alloc_rsp_actual_size_next = 0;
                alloc_rsp_id_next = alloc_req_id;
                invalid_req_meet_next = 1;
            end else begin
                //2. aligned the page size
                case (alloc_req_page_count)
                    1:alloc_req_size_fdt_out_next = `REQ_512;
                    2:alloc_req_size_fdt_out_next = `REQ_1K;
                    3:alloc_req_size_fdt_out_next = `REQ_2K;
                    4:alloc_req_size_fdt_out_next = `REQ_2K;
                    5:alloc_req_size_fdt_out_next = `REQ_4K;
                    6:alloc_req_size_fdt_out_next = `REQ_4K;
                    7:alloc_req_size_fdt_out_next = `REQ_4K;
                    8:alloc_req_size_fdt_out_next = `REQ_4K;
                endcase
                alloc_req_id_fdt_out_next = alloc_req_id;
                alloc_req_origin_size_fdt_out_next = alloc_req_page_count;
                if(!free_alloc_switch) begin
                    alloc_req_valid_fdt_out_next = 1;
                end
            end            
            if (free_alloc_switch) begin
                state_next = ALLOC_WAIT_VALID;
            end else begin
                state_next = IDLE;
            end
        end
        ALLOC_WAIT_VALID:begin
            alloc_waiting_count_next =  alloc_waiting_count + 1;
            invalid_req_meet_next = invalid_req_meet;
            if ( alloc_waiting_count == ALLOC_WAIT_VALID_COUNT) begin
                if (invalid_req_meet) begin
                    alloc_req_valid_fdt_out_next = 0;
                end else begin //from check_req or fdt block in
                    alloc_req_valid_fdt_out_next = 1;  
                end
                alloc_waiting_count_next = 0;
                state_next = IDLE;
            end else begin
                state_next = ALLOC_WAIT_VALID;
            end
        end
        SPIN_WAIT_1:begin
            state_next = SPIN_WAIT_2; //just gap one cycle
        end
        SPIN_WAIT_2:begin
            state_next = IDLE; 
        end
        default:begin
           state_next = IDLE; //impossible to reach here
        end
    endcase    
end



//************************************ sequential block
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        alloc_req_valid_fdt_out <= 0;
        alloc_req_id_fdt_out <= 0;
        alloc_req_size_fdt_out <= 0;
        alloc_req_origin_size_fdt_out <= 0;
        free_req_valid_or_tree_out <= 0;
        free_req_id_or_tree_out <= 0;
        free_req_page_idx_or_tree_out <= 0;
        free_req_size_or_tree_out <= 0;
        free_req_origin_size_or_tree_out <= 0;
        alloc_rsp_write_en <= 0;
        alloc_rsp_id <= 0;
        alloc_rsp_page_idx <= 0;
        alloc_rsp_fail <= 0;
        alloc_rsp_fail_reason <= 0;
        alloc_rsp_origin_size <= 0;
        alloc_rsp_actual_size <= 0;
        free_rsp_write_en <= 0;
        free_rsp_id <= 0;
        free_rsp_fail <= 0;
        free_rsp_fail_reason <= 0;
        free_rsp_origin_size <= 0;
        free_rsp_actual_size <= 0;
        state <= IDLE;
        prev_state <= IDLE;
        alloc_free_switch <= 0;
        free_alloc_switch <= 0;
        free_waiting_count <= 0;
        alloc_waiting_count <= 0;
        invalid_req_meet <= 0;
    end else begin
        alloc_req_valid_fdt_out <= alloc_req_valid_fdt_out_next;
        alloc_req_id_fdt_out <= alloc_req_id_fdt_out_next;
        alloc_req_size_fdt_out <= alloc_req_size_fdt_out_next;
        alloc_req_origin_size_fdt_out <= alloc_req_origin_size_fdt_out_next;
        free_req_valid_or_tree_out <= free_req_valid_or_tree_out_next;
        free_req_id_or_tree_out <= free_req_id_or_tree_out_next;
        free_req_page_idx_or_tree_out <= free_req_page_idx_or_tree_out_next;
        free_req_size_or_tree_out <= free_req_size_or_tree_out_next;
        free_req_origin_size_or_tree_out <= free_req_origin_size_or_tree_out_next;
        alloc_rsp_write_en <= alloc_rsp_write_en_next;
        alloc_rsp_id <= alloc_rsp_id_next;
        alloc_rsp_page_idx <= alloc_rsp_page_idx_next;
        alloc_rsp_fail <= alloc_rsp_fail_next;
        alloc_rsp_fail_reason <= alloc_rsp_fail_reason_next;
        alloc_rsp_origin_size <= alloc_rsp_origin_size_next;
        alloc_rsp_actual_size <= alloc_rsp_actual_size_next;
        free_rsp_write_en <= free_rsp_write_en_next;
        free_rsp_id <= free_rsp_id_next;
        free_rsp_fail <= free_rsp_fail_next;
        free_rsp_fail_reason <= free_rsp_fail_reason_next;
        free_rsp_origin_size <= free_rsp_origin_size_next;
        free_rsp_actual_size <= free_rsp_actual_size_next;
        state <= state_next;
        prev_state <= state;
        alloc_free_switch <= alloc_free_switch_next;
        free_alloc_switch <= free_alloc_switch_next;
        free_waiting_count <= free_waiting_count_next;
        alloc_waiting_count <= alloc_waiting_count_next;
        invalid_req_meet <= invalid_req_meet_next;
    end
end

endmodule