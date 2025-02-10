
//! the module handle the find request from fdt, and updated by the or_tree
//! then pop the update value to the fdt

`include "../src/ram_3port_dp.v"
`include "../src/mmu_param.vh"
`include "../src/first_zero.v"

module and_tree  (
    clk,
    rst_n,
    //for fdt search request input
    alloc_valid_fdt_in,
    alloc_id_fdt_in,
    alloc_pos_fdt_in, //the 64 bit line to read out
    alloc_size_fdt_in, //aligned size
    alloc_origin_size_fdt_in,
    //for fdt search result output
    alloc_valid_ort_out,
    alloc_id_ort_out,
    alloc_tree_index_ort_out,
    alloc_size_ort_out, 
    alloc_origin_size_ort_out,
    //for or_tree update request input
    at_tree_update_en,
    at_tree_update_column_idx,
    at_tree_update_row_idx,
    at_tree_update_bit_sequence,
    //for fdt update request output
    fdt_update_valid,
    fdt_update_idx,
    fdt_update_bit_sequence
); 
//************************************ ports
input clk;
input rst_n;
//for fdt search request input
input alloc_valid_fdt_in;
input [`REQ_ID_WIDTH-1:0] alloc_id_fdt_in;
input [`AT_TREE_INDEX_WIDTH-1:0] alloc_pos_fdt_in; //the 64 bit line to read out
input [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_size_fdt_in; //aligned size
input [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_origin_size_fdt_in;
//for fdt search result output
output alloc_valid_ort_out;
output [`REQ_ID_WIDTH-1:0] alloc_id_ort_out;
output [`OR_TREE_INDEX_WIDTH-1:0] alloc_tree_index_ort_out;
output [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_size_ort_out;
output [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_origin_size_ort_out;
//for or_tree update request input
input at_tree_update_en;
input [`AT_TREE_INDEX_WIDTH-1:0] at_tree_update_column_idx;
input [`AT_TREE_INDEX_WIDTH-1:0] at_tree_update_row_idx;
input [`AT_TREE_BIT_WIDTH-1:0] at_tree_update_bit_sequence;
//for fdt update request output
output fdt_update_valid;
output [`FDT_INDEX_WIDTH-1:0] fdt_update_idx;
output [`FDT_BIT_WIDTH-1:0] fdt_update_bit_sequence;

