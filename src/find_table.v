//!the entrance to handle the alloc request and the end to handle the poped up update opt.
//!we dont need ram here, the fdt only need 256bit
//!the kernel of this module is the mask
`include "../src/mmu_param.vh"
`include "../src/ram_assign.v"
`include "../src/first_zero.v"

module find_table(
    clk,
    rst_n,
    //the alloc request from dispatcher
    alloc_valid_dsp_in,
    alloc_id_dsp_in,
    alloc_size_dsp_in, //aligned size
    //search the table , put the result to the at tree
    alloc_valid_at_out,
    alloc_id_at_out,
    alloc_row_index_at_out,
    alloc_size_at_out, 
    //update from the at tree
    fdt_update_valid_at_in,
    fdt_update_idx_at_in,
    fdt_update_bit_sequence_at_in,
    //output a valid signal to the dispatcher , to determine whether can alloc new memory
    fdt_blocked //1 bit output to dispatcher
);
//************************************ ports
input clk;
input rst_n;
input alloc_valid_dsp_in;
input [`REQ_ID_WIDTH-1:0] alloc_id_dsp_in;
input [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_size_dsp_in; 
//for fdt search result output
output alloc_valid_at_out;
output [`REQ_ID_WIDTH-1:0] alloc_id_at_out;
output [`AT_TREE_INDEX_WIDTH-1:0] alloc_row_index_at_out;
output [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_size_at_out;
input fdt_update_valid_at_in;
input [`FDT_INDEX_WIDTH-1:0] fdt_update_idx_at_in;
input [`FDT_BIT_WIDTH-1:0] fdt_update_bit_sequence_at_in;
output fdt_blocked;//3:4k 2:2k 1:1k 0:512

//************************************ signals
reg alloc_valid_at_out;
reg [`REQ_ID_WIDTH-1:0] alloc_id_at_out;
reg [`AT_TREE_INDEX_WIDTH-1:0] alloc_row_index_at_out;
reg [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_size_at_out;
reg alloc_valid_dsp_in_n1,alloc_valid_dsp_in_n2,alloc_valid_dsp_in_n3;
reg [`REQ_ID_WIDTH-1:0] alloc_id_dsp_in_n1,alloc_id_dsp_in_n2,alloc_id_dsp_in_n3;
reg [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_size_dsp_in_n1,alloc_size_dsp_in_n2,alloc_size_dsp_in_n3;
reg fdt_blocked;

reg fdt_update_valid_at_in_n1,fdt_update_valid_at_in_n2;
reg [`FDT_INDEX_WIDTH-1:0] fdt_update_idx_at_in_n1,fdt_update_idx_at_in_n2;
reg [`FDT_BIT_WIDTH-1:0] fdt_update_bit_sequence_at_in_n1,fdt_update_bit_sequence_at_in_n2;

//internal signals, we need mask & table value ram
reg [`FTD_DATA_WIDTH-1:0] fdt_mask,fdt_mask_next;
reg [`FTD_DATA_WIDTH-1:0] fdt_table_read_value1,fdt_table_read_value1_next;
wire[`FTD_DATA_WIDTH-1:0] fdt_masked_value;
wire[`FTD_DATA_WIDTH-1:0] fdt_masked_value_next;
wire find_success;
wire [6:0] pos_out;
reg blocked,blocked_next;
wire [`FTD_DATA_WIDTH-1:0] mask_out;

reg fdt_512_write_en,fdt_1k_write_en,fdt_2k_write_en,fdt_4k_write_en;
reg fdt_512_write_en_next,fdt_1k_write_en_next,fdt_2k_write_en_next,fdt_4k_write_en_next;
wire [`FTD_DATA_WIDTH-1:0] fdt_512_read_data,fdt_1k_read_data,fdt_2k_read_data,fdt_4k_read_data;
reg [`FTD_DATA_WIDTH-1:0] fdt_512_read_data_tmp,fdt_1k_read_data_tmp,fdt_2k_read_data_tmp,fdt_4k_read_data_tmp;

reg [`FTD_DATA_WIDTH-1:0] fdt_512_write_data,fdt_1k_write_data,fdt_2k_write_data,fdt_4k_write_data;
reg [`FTD_DATA_WIDTH-1:0] fdt_512_write_data_next,fdt_1k_write_data_next,fdt_2k_write_data_next,fdt_4k_write_data_next;

//************************************ combinational logic
assign fdt_masked_value = fdt_table_read_value1 | fdt_mask;
assign fdt_masked_value_next = fdt_table_read_value1_next | fdt_mask;

//make sure the block keep high until next time we dispatch the prev request again
always @(*) begin
    blocked_next = blocked;
    if (alloc_valid_dsp_in)begin
        blocked_next = (fdt_masked_value_next == 64'hFFFF_FFFF_FFFF_FFFF);
    end
end


//!logic to update the mask_next
always @(*) begin
    fdt_mask_next = fdt_mask;
    if (find_success && alloc_valid_dsp_in_n2)begin
        fdt_mask_next = fdt_mask | mask_out;
    end
    if (fdt_update_valid_at_in_n2)begin //we can cancel the mask now
        fdt_mask_next[fdt_update_idx_at_in_n2] = 1'b0;
    end
end



always @(*) begin
    fdt_table_read_value1_next = fdt_table_read_value1; 
    if(alloc_valid_dsp_in) begin
        case(alloc_size_dsp_in)
            `REQ_512: begin
               fdt_table_read_value1_next = fdt_512_read_data;
            end
            `REQ_1K: begin
               fdt_table_read_value1_next = fdt_1k_read_data;
            end
            `REQ_2K: begin
               fdt_table_read_value1_next = fdt_2k_read_data;
            end
            `REQ_4K: begin
               fdt_table_read_value1_next = fdt_4k_read_data;
            end
        endcase 
    end
end

always @(*) begin
    fdt_512_write_data_next = 0;
    fdt_512_write_en_next = 1'b0;
    if (fdt_update_valid_at_in_n1)begin
        fdt_512_write_en_next = 1'b1;
        fdt_512_write_data_next = fdt_512_read_data_tmp;
        fdt_512_write_data_next[fdt_update_idx_at_in_n1] = fdt_update_bit_sequence_at_in_n1[0];
    end
end

always @(*) begin
    fdt_1k_write_data_next = 0;
    fdt_1k_write_en_next = 1'b0;
    if (fdt_update_valid_at_in_n1)begin
        fdt_1k_write_en_next = 1'b1;
        fdt_1k_write_data_next = fdt_1k_read_data_tmp;
        fdt_1k_write_data_next[fdt_update_idx_at_in_n1] = fdt_update_bit_sequence_at_in_n1[1];
    end
end

always @(*) begin
    fdt_2k_write_data_next = 0;
    fdt_2k_write_en_next = 1'b0;
    if (fdt_update_valid_at_in_n1)begin
        fdt_2k_write_en_next = 1'b1;
        fdt_2k_write_data_next = fdt_2k_read_data_tmp;
        fdt_2k_write_data_next[fdt_update_idx_at_in_n1] = fdt_update_bit_sequence_at_in_n1[2];
    end
end

always @(*) begin
    fdt_4k_write_data_next = 0;
    fdt_4k_write_en_next = 1'b0;
    if (fdt_update_valid_at_in_n1)begin
        fdt_4k_write_en_next = 1'b1;
        fdt_4k_write_data_next = fdt_4k_read_data_tmp;
        fdt_4k_write_data_next[fdt_update_idx_at_in_n1] = fdt_update_bit_sequence_at_in_n1[3];
    end
end



//!output assign
always @(*) begin
    fdt_blocked = blocked;
    alloc_valid_at_out = alloc_valid_dsp_in_n3;
    alloc_id_at_out = alloc_id_dsp_in_n3;
    alloc_row_index_at_out = pos_out -1;
    alloc_size_at_out = alloc_size_dsp_in_n3;
end


//************************************ sequential logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        alloc_valid_dsp_in_n1 <= 0;
        alloc_valid_dsp_in_n2 <= 0;
        alloc_valid_dsp_in_n3 <= 0;
        alloc_id_dsp_in_n1 <= 0;
        alloc_id_dsp_in_n2 <= 0;
        alloc_id_dsp_in_n3 <= 0;
        alloc_size_dsp_in_n1 <= 0;
        alloc_size_dsp_in_n2 <= 0;
        alloc_size_dsp_in_n3 <= 0;

        fdt_table_read_value1 <= 0;
        fdt_mask <= 0;

        fdt_update_valid_at_in_n1 <= 0;
        fdt_update_valid_at_in_n2 <= 0;
        fdt_update_idx_at_in_n1 <= 0;
        fdt_update_idx_at_in_n2 <= 0;
        fdt_update_bit_sequence_at_in_n1 <= 0;
        fdt_update_bit_sequence_at_in_n2 <= 0;

        fdt_512_read_data_tmp <= 0;
        fdt_1k_read_data_tmp <= 0;
        fdt_2k_read_data_tmp <= 0;
        fdt_4k_read_data_tmp <= 0;

        fdt_512_write_data <= 0;
        fdt_1k_write_data <= 0;
        fdt_2k_write_data <= 0;
        fdt_4k_write_data <= 0;

        fdt_512_write_en <= 0;
        fdt_1k_write_en <= 0;
        fdt_2k_write_en <= 0;
        fdt_4k_write_en <= 0;

        blocked <= 0;


    end else begin
        alloc_valid_dsp_in_n1 <= alloc_valid_dsp_in;
        alloc_id_dsp_in_n1 <= alloc_id_dsp_in;
        alloc_size_dsp_in_n1 <= alloc_size_dsp_in;
        //stop spread if blocked
        if(!blocked) begin
            alloc_valid_dsp_in_n2 <= alloc_valid_dsp_in_n1;
            alloc_id_dsp_in_n2 <= alloc_id_dsp_in_n1;
            alloc_size_dsp_in_n2 <= alloc_size_dsp_in_n1;
            alloc_valid_dsp_in_n3 <= alloc_valid_dsp_in_n2;
            alloc_id_dsp_in_n3 <= alloc_id_dsp_in_n2;
            alloc_size_dsp_in_n3 <= alloc_size_dsp_in_n2;
        end else begin
            alloc_valid_dsp_in_n2 <= 0;
            alloc_id_dsp_in_n2 <= 0;
            alloc_size_dsp_in_n2 <= 0;
            alloc_valid_dsp_in_n3 <= 0;
            alloc_id_dsp_in_n3 <= 0;
            alloc_size_dsp_in_n3 <= 0;
        end

        fdt_table_read_value1 <= fdt_table_read_value1_next;
        fdt_mask <= fdt_mask_next;

        fdt_update_valid_at_in_n1 <= fdt_update_valid_at_in;
        fdt_update_idx_at_in_n1 <= fdt_update_idx_at_in;
        fdt_update_bit_sequence_at_in_n1 <= fdt_update_bit_sequence_at_in;
        fdt_update_valid_at_in_n2 <= fdt_update_valid_at_in_n1;
        fdt_update_idx_at_in_n2 <= fdt_update_idx_at_in_n1;
        fdt_update_bit_sequence_at_in_n2 <= fdt_update_bit_sequence_at_in_n1;

        fdt_512_write_data <= fdt_512_write_data_next;
        fdt_1k_write_data <= fdt_1k_write_data_next;
        fdt_2k_write_data <= fdt_2k_write_data_next;
        fdt_4k_write_data <= fdt_4k_write_data_next;

        fdt_512_write_en <= fdt_512_write_en_next;
        fdt_1k_write_en <= fdt_1k_write_en_next;
        fdt_2k_write_en <= fdt_2k_write_en_next;
        fdt_4k_write_en <= fdt_4k_write_en_next;

        fdt_512_read_data_tmp <= fdt_512_read_data;
        fdt_1k_read_data_tmp <= fdt_1k_read_data;
        fdt_2k_read_data_tmp <= fdt_2k_read_data;
        fdt_4k_read_data_tmp <= fdt_4k_read_data;

        blocked <= blocked_next;

    end
end


//************************************ instance

first_zero  first_zero_inst (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(fdt_masked_value),
    .find_success(find_success),//dont care
    .pos_out(pos_out), //care about
    .mask_out(mask_out) 
  );


ram_assign #(
    .ADDR_WIDTH(`FDT_ADDR_WIDTH),
    .DATA_WIDTH(`FTD_DATA_WIDTH)
)  fdt_512 (
    .clk(clk),
    .write_en(fdt_512_write_en), //for or_tree update
    .write_addr(1'b0),
    .write_data(fdt_512_write_data),
    .read_addr(1'b0), //for or_tree read
    .read_data(fdt_512_read_data)
);

ram_assign #(
    .ADDR_WIDTH(`FDT_ADDR_WIDTH),
    .DATA_WIDTH(`FTD_DATA_WIDTH)
)  fdt_1k (
    .clk(clk),
    .write_en(fdt_1k_write_en),
    .write_addr(1'b0),
    .write_data(fdt_1k_write_data),
    .read_addr(1'b0),
    .read_data(fdt_1k_read_data)
);

ram_assign #(
    .ADDR_WIDTH(`FDT_ADDR_WIDTH),
    .DATA_WIDTH(`FTD_DATA_WIDTH)
)  fdt_2k (
    .clk(clk),
    .write_en(fdt_2k_write_en),
    .write_addr(1'b0),
    .write_data(fdt_2k_write_data),
    .read_addr(1'b0),
    .read_data(fdt_2k_read_data)
);

ram_assign #(
    .ADDR_WIDTH(`FDT_ADDR_WIDTH),
    .DATA_WIDTH(`FTD_DATA_WIDTH)
)  fdt_4k (
    .clk(clk),
    .write_en(fdt_4k_write_en),
    .write_addr(1'b0),
    .write_data(fdt_4k_write_data),
    .read_addr(1'b0),
    .read_data(fdt_4k_read_data)
);

endmodule