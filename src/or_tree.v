//!Module：      or_tree.v
//!Usage:        handle the request and update the or tree table
//!Introduction: The module is used to handle the alloc or free request and update the or tree table.
//              Then update the tree and pop the change to the and tree module.

`include "src/ram_3port.v"
`include "src/mmu_param.vh"

 module or_tree (
    clk,
    rst_n,
    alloc_valid,
    alloc_id,
    alloc_tree_index,
    alloc_size,

    free_valid,
    free_id,
    free_page_index,
    free_size,


    //output to the fifo
    alloc_fifo_push_en,
    alloc_fifo_push_req_id,
    alloc_fifo_push_page_idx,
    alloc_fifo_push_fail,
    alloc_fifo_push_reason,

    free_fifo_push_en,
    free_fifo_push_req_id,
    free_fifo_push_fail,
    free_fifo_push_reason,

    at_tree_update_en,
    at_tree_update_idx,
    at_tree_update_bit_sequence

);


//************************************ ports
input clk;
input rst_n;
input alloc_valid;
input [`REQ_ID_WIDTH-1:0] alloc_id;
input [`OR_TREE_INDEX_WIDTH-1:0] alloc_tree_index;
input [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_size;
input free_valid; 
input [`REQ_ID_WIDTH-1:0] free_id;
input [`FREE_PAGE_IDX_WIDTH-1:0] free_page_index;
input [`REQ_SIZE_TYPE_WIDTH-1:0] free_size;


output alloc_fifo_push_en;
output [`REQ_ID_WIDTH-1:0] alloc_fifo_push_req_id;
output [`FREE_PAGE_IDX_WIDTH-1:0] alloc_fifo_push_page_idx;
output alloc_fifo_push_fail;
output [`FAIL_REASON_WIDTH-1:0] alloc_fifo_push_reason;

output free_fifo_push_en;
output [`REQ_ID_WIDTH-1:0] free_fifo_push_req_id;
output free_fifo_push_fail;
output [`FAIL_REASON_WIDTH-1:0] free_fifo_push_reason;

output at_tree_update_en;
output [`OR_TREE_INDEX_WIDTH-1:0] at_tree_update_idx;
output [`OR_TREE_BIT_WIDTH-1:0] at_tree_update_bit_sequence;


//************************************ signals
reg write_en;
reg [`OR_TREE_INDEX_WIDTH-1:0] write_addr;
reg [`OR_TREE_BIT_WIDTH-1:0] write_data;
reg [`OR_TREE_INDEX_WIDTH-1:0] read_addr1; //!alloc use this port
wire [`OR_TREE_BIT_WIDTH-1:0] read_data1;
reg [`OR_TREE_INDEX_WIDTH-1:0] read_addr2; //!free use this port
wire [`OR_TREE_BIT_WIDTH-1:0] read_data2;


//!store the idx of the tree node ,return the idx to the user
reg [2:0] alloc_page_idx_next,alloc_page_idx;
reg [2:0] free_tree_idx_next,free_tree_idx;
//!the error signal when we meet some error that wrong
reg alloc_error_meet_next,alloc_error_meet;
reg free_error_meet_next,free_error_meet;


reg alloc_write_en , alloc_write_en_next;
reg [`OR_TREE_BIT_WIDTH-1:0] alloc_write_data,alloc_write_data_next;
reg free_write_en,free_write_en_next;
reg [`OR_TREE_BIT_WIDTH-1:0] free_write_data,free_write_data_next;

reg alloc_valid_n1,alloc_valid_n2;
reg [`REQ_ID_WIDTH-1:0] alloc_id_n1,alloc_id_n2;
reg [`OR_TREE_INDEX_WIDTH-1:0] alloc_tree_index_n1,alloc_tree_index_n2;
reg [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_size_n1,alloc_size_n2;

reg free_valid_n1,free_valid_n2;
reg [`REQ_ID_WIDTH-1:0] free_id_n1,free_id_n2;
reg [`FREE_PAGE_IDX_WIDTH-1:0] free_page_index_n1,free_page_index_n2;
reg [`REQ_SIZE_TYPE_WIDTH-1:0] free_size_n1,free_size_n2;


reg alloc_fifo_push_en;
reg [`REQ_ID_WIDTH-1:0] alloc_fifo_push_req_id;
reg [`FREE_PAGE_IDX_WIDTH-1:0] alloc_fifo_push_page_idx;
reg alloc_fifo_push_fail;
reg [`FAIL_REASON_WIDTH-1:0] alloc_fifo_push_reason;

reg free_fifo_push_en;
reg [`REQ_ID_WIDTH-1:0] free_fifo_push_req_id;
reg free_fifo_push_fail;
reg [`FAIL_REASON_WIDTH-1:0] free_fifo_push_reason;

reg at_tree_update_en;
reg [`OR_TREE_INDEX_WIDTH-1:0] at_tree_update_idx;
reg [`OR_TREE_BIT_WIDTH-1:0] at_tree_update_bit_sequence;

reg alloc_fifo_push_en_next;
reg [`REQ_ID_WIDTH-1:0] alloc_fifo_push_req_id_next;
reg [`FREE_PAGE_IDX_WIDTH-1:0] alloc_fifo_push_page_idx_next;
reg alloc_fifo_push_fail_next;
reg [`FAIL_REASON_WIDTH-1:0] alloc_fifo_push_reason_next;

reg free_fifo_push_en_next;
reg [`REQ_ID_WIDTH-1:0] free_fifo_push_req_id_next;
reg free_fifo_push_fail_next;
reg [`FAIL_REASON_WIDTH-1:0] free_fifo_push_reason_next;

reg at_tree_update_en_next;
reg [`OR_TREE_INDEX_WIDTH-1:0] at_tree_update_idx_next;
reg [`OR_TREE_BIT_WIDTH-1:0] at_tree_update_bit_sequence_next;


wire [`OR_TREE_BIT_WIDTH-1:0] alloc_magic [`OR_TREE_BIT_WIDTH-1:0];
wire [`OR_TREE_BIT_WIDTH-1:0] free_magic [`OR_TREE_BIT_WIDTH-1:0];
wire full_4k;
wire full_2k_1;
wire full_2k_2;
wire full_1k_1;
wire full_1k_2;
wire full_1k_3;
wire full_1k_4;


//************************************ combinational logic
assign alloc_magic[0] = {1'b1,2'b11,4'b1111,8'b11111111};
assign alloc_magic[1] = {1'b1,2'b10,4'b1100,8'b11110000};
assign alloc_magic[2] = {1'b1,2'b01,4'b0011,8'b00001111};
assign alloc_magic[3] = {1'b1,2'b10,4'b1000,8'b11000000};
assign alloc_magic[4] = {1'b1,2'b10,4'b0100,8'b00110000};
assign alloc_magic[5] = {1'b1,2'b01,4'b0010,8'b00001100};
assign alloc_magic[6] = {1'b1,2'b01,4'b0001,8'b00000011};
assign alloc_magic[7] = {1'b1,2'b10,4'b1000,8'b10000000};
assign alloc_magic[8] = {1'b1,2'b10,4'b1000,8'b01000000};
assign alloc_magic[9] = {1'b1,2'b10,4'b0100,8'b00100000};
assign alloc_magic[10]= {1'b1,2'b10,4'b0100,8'b00010000};
assign alloc_magic[11]= {1'b1,2'b01,4'b0010,8'b00001000};
assign alloc_magic[12]= {1'b1,2'b01,4'b0010,8'b00000100};
assign alloc_magic[13]= {1'b1,2'b01,4'b0001,8'b00000010};
assign alloc_magic[14]= {1'b1,2'b01,4'b0001,8'b00000001};

assign free_magic[0]  = {1'b0,2'b00,4'b0000,8'b00000000};
assign free_magic[1]  = {1'b1,2'b01,4'b0011,8'b00001111};
assign free_magic[2]  = {1'b1,2'b10,4'b1100,8'b11110000};
assign free_magic[3]  = {1'b1,2'b11,4'b0111,8'b00111111};
assign free_magic[4]  = {1'b1,2'b11,4'b1011,8'b11001111};
assign free_magic[5]  = {1'b1,2'b11,4'b1101,8'b11110011};
assign free_magic[6]  = {1'b1,2'b11,4'b1110,8'b11111100};
assign free_magic[7]  = {1'b1,2'b11,4'b1111,8'b01111111};
assign free_magic[8]  = {1'b1,2'b11,4'b1111,8'b10111111};
assign free_magic[9]  = {1'b1,2'b11,4'b1111,8'b11011111};
assign free_magic[10] = {1'b1,2'b11,4'b1111,8'b11101111};
assign free_magic[11] = {1'b1,2'b11,4'b1111,8'b11110111};
assign free_magic[12] = {1'b1,2'b11,4'b1111,8'b11111011};
assign free_magic[13] = {1'b1,2'b11,4'b1111,8'b11111101};
assign free_magic[14] = {1'b1,2'b11,4'b1111,8'b11111110};


assign full_4k = read_data2[7:0] == 8'hff;
assign full_2k_1 = read_data2[7:4] == 4'hf;
assign full_2k_2 = read_data2[3:0] == 4'hf;
assign full_1k_1 = read_data2[7:6] == 2'h3;
assign full_1k_2 = read_data2[5:4] == 2'h3;
assign full_1k_3 = read_data2[3:2] == 2'h3;
assign full_1k_4 = read_data2[1:0] == 2'h3;




//!generate the alloc read request
always @(*) begin
    read_addr1 = 0;
    if(alloc_valid) begin
        read_addr1 = alloc_tree_index;
    end
end

//!generate the free read request
always @(*) begin
    read_addr2 = 0;
    if(free_valid) begin
        read_addr2 = free_page_index >> 3;
    end
end


//!next cycle 
always @(*) begin
    alloc_write_en_next = 1'b0;
    alloc_write_data_next = 0;
    alloc_error_meet_next = 1'b0;
    alloc_page_idx_next = 3'b0;
    if (alloc_valid_n1) begin
        case (alloc_size_n1)
        `REQ_4K:begin
            case (read_data1[15])
                1'b0: alloc_page_idx_next = 3'h0;
                default: alloc_error_meet_next = 1'b1;
            endcase                
            end
            `REQ_2K:begin
             casez(read_data1[13:12])
                2'b0?: alloc_page_idx_next = 3'h0;
                2'b?0: alloc_page_idx_next = 3'h4;
             default: alloc_error_meet_next = 1'b1;
            endcase
        end 
        `REQ_1K:begin 
            casez (read_data1[11:8])
                4'b0??? : alloc_page_idx_next = 3'h0;
                4'b?0?? : alloc_page_idx_next = 3'h2;
                4'b??0? : alloc_page_idx_next = 3'h4;
                4'b???0 : alloc_page_idx_next = 3'h6;         
            default: alloc_error_meet_next = 1'b1;
            endcase
        end 
        `REQ_512:begin
            casez (read_data1[7:0])
                8'b0??????? : alloc_page_idx_next = 3'h0; 
                8'b?0?????? : alloc_page_idx_next = 3'h1; 
                8'b??0????? : alloc_page_idx_next = 3'h2;
                8'b???0???? : alloc_page_idx_next = 3'h3;
                8'b????0??? : alloc_page_idx_next = 3'h4;
                8'b?????0?? : alloc_page_idx_next = 3'h5;
                8'b??????0? : alloc_page_idx_next = 3'h6;
                8'b???????0 : alloc_page_idx_next = 3'h7;
            default: alloc_error_meet_next = 1'b1;
            endcase
        end
        endcase
        if (alloc_error_meet_next == 1'b0) begin
            alloc_write_en_next = 1'b1;
            alloc_write_data_next = alloc_magic[alloc_page_idx_next] | read_data1;
        end 
    end
end
 




//!the free logic just read the data ,and check the postion to free is valid
//!how can we check the postion is valid?
//!1.the postion is used,and the size we want to free is also used
always @(*) begin
    free_write_en_next = 1'b0;
    free_write_data_next = 0;
    free_error_meet_next = 1'b0;
    free_tree_idx_next = free_page_index_n1[2:0];
    if (free_valid_n1) begin
       case (free_size_n1)
       `REQ_4K:begin
           if (free_tree_idx_next == 3'b0 && full_4k) begin
               free_error_meet_next = 1'b0;
           end else begin
               free_error_meet_next = 1'b1;
           end
       end
       `REQ_2K :begin
            case (free_tree_idx_next)
                3'b000: free_error_meet_next = ~full_2k_1;
                3'b100: free_error_meet_next = ~full_2k_2;
                default: free_error_meet_next = 1'b1;
            endcase
       end
       `REQ_1K:
            case (free_tree_idx_next)
                3'b000: free_error_meet_next = ~full_1k_1;
                3'b010: free_error_meet_next = ~full_1k_2;
                3'b100: free_error_meet_next = ~full_1k_3;
                3'b110: free_error_meet_next = ~full_1k_4;
                default: free_error_meet_next = 1'b1;
            endcase
       `REQ_512:
            case (free_tree_idx_next) //no default
                3'h0: free_error_meet_next = ~read_data2[7];
                3'h1: free_error_meet_next = ~read_data2[6];
                3'h2: free_error_meet_next = ~read_data2[5];
                3'h3: free_error_meet_next = ~read_data2[4];
                3'h4: free_error_meet_next = ~read_data2[3];
                3'h5: free_error_meet_next = ~read_data2[2];
                3'h6: free_error_meet_next = ~read_data2[1];
                3'h7: free_error_meet_next = ~read_data2[0];
                default: free_error_meet_next = 1'b1;
            endcase
       endcase
        if(!free_error_meet_next)begin
            free_write_en_next = 1'b1;
            free_write_data_next = free_magic[free_tree_idx_next] & read_data2;
        end
    end
end

//!in the third clk cycle,write the ram, the alloc and free must not in the same clk cycle
always @(*) begin
    write_en = 1'b0;
    write_addr = 0;
    write_data = 0;

    if(alloc_valid_n2 && !alloc_error_meet ) begin
        write_en = alloc_write_en;
        write_addr = alloc_tree_index;
        write_data = alloc_write_data;
    end else if(free_valid_n2 && !free_error_meet) begin
        write_en = free_write_en;
        write_addr = free_page_index_n2 >> 3;
        write_data = free_write_data;
    end

end

//in the third clk cycle,write the result to fifo
// always @(*)begin


// end


//in the third clk cycle, generate the update value to the and tree
// always @(*) begin
    
// end




//************************************ sequential logic
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        alloc_valid_n1 <= 1'b0;
        alloc_valid_n2 <= 1'b0;
        free_valid_n1 <= 1'b0;
        free_valid_n2 <= 1'b0;
        alloc_id_n1 <= 0;
        alloc_id_n2 <= 0;
        alloc_tree_index_n1 <= 0;
        alloc_tree_index_n2 <= 0;
        alloc_size_n1 <= 0;
        alloc_size_n2 <= 0;
        free_id_n1 <= 0;
        free_id_n2 <= 0;
        free_page_index_n1 <= 0;
        free_page_index_n2 <= 0;
        free_size_n1 <= 0;
        free_size_n2 <= 0;
    end else begin
        alloc_valid_n1 <= alloc_valid;
        alloc_valid_n2 <= alloc_valid_n1;
        free_valid_n1 <= free_valid;
        free_valid_n2 <= free_valid_n1;
        alloc_id_n1 <= alloc_id;
        alloc_id_n2 <= alloc_id_n1;
        alloc_tree_index_n1 <= alloc_tree_index;
        alloc_tree_index_n2 <= alloc_tree_index_n1;
        alloc_size_n1 <= alloc_size;
        alloc_size_n2 <= alloc_size_n1;
        free_id_n1 <= free_id;
        free_id_n2 <= free_id_n1;
        free_page_index_n1 <= free_page_index;
        free_page_index_n2 <= free_page_index_n1;
        free_size_n1 <= free_size;
        free_size_n2 <= free_size_n1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        alloc_page_idx <= 0;
        free_tree_idx <= 0;
        alloc_error_meet <= 1'b0;
        free_error_meet <= 1'b0;
        alloc_write_data <= 0;
        free_write_data <= 0;
        alloc_write_en <= 1'b0;
        free_write_en <= 1'b0;
    end else begin
        alloc_page_idx <= alloc_page_idx_next;
        free_tree_idx <= free_tree_idx_next;
        alloc_error_meet <= alloc_error_meet_next;
        free_error_meet <= free_error_meet_next;
        alloc_write_data <= alloc_write_data_next;
        free_write_data <= free_write_data_next;
        alloc_write_en <= alloc_write_en_next;
        free_write_en <= free_write_en_next;
    end
end


//************************************ module instantiation
ram_3port #(
    .ADDR_WIDTH(`OR_TREE_INDEX_WIDTH),
    .DATA_WIDTH(`OR_TREE_BIT_WIDTH)
) or_tree_ram (
    .clk(clk),
    .write_en(write_en),
    .write_addr(write_addr),
    .write_data(write_data),
    .read_addr1(read_addr1),
    .read_data1(read_data1),
    .read_addr2(read_addr2),
    .read_data2(read_data2) 
);

 endmodule