//************************************ signals
reg alloc_valid_fdt_in_n1, alloc_valid_fdt_in_n2, alloc_valid_fdt_in_n3;
reg [`REQ_ID_WIDTH-1:0] alloc_id_fdt_in_n1, alloc_id_fdt_in_n2, alloc_id_fdt_in_n3;
reg [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_size_fdt_in_n1, alloc_size_fdt_in_n2 ,alloc_size_fdt_in_n3;
reg [`AT_TREE_INDEX_WIDTH-1:0] alloc_pos_fdt_in_n1, alloc_pos_fdt_in_n2, alloc_pos_fdt_in_n3;
reg [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_origin_size_fdt_in_n1, alloc_origin_size_fdt_in_n2, alloc_origin_size_fdt_in_n3;

reg at_tree_update_en_n1, at_tree_update_en_n2, at_tree_update_en_n3;
reg [`AT_TREE_INDEX_WIDTH-1:0] at_tree_update_column_idx_n1;
reg [`AT_TREE_INDEX_WIDTH-1:0] at_tree_update_row_idx_n1, at_tree_update_row_idx_n2, at_tree_update_row_idx_n3;
reg [`AT_TREE_BIT_WIDTH-1:0] at_tree_update_bit_sequence_n1;

reg alloc_valid_ort_out;
reg [`REQ_ID_WIDTH-1:0] alloc_id_ort_out;
reg [`OR_TREE_INDEX_WIDTH-1:0] alloc_tree_index_ort_out;
reg [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_size_ort_out;
reg [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_origin_size_ort_out;

reg fdt_update_valid;
reg [`FDT_INDEX_WIDTH-1:0] fdt_update_idx;
reg [`FDT_BIT_WIDTH-1:0] fdt_update_bit_sequence , fdt_update_bit_sequence_next;

//! the write for update pop, the read1 for fdt search, the read2 for update pop
reg at_tree_512_write_en, at_tree_1k_write_en, at_tree_2k_write_en, at_tree_4k_write_en;
reg[`AT_TREE_INDEX_WIDTH-1:0] at_tree_512_write_addr, at_tree_1k_write_addr, at_tree_2k_write_addr, at_tree_4k_write_addr;
reg[`AT_TREE_DATA_WIDTH-1:0] at_tree_512_write_data, at_tree_1k_write_data, at_tree_2k_write_data, at_tree_4k_write_data;

reg[`AT_TREE_INDEX_WIDTH-1:0] at_tree_512_read_addr1, at_tree_1k_read_addr1, at_tree_2k_read_addr1, at_tree_4k_read_addr1;
wire[`AT_TREE_DATA_WIDTH-1:0] at_tree_512_read_data1, at_tree_1k_read_data1, at_tree_2k_read_data1, at_tree_4k_read_data1;

reg[`AT_TREE_INDEX_WIDTH-1:0] at_tree_512_read_addr2, at_tree_1k_read_addr2, at_tree_2k_read_addr2, at_tree_4k_read_addr2;
wire[`AT_TREE_DATA_WIDTH-1:0] at_tree_512_read_data2, at_tree_1k_read_data2, at_tree_2k_read_data2, at_tree_4k_read_data2;

reg [`AT_TREE_DATA_WIDTH-1:0] at_tree_512_read_out_next, at_tree_1k_read_out_next, at_tree_2k_read_out_next, at_tree_4k_read_out_next;
reg [`AT_TREE_DATA_WIDTH-1:0] at_tree_512_read_out, at_tree_1k_read_out, at_tree_2k_read_out, at_tree_4k_read_out;

reg[`AT_TREE_DATA_WIDTH-1:0] at_tree_64bit_line;//!a combinational signal to store the 64 bit line data read out
wire find_success; //!for debug ,must find in this stage
wire [6:0] pos_out;//!from 1~64,so need 7 bit, we use this to calculate the tree index

//************************************ combinational logic

//!combinational logic to generate the addr to read the tree, the data will out in the next cycle
always @(*) begin
    at_tree_512_read_addr1 = 0;
    at_tree_1k_read_addr1 = 0;
    at_tree_2k_read_addr1 = 0;
    at_tree_4k_read_addr1 = 0;
    if (alloc_valid_fdt_in)begin
       case(alloc_size_fdt_in)
        `REQ_512: begin
            at_tree_512_read_addr1 = alloc_pos_fdt_in;
        end
         `REQ_1K: begin
              at_tree_1k_read_addr1 = alloc_pos_fdt_in;
        end
         `REQ_2K: begin
              at_tree_2k_read_addr1 = alloc_pos_fdt_in;
        end
         `REQ_4K: begin
              at_tree_4k_read_addr1 = alloc_pos_fdt_in;
        end
       endcase 
    end
end


//!1rd cycle: combinational logic to generate the bit sequence to get the index
always @(*) begin
    at_tree_64bit_line = 0;
    if (alloc_valid_fdt_in_n1)begin
         case(alloc_size_fdt_in_n1)
          `REQ_512: begin
                at_tree_64bit_line = at_tree_512_read_data1;
          end
            `REQ_1K: begin
                  at_tree_64bit_line = at_tree_1k_read_data1;
          end
            `REQ_2K: begin
                  at_tree_64bit_line = at_tree_2k_read_data1;
          end
            `REQ_4K: begin
                  at_tree_64bit_line = at_tree_4k_read_data1;
          end
         endcase  
    end
end


//!3rd cycle: 
always @(*) begin
    alloc_tree_index_ort_out = 0;
    if (alloc_valid_fdt_in_n3)begin
        alloc_tree_index_ort_out = (alloc_pos_fdt_in_n3<<6) + pos_out - 1'b1;
    end
end

always @(*) begin
    alloc_valid_ort_out = alloc_valid_fdt_in_n3;
    alloc_id_ort_out = alloc_id_fdt_in_n3;
    alloc_size_ort_out = alloc_size_fdt_in_n3;
    alloc_origin_size_ort_out = alloc_origin_size_fdt_in_n3;
end


//handle the update request from or_tree
always @(*) begin
    at_tree_512_read_addr2 = 0;
    at_tree_1k_read_addr2 = 0;
    at_tree_2k_read_addr2 = 0;
    at_tree_4k_read_addr2 = 0;
    if(at_tree_update_en)begin
        at_tree_512_read_addr2 = at_tree_update_row_idx;
        at_tree_1k_read_addr2 = at_tree_update_row_idx;
        at_tree_2k_read_addr2 = at_tree_update_row_idx;
        at_tree_4k_read_addr2 = at_tree_update_row_idx;        
    end
end

//1rd cycle,read out the data ,and update the bit sequence, will  synthesize to a decoder
always @(*) begin
    at_tree_512_read_out_next = 0;
    if (at_tree_update_en_n1) begin
        at_tree_512_read_out_next = at_tree_512_read_data2;
        at_tree_512_read_out_next[at_tree_update_column_idx_n1] = at_tree_update_bit_sequence_n1[0];
    end
end

always @(*) begin
    at_tree_1k_read_out_next = 0;
    if (at_tree_update_en_n1) begin
        at_tree_1k_read_out_next = at_tree_1k_read_data2;
        at_tree_1k_read_out_next[at_tree_update_column_idx_n1] = at_tree_update_bit_sequence_n1[1];
    end
end

always @(*) begin
    at_tree_2k_read_out_next = 0;
    if (at_tree_update_en_n1) begin
        at_tree_2k_read_out_next = at_tree_2k_read_data2;
        at_tree_2k_read_out_next[at_tree_update_column_idx_n1] = at_tree_update_bit_sequence_n1[2];
    end
end

always @(*) begin
    at_tree_4k_read_out_next = 0;
    if (at_tree_update_en_n1) begin
        at_tree_4k_read_out_next = at_tree_4k_read_data2;
        at_tree_4k_read_out_next[at_tree_update_column_idx_n1] = at_tree_update_bit_sequence_n1[3];
    end
end

//2rd cycle, write back the updated data
always @(*) begin
    at_tree_512_write_en = 0;
    at_tree_512_write_addr = 0;
    at_tree_512_write_data = 0;
    if (at_tree_update_en_n2) begin
        at_tree_512_write_en = 1;
        at_tree_512_write_addr = at_tree_update_row_idx_n2;
        at_tree_512_write_data = at_tree_512_read_out;
    end
end

always @(*) begin
    at_tree_1k_write_en = 0;
    at_tree_1k_write_addr = 0;
    at_tree_1k_write_data = 0;
    if (at_tree_update_en_n2) begin
        at_tree_1k_write_en = 1;
        at_tree_1k_write_addr = at_tree_update_row_idx_n2;
        at_tree_1k_write_data = at_tree_1k_read_out;
    end
end

always @(*) begin
    at_tree_2k_write_en = 0;
    at_tree_2k_write_addr = 0;
    at_tree_2k_write_data = 0;
    if (at_tree_update_en_n2) begin
        at_tree_2k_write_en = 1;
        at_tree_2k_write_addr = at_tree_update_row_idx_n2;
        at_tree_2k_write_data = at_tree_2k_read_out;
    end
end

always @(*) begin
    at_tree_4k_write_en = 0;
    at_tree_4k_write_addr = 0;
    at_tree_4k_write_data = 0;
    if (at_tree_update_en_n2) begin
        at_tree_4k_write_en = 1;
        at_tree_4k_write_addr = at_tree_update_row_idx_n2;
        at_tree_4k_write_data = at_tree_4k_read_out;
    end
end

//3rd cycle,genearte the fdt update bit sequence
always @(*) begin
    fdt_update_bit_sequence_next = {&at_tree_4k_read_out, &at_tree_2k_read_out, &at_tree_1k_read_out, &at_tree_512_read_out};
end

//generate the fdt update request
always @(*) begin
     fdt_update_valid = at_tree_update_en_n3;
     fdt_update_idx = at_tree_update_row_idx_n3; //the at row idx is the fdt column idx
end


//************************************ sequential logic
always @(posedge clk or negedge rst_n) begin
    if (~rst_n)begin
        fdt_update_bit_sequence_next <= 0;
    end else begin
        fdt_update_bit_sequence <= fdt_update_bit_sequence_next;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        at_tree_512_read_out <= 0;
        at_tree_1k_read_out <= 0;
        at_tree_2k_read_out <= 0;
        at_tree_4k_read_out <= 0;
    end else begin
        at_tree_512_read_out <= at_tree_512_read_out_next;
        at_tree_1k_read_out <= at_tree_1k_read_out_next;
        at_tree_2k_read_out <= at_tree_2k_read_out_next;
        at_tree_4k_read_out <= at_tree_4k_read_out_next;        
    end
end



always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        alloc_valid_fdt_in_n1 <= 1'b0;
        alloc_valid_fdt_in_n2 <= 1'b0;
        alloc_valid_fdt_in_n3 <= 1'b0;
        alloc_id_fdt_in_n1 <= 0;
        alloc_id_fdt_in_n2 <= 0;
        alloc_id_fdt_in_n3 <= 0;
        alloc_size_fdt_in_n1 <= 0;
        alloc_size_fdt_in_n2 <= 0;
        alloc_size_fdt_in_n3 <= 0;
        alloc_pos_fdt_in_n1 <= 0;
        alloc_pos_fdt_in_n2 <= 0;
        alloc_pos_fdt_in_n3 <= 0;
        alloc_origin_size_fdt_in_n1 <= 0;
        alloc_origin_size_fdt_in_n2 <= 0;
        alloc_origin_size_fdt_in_n3 <= 0;

        at_tree_update_en_n1 <= 1'b0;
        at_tree_update_en_n2 <= 1'b0;
        at_tree_update_en_n3 <= 1'b0;
        at_tree_update_column_idx_n1 <= 0;
        at_tree_update_row_idx_n1 <= 0;
        at_tree_update_row_idx_n2 <= 0;
        at_tree_update_row_idx_n3 <= 0;
        at_tree_update_bit_sequence_n1 <= 0;
    end else begin
        alloc_valid_fdt_in_n1 <= alloc_valid_fdt_in;
        alloc_valid_fdt_in_n2 <= alloc_valid_fdt_in_n1;
        alloc_valid_fdt_in_n3 <= alloc_valid_fdt_in_n2;
        alloc_id_fdt_in_n1 <= alloc_id_fdt_in;
        alloc_id_fdt_in_n2 <= alloc_id_fdt_in_n1;
        alloc_id_fdt_in_n3 <= alloc_id_fdt_in_n2;
        alloc_size_fdt_in_n1 <= alloc_size_fdt_in;
        alloc_size_fdt_in_n2 <= alloc_size_fdt_in_n1;
        alloc_size_fdt_in_n3 <= alloc_size_fdt_in_n2;
        alloc_pos_fdt_in_n1 <= alloc_pos_fdt_in;
        alloc_pos_fdt_in_n2 <= alloc_pos_fdt_in_n1;
        alloc_pos_fdt_in_n3 <= alloc_pos_fdt_in_n2;
        alloc_origin_size_fdt_in_n1 <= alloc_origin_size_fdt_in;
        alloc_origin_size_fdt_in_n2 <= alloc_origin_size_fdt_in_n1;
        alloc_origin_size_fdt_in_n3 <= alloc_origin_size_fdt_in_n2;

        at_tree_update_en_n1 <= at_tree_update_en; 
        at_tree_update_en_n2 <= at_tree_update_en_n1;
        at_tree_update_en_n3 <= at_tree_update_en_n2;
        at_tree_update_column_idx_n1 <= at_tree_update_column_idx;
        at_tree_update_row_idx_n1 <= at_tree_update_row_idx;
        at_tree_update_row_idx_n2 <= at_tree_update_row_idx_n1;
        at_tree_update_row_idx_n3 <= at_tree_update_row_idx_n2;
        at_tree_update_bit_sequence_n1 <= at_tree_update_bit_sequence;
    end
end


//************************************ instance

first_zero  first_zero_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(at_tree_64bit_line),
    .find_success(find_success),//dont care
    .pos_out(pos_out), //care about
    .mask_out() //dont care
  );

  ram_3port_dp #(
    .ADDR_WIDTH(`AT_TREE_INDEX_WIDTH),
    .DATA_WIDTH(`AT_TREE_DATA_WIDTH)
)  at_tree_512 (
    .clk(clk),
    .write_en(at_tree_512_write_en), //for or_tree update
    .write_addr(at_tree_512_write_addr),
    .write_data(at_tree_512_write_data),
    .read_addr1(at_tree_512_read_addr1), //for or_tree read
    .read_data1(at_tree_512_read_data1),
    .read_addr2(at_tree_512_read_addr2), //for fdt search
    .read_data2(at_tree_512_read_data2)
);

ram_3port_dp #(
    .ADDR_WIDTH(`AT_TREE_INDEX_WIDTH),
    .DATA_WIDTH(`AT_TREE_DATA_WIDTH)
)  at_tree_1k (
    .clk(clk),
    .write_en(at_tree_1k_write_en),
    .write_addr(at_tree_1k_write_addr),
    .write_data(at_tree_1k_write_data),
    .read_addr1(at_tree_1k_read_addr1),
    .read_data1(at_tree_1k_read_data1),
    .read_addr2(at_tree_1k_read_addr2),
    .read_data2(at_tree_1k_read_data2)
);

ram_3port_dp #(
    .ADDR_WIDTH(`AT_TREE_INDEX_WIDTH),
    .DATA_WIDTH(`AT_TREE_DATA_WIDTH)
)  at_tree_2k (
    .clk(clk),
    .write_en(at_tree_2k_write_en),
    .write_addr(at_tree_2k_write_addr),
    .write_data(at_tree_2k_write_data),
    .read_addr1(at_tree_2k_read_addr1),
    .read_data1(at_tree_2k_read_data1),
    .read_addr2(at_tree_2k_read_addr2),
    .read_data2(at_tree_2k_read_data2)
);

ram_3port_dp #(
    .ADDR_WIDTH(`AT_TREE_INDEX_WIDTH),
    .DATA_WIDTH(`AT_TREE_DATA_WIDTH)
)  at_tree_4k (
    .clk(clk),
    .write_en(at_tree_4k_write_en),
    .write_addr(at_tree_4k_write_addr),
    .write_data(at_tree_4k_write_data),
    .read_addr1(at_tree_4k_read_addr1),
    .read_data1(at_tree_4k_read_data1),
    .read_addr2(at_tree_4k_read_addr2),
    .read_data2(at_tree_4k_read_data2)
);

endmodule