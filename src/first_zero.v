
//Module:       first_zero.v
//Usage:        Find the position of the first zero in the input data stream
//Introduction: The first clk cycle will use the operator update the data to 0000...10000 pattern.
//              And the next clk cycle will find the position of the first zero in the edited data
//              stream.
`ifndef FIRST_ZERO_H
`define FIRST_ZERO_H

module first_zero (
    clk,
    rst_n,

    find_success, //output, 1 if the first zero is found, 0 otherwise
    data_in,    // input data stream
    pos_out,     // output position of the first zero
    mask_out    // output mask of the first zero, 00..010...000
  );
  //************************************ parameters
  parameter FIND_SUCCESS = 1;
  parameter FIND_FAIL = 0;

  //************************************ ports
  input clk;
  input rst_n;
  input [63:0] data_in;
  output find_success;
  output [6:0] pos_out;
  output [63:0] mask_out;


  //************************************ signals
  reg [63:0] mask_out;
  reg [6:0] pos_out;
  reg find_success;

  wire [63:0] data_reverse;
  wire [63:0] data_reverse_dec_1;
  wire [63:0] dara_reverse_dec_1_reverse;
  wire [63:0] mask_result;

  wire [15:0] data_split_part1;
  wire [15:0] data_split_part2;
  wire [15:0] data_split_part3;
  wire [15:0] data_split_part4;
  
  wire part1_all_zero;
  wire part2_all_zero;
  wire part3_all_zero;
  wire part4_all_zero;

  reg [6:0] split_part1_pos;
  reg [6:0] split_part2_pos;
  reg [6:0] split_part3_pos;
  reg [6:0] split_part4_pos;
  wire [6:0] part1_2_sum_pos;
  wire [6:0] part3_4_sum_pos;
  wire [6:0] part1_2_3_4_sum_pos;



  //************************************ combinational logic
  assign data_reverse = ~data_in;
  assign data_reverse_dec_1 = data_reverse - 1;
  assign dara_reverse_dec_1_reverse = ~data_reverse_dec_1;
  assign mask_result = data_reverse & dara_reverse_dec_1_reverse;

  assign data_split_part1 = mask_out[15:0];
  assign data_split_part2 = mask_out[31:16];
  assign data_split_part3 = mask_out[47:32];
  assign data_split_part4 = mask_out[63:48];

  assign part1_all_zero = (data_split_part1 == 16'b0);
  assign part2_all_zero = (data_split_part2 == 16'b0);
  assign part3_all_zero = (data_split_part3 == 16'b0);
  assign part4_all_zero = (data_split_part4 == 16'b0);

  assign part1_2_sum_pos = split_part1_pos + split_part2_pos;
  assign part3_4_sum_pos = split_part3_pos + split_part4_pos;
  assign part1_2_3_4_sum_pos = part1_2_sum_pos + part3_4_sum_pos;
  //then we use the mask_out in the next clk cycle to find the position of the first zero

  always @(*) 
    begin
        if (part1_all_zero)
            split_part1_pos = 6'b0;
        else
            begin
               case(data_split_part1)
                     16'b0000000000000001: split_part1_pos = 7'd1;
                     16'b0000000000000010: split_part1_pos = 7'd2;
                     16'b0000000000000100: split_part1_pos = 7'd3;
                     16'b0000000000001000: split_part1_pos = 7'd4;
                     16'b0000000000010000: split_part1_pos = 7'd5;
                     16'b0000000000100000: split_part1_pos = 7'd6;
                     16'b0000000001000000: split_part1_pos = 7'd7;
                     16'b0000000010000000: split_part1_pos = 7'd8;
                     16'b0000000100000000: split_part1_pos = 7'd9;
                     16'b0000001000000000: split_part1_pos = 7'd10;
                     16'b0000010000000000: split_part1_pos = 7'd11;
                     16'b0000100000000000: split_part1_pos = 7'd12;
                     16'b0001000000000000: split_part1_pos = 7'd13;
                     16'b0010000000000000: split_part1_pos = 7'd14;
                     16'b0100000000000000: split_part1_pos = 7'd15;
                     16'b1000000000000000: split_part1_pos = 7'd16;
                     default: split_part1_pos = 7'd0;
                endcase
            end
    end

    always @(*)
    begin
        if (part2_all_zero)
            split_part2_pos = 7'b0;
        else
            begin
               case(data_split_part2)
                     16'b0000000000000001: split_part2_pos = 7'd17;
                     16'b0000000000000010: split_part2_pos = 7'd18;
                     16'b0000000000000100: split_part2_pos = 7'd19;
                     16'b0000000000001000: split_part2_pos = 7'd20;
                     16'b0000000000010000: split_part2_pos = 7'd21;
                     16'b0000000000100000: split_part2_pos = 7'd22;
                     16'b0000000001000000: split_part2_pos = 7'd23;
                     16'b0000000010000000: split_part2_pos = 7'd24;
                     16'b0000000100000000: split_part2_pos = 7'd25;
                     16'b0000001000000000: split_part2_pos = 7'd26;
                     16'b0000010000000000: split_part2_pos = 7'd27;
                     16'b0000100000000000: split_part2_pos = 7'd28;
                     16'b0001000000000000: split_part2_pos = 7'd29;
                     16'b0010000000000000: split_part2_pos = 7'd30;
                     16'b0100000000000000: split_part2_pos = 7'd31;
                     16'b1000000000000000: split_part2_pos = 7'd32;
                     default: split_part2_pos = 7'd0;
                endcase
            end
    end
    always @(*)
    begin
        if (part3_all_zero)
            split_part3_pos = 7'b0;
        else
            begin
               case(data_split_part3)
                     16'b0000000000000001: split_part3_pos = 7'd33;
                     16'b0000000000000010: split_part3_pos = 7'd34;
                     16'b0000000000000100: split_part3_pos = 7'd35;
                     16'b0000000000001000: split_part3_pos = 7'd36;
                     16'b0000000000010000: split_part3_pos = 7'd37;
                     16'b0000000000100000: split_part3_pos = 7'd38;
                     16'b0000000001000000: split_part3_pos = 7'd39;
                     16'b0000000010000000: split_part3_pos = 7'd40;
                     16'b0000000100000000: split_part3_pos = 7'd41;
                     16'b0000001000000000: split_part3_pos = 7'd42;
                     16'b0000010000000000: split_part3_pos = 7'd43;
                     16'b0000100000000000: split_part3_pos = 7'd44;
                     16'b0001000000000000: split_part3_pos = 7'd45;
                     16'b0010000000000000: split_part3_pos = 7'd46;
                     16'b0100000000000000: split_part3_pos = 7'd47;
                     16'b1000000000000000: split_part3_pos = 7'd48;
                     default: split_part3_pos = 7'd0;
                endcase
            end
    end

    always @(*)
    begin
        if (part4_all_zero)
            split_part4_pos = 7'b0;
        else
            begin
               case(data_split_part4)
                     16'b0000000000000001: split_part4_pos = 7'd49;
                     16'b0000000000000010: split_part4_pos = 7'd50;
                     16'b0000000000000100: split_part4_pos = 7'd51;
                     16'b0000000000001000: split_part4_pos = 7'd52;
                     16'b0000000000010000: split_part4_pos = 7'd53;
                     16'b0000000000100000: split_part4_pos = 7'd54;
                     16'b0000000001000000: split_part4_pos = 7'd55;
                     16'b0000000010000000: split_part4_pos = 7'd56;
                     16'b0000000100000000: split_part4_pos = 7'd57;
                     16'b0000001000000000: split_part4_pos = 7'd58;
                     16'b0000010000000000: split_part4_pos = 7'd59;
                     16'b0000100000000000: split_part4_pos = 7'd60;
                     16'b0001000000000000: split_part4_pos = 7'd61;
                     16'b0010000000000000: split_part4_pos = 7'd62;
                     16'b0100000000000000: split_part4_pos = 7'd63;
                     16'b1000000000000000: split_part4_pos = 7'd64;
                     default: split_part4_pos = 7'd0;
                endcase
            end
    end



  //************************************ sequential logic
  always @(posedge clk or negedge rst_n)
    begin
        if (~rst_n) begin
            mask_out <= 64'b0;
            find_success <= FIND_FAIL;
            pos_out <= 0;
        end
        else begin
            mask_out <= mask_result;
            find_success <= (mask_result != 64'b0);
            pos_out <= part1_2_3_4_sum_pos;
        end
    end


endmodule

`endif