
//DUT: firstZero.v
`include "src/first_zero.v"

module first_zero_tb;

    // Parameters

    // Ports
    reg clk;
    reg rst_n;
    reg [63:0] data_in;
    wire find_success;
    wire [6:0] pos_out;
    wire [63:0] mask_out;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // DUT instantiation
    first_zero first_zero_i (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .find_success(find_success),
        .pos_out(pos_out),
        .mask_out(mask_out)
    );

    // Test stimulus
    initial begin
        // Initialize inputs
        rst_n = 0;
        data_in = 64'hFFFFFFFFFFFFFFFF;

        // Apply reset
        #10;
        rst_n = 1;

        // Test case 1: No zero in data_in
        #20;
        data_in = 64'hFFFFFFFFFFF0FFFF;
        $display("Test case 1: data_in = %h, find_success = %b, pos_out = %d, mask_out = %h", data_in, find_success, pos_out, mask_out);

        // Test case 2: Zero at position 0
        #20;
        data_in = 64'hFFFFFFFFFFFFFFFE;
        $display("Test case 2: data_in = %h, find_success = %b, pos_out = %d, mask_out = %h", data_in, find_success, pos_out, mask_out);

        // Test case 3: Zero at position 63
       #20;
        data_in = 64'h7FFFFFFFFFFFFFFF;
        $display("Test case 3: data_in = %h, find_success = %b, pos_out = %d, mask_out = %h", data_in, find_success, pos_out, mask_out);

        // Test case 4: Multiple zeros
       #20;
        data_in = 64'hFF00FF00FF00FF00;
        
        $display("Test case 4: data_in = %h, find_success = %b, pos_out = %d, mask_out = %h", data_in, find_success, pos_out, mask_out);

        // Test case 5: All zeros
       #20;
        data_in = 64'h0000000000000000;
       
        $display("Test case 5: data_in = %h, find_success = %b, pos_out = %d, mask_out = %h", data_in, find_success, pos_out, mask_out);

        // Test case 6: First zero at position 0
       #20;
        data_in = 64'h7FFFFFFFFFFFFFFF;
        
        $display("Test case 6: data_in = %h, find_success = %b, pos_out = %d, mask_out = %h", data_in, find_success, pos_out, mask_out);


        // Finish simulation
        #20;
        $finish;
    end

endmodule