//@Author:GaoSong Xu
//!This is the testbench for the mmu_tree module, we will generate the alloc request and free request, and check the memory usage

`include "../src/mmu_top.v"
`include "../src/mmu_param.vh"

typedef struct packed {
    bit [`REQ_ID_WIDTH-1:0] alloc_req_id;
    bit [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_req_page_count;
} alloc_req;

typedef struct packed {
   bit [`REQ_ID_WIDTH-1:0] free_req_id;
   bit [`ALL_PAGE_IDX_WIDTH-1:0] free_req_page_idx;
   bit [`REQ_SIZE_TYPE_WIDTH-1:0] free_req_page_count;
} free_req;

typedef struct packed{
   bit [`REQ_ID_WIDTH-1:0] alloc_rsp_id;
   bit [`ALL_PAGE_IDX_WIDTH-1:0] alloc_rsp_page_idx;
   bit alloc_rsp_fail;
   bit [`FAIL_REASON_WIDTH-1:0] alloc_rsp_fail_reason;
   bit [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_request_size; //may not aligned
   bit [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_request_aligned_size; //aligned size
}alloc_rsp;

typedef struct packed{
   bit [`REQ_ID_WIDTH-1:0] free_rsp_id;
   bit free_rsp_fail;
   bit [`FAIL_REASON_WIDTH-1:0] free_rsp_fail_reason;
   bit [`REQ_SIZE_TYPE_WIDTH-1:0] free_rsp_origin_page_count;
   bit [`REQ_SIZE_TYPE_WIDTH-1:0] free_rsp_aligned_page_count;
}free_rsp;

`define INIT_ALLOC_REQUEST_SIZE 16384
`define KB 1024
`define MB 1024*1024
`define GB 1024*1024*1024

class MemoryChecker;


    localparam TOTAL_MEMORY_PAGE_IDX = 32768;

    bit [`REQ_ID_WIDTH-1:0] ram [TOTAL_MEMORY_PAGE_IDX]; 
    alloc_req alloc_req_map[alloc_req];
    free_req free_req_map[free_req];
    semaphore alloc_req_map_samaphore;
    semaphore free_req_map_samaphore;
    semaphore ram_samaphore;
    mailbox alloc_rsp_box;
    mailbox free_rsp_box;
    mailbox checked_alloc_rsp_box;
    integer total_submit_alloc_req = 0;
    integer total_submit_free_req = 0;

    integer total_success_alloc_req = 0;
    integer total_success_free_req = 0;
    integer total_fail_alloc_req = 0;
    integer total_fail_free_req = 0;
    real current_memory_usage = 0.0;
    real max_memory_usage = 0.0;
    integer page_in_use = 0;
    integer page_max_in_use = 0;
    integer diff_size_alloc_submitted_req[10] = '{default:0};
    integer diff_size_free_submitted_req[10] = '{default:0};
    integer on_flight_alloc_req = 0;
    integer on_flight_free_req = 0;
    semaphore page_use_samaphore;
    time start_time;//for performance check
    real ave_alloc_memory_per_sec, ave_free_memory_per_sec;
    longint all_alloced_memory_size = 0;
    longint all_freed_memory_size = 0;
    event print_trigger;

    //when to end the test?
    //the flight request is 0,and the total alloc rsp equal to the total submit alloc req
    //and the total free rsp equal to the total submit free req,the page in use is 0


    function new(mailbox alloc_rsp_box, mailbox free_rsp_box, mailbox checked_alloc_rsp_box);
        alloc_req_map_samaphore = new(1);
        free_req_map_samaphore = new(1);
        ram_samaphore = new(1);
        alloc_req_map.delete();
        free_req_map.delete(); 
        this.alloc_rsp_box = alloc_rsp_box;
        this.free_rsp_box = free_rsp_box;
        this.checked_alloc_rsp_box = checked_alloc_rsp_box;
        diff_size_alloc_submitted_req = '{default:0};
        diff_size_free_submitted_req = '{default:0};
        page_use_samaphore = new(1);
        start_time = $time;
    endfunction //new()

    task register_alloc_req(alloc_req req);
        alloc_req_map_samaphore.get();
        alloc_req_map[req.alloc_req_id] = req;
        alloc_req_map_samaphore.put();

        total_submit_alloc_req++;
        diff_size_alloc_submitted_req[req.alloc_req_page_count]++;
        on_flight_alloc_req++;
    endtask

    task register_free_req(free_req req);
        free_req_map_samaphore.get();
        free_req_map[req.free_req_id] = req;
        free_req_map_samaphore.put();

        total_submit_free_req++;
        diff_size_free_submitted_req[req.free_req_page_count]++;
        on_flight_free_req++;
    endtask

    task clear_alloc_req(alloc_req req);
        alloc_req_map_samaphore.get();
        alloc_req_map.delete(req.alloc_req_id);
        alloc_req_map_samaphore.put();
    endtask

    task clear_free_req(free_req req);
        free_req_map_samaphore.get();
        free_req_map.delete(req.free_req_id);
        free_req_map_samaphore.put();
    endtask

    //input the cycle number
    task print_static_thread(
    );
    begin
        time cur_time;
        @(print_trigger);
        cur_time = $time;
        $display("*********Memory Checker Event Report*********");
        //display current time in ms, .3f
        $display("Current time: %.3f ms",cur_time*1.0e-6);
        $display("total_submit_alloc_req:%d",total_submit_alloc_req);
        $display("total_submit_free_req:%d",total_submit_free_req);
        $display("total_success_alloc_rsp:%d",total_success_alloc_req);
        $display("total_success_free_rsp:%d",total_success_free_req);
        $display("total_fail_alloc_rsp:%d",total_fail_alloc_req);
        $display("total_fail_free_rsp:%d",total_fail_free_req);
        $display("on_flight_alloc_req:%d",on_flight_alloc_req);
        $display("on_flight_free_req:%d",on_flight_free_req);
        $display("page_in_use:%d",page_in_use);
        $display("current_memory_usage:%.3f%%",current_memory_usage*100);
        $display("page_max_in_use:%d",page_max_in_use);
        $display("max_memory_usage:%.3f%%",max_memory_usage*100);
        $display("ave_alloc_memory_per_sec:%.3fGB/s",ave_alloc_memory_per_sec);
        $display("ave_free_memory_per_sec:%.3fGB/s",ave_free_memory_per_sec);
        $display("diff_size_alloc_submitted_req:");
        for (int i=0; i<10; i++) begin
            $write("%4d:%4d;",i,diff_size_alloc_submitted_req[i]);
        end
        $display("");
        $display("diff_size_free_submitted_req:");
        for (int i=0; i<10; i++) begin
            $write("%4d:%4d;",i,diff_size_free_submitted_req[i]);
        end
        $display("");
    end
    endtask
    task test_over_check(
        output bit test_over
    );
    begin
        test_over = (on_flight_alloc_req==0 && on_flight_free_req==0 && (total_success_alloc_req+total_fail_alloc_req)==`INIT_ALLOC_REQUEST_SIZE
            && (page_in_use==0));
    end
    endtask

    task check_alloc_rsp_thread();
    begin
        alloc_rsp rsp;
        alloc_req req;
        integer aligned_page_size;
        bit fail_rsp;
        integer tree_idx_start;
        integer tree_idx_end;
        integer total_rsp_get = 0;
        time gap_time;

        while (1) begin
            fail_rsp = 0;
            alloc_rsp_box.get(rsp);
            total_rsp_get++;
            alloc_req_map_samaphore.get();
            req = alloc_req_map[rsp.alloc_rsp_id];
            alloc_req_map_samaphore.put();
            //the req must be valid
            assert(req.alloc_req_id == rsp.alloc_rsp_id) else $fatal("MMU:alloc rsp id %d is not valid",rsp.alloc_rsp_id);
            assert(req.alloc_req_page_count == rsp.alloc_request_size) else $fatal("MMU:alloc rsp id %d is not valid, page count is not equal",rsp.alloc_rsp_id);
            
            //do some check step
            //1.assert the rsp must be valid or invalid base on the req size
            if(req.alloc_req_page_count == 0)begin
                assert (rsp.alloc_rsp_fail==1 && rsp.alloc_rsp_fail_reason==`ALLOC_FAIL_REASON_EQUAL_ZERO)
                else $fatal("MMU:alloc rsp id %d is not valid, fail reason is equal zero",rsp.alloc_rsp_id);
                assert (rsp.alloc_request_aligned_size == 0) else
                $fatal("MMU:alloc rsp id %d is not valid, aligned size is not equal",rsp.alloc_rsp_id);
                fail_rsp = 1;
            end else if (req.alloc_req_page_count >8)begin
                assert (rsp.alloc_rsp_fail==1 && rsp.alloc_rsp_fail_reason==`ALLOC_FAIL_REASON_OVER_4KB)
                else $fatal("MMU:alloc rsp id %d is not valid, fail reason is over 4k",rsp.alloc_rsp_id);
                assert (rsp.alloc_request_aligned_size == 0) else
                $fatal("MMU:alloc rsp id %d is not valid, aligned size is not equal",rsp.alloc_rsp_id);
                fail_rsp = 1;
            end else begin
                case (req.alloc_req_page_count)
                    1: aligned_page_size = 1;
                    2: aligned_page_size = 2;
                    3: aligned_page_size = 4;
                    4: aligned_page_size = 4;
                    5: aligned_page_size = 8;
                    6: aligned_page_size = 8;
                    7: aligned_page_size = 8;
                    8: aligned_page_size = 8;
                    default: aligned_page_size = 0;
                endcase
                //2. check the page idx + aligned_page_size must in a tree
                tree_idx_start = rsp.alloc_rsp_page_idx>>3;
                tree_idx_end = (rsp.alloc_rsp_page_idx+aligned_page_size-1)>>3;
                if (tree_idx_start != tree_idx_end)begin
                    $fatal("MMU:alloc rsp id %d is not valid, page idx is not in a tree",rsp.alloc_rsp_id);
                end else begin
                    assert (rsp.alloc_rsp_fail==0) else
                    $fatal("MMU:alloc rsp id %d is not valid, fail reason is unknown",rsp.alloc_rsp_id);
                end
                assert (aligned_page_size == rsp.alloc_request_aligned_size) else
                $fatal("MMU:alloc rsp id %d is not valid, aligned size is not equal",rsp.alloc_rsp_id);
            end 
            if(fail_rsp)begin
                total_fail_alloc_req++;
                on_flight_alloc_req--;
                this.clear_alloc_req(req);
                ->print_trigger;
                continue;
            end
            ram_samaphore.get();
            for (int i=rsp.alloc_rsp_page_idx; i<rsp.alloc_rsp_page_idx+aligned_page_size; i++) begin
                assert (ram[i] == 0) else $fatal("MMU:alloc rsp id %d is not valid, page idx %d is not zero",rsp.alloc_rsp_id,i);
                ram[i] = rsp.alloc_rsp_id;
            end
            ram_samaphore.put();
            rsp.alloc_request_size = req.alloc_req_page_count;//must be valid,1~8
            rsp.alloc_request_aligned_size = aligned_page_size;
            //4. push the rsp into the checked_alloc_rsp_box, alloc tester to generate the free req
            checked_alloc_rsp_box.put(rsp);
            total_success_alloc_req++;
            on_flight_alloc_req--;

            page_use_samaphore.get();

            gap_time = $time - start_time;
            all_alloced_memory_size += req.alloc_req_page_count * 512;//512 bytes per page
            //the gap time is current ns,change to second
            ave_alloc_memory_per_sec = all_alloced_memory_size*1.0/(gap_time*1.0e-9)/(`GB);

            page_in_use += req.alloc_req_page_count;
            if (page_in_use > page_max_in_use) begin
                page_max_in_use = page_in_use;
            end
            //calculate the memory usage
            current_memory_usage = page_in_use*1.0/TOTAL_MEMORY_PAGE_IDX;
            if (current_memory_usage > max_memory_usage) begin
                max_memory_usage = current_memory_usage;
            end
            page_use_samaphore.put();

            //5.remove the req from the alloc_req_map
            this.clear_alloc_req(req);
            ->print_trigger;
        end   
    end     
    endtask

    //when we generate a wrong free request,we must follow a valid free request
    task check_free_rsp_thread();
    begin        
        free_req req;
        free_rsp rsp;
        integer aligned_page_size;
        bit fail_rsp;
        integer tree_idx_start;
        integer tree_idx_end;
        time gap_time;

        while(1)begin
            fail_rsp = 0;
            free_rsp_box.get(rsp);
            free_req_map_samaphore.get();
            req = free_req_map[rsp.free_rsp_id];
            free_req_map_samaphore.put();
            assert(req.free_req_id == rsp.free_rsp_id) else $fatal("MMU:free rsp id %d is not valid",rsp.free_rsp_id);
            assert(req.free_req_page_count == rsp.free_rsp_origin_page_count) else $fatal("MMU:free rsp id %d is not valid, page count is not equal",rsp.free_rsp_id);

            if(req.free_req_page_count == 0)begin
                assert (rsp.free_rsp_fail==1 && rsp.free_rsp_fail_reason==`FREE_FAIL_REASON_EQUAL_ZERO)
                else $fatal("MMU:free rsp id %d is not valid, fail reason is equal zero",rsp.free_rsp_id);
                assert(rsp.free_rsp_aligned_page_count == 0) else
                $fatal("MMU:free rsp id %d is not valid, aligned size is not equal",rsp.free_rsp_id);
                fail_rsp = 1;
            end else if (req.free_req_page_count >8)begin
                assert (rsp.free_rsp_fail==1 && rsp.free_rsp_fail_reason==`FREE_FAIL_REASON_OVER_4KB)
                else $fatal("MMU:free rsp id %d is not valid, fail reason is over 4k",rsp.free_rsp_id);
                assert (rsp.free_rsp_aligned_page_count == 0) else
                $fatal("MMU:free rsp id %d is not valid, aligned size is not equal",rsp.free_rsp_id);
                fail_rsp = 1;
            end else begin
                //calculate the aligned size
                case (req.free_req_page_count)
                    1: aligned_page_size = 1;
                    2: aligned_page_size = 2;
                    3: aligned_page_size = 4;
                    4: aligned_page_size = 4;
                    5: aligned_page_size = 8;
                    6: aligned_page_size = 8;
                    7: aligned_page_size = 8;
                    8: aligned_page_size = 8;
                endcase
                tree_idx_start = req.free_req_page_idx>>3;
                tree_idx_end = (req.free_req_page_idx+aligned_page_size-1)>>3;
                if (tree_idx_start != tree_idx_end)begin
                    $fatal("MMU:free rsp id %d is not valid, page idx is not in a tree",rsp.free_rsp_id);
                end else begin                        
                    assert (rsp.free_rsp_fail==0) //must success
                    else   $fatal("MMU:free rsp id %d is not valid, fail reason is unknown",rsp.free_rsp_id);
                end
                assert (aligned_page_size == rsp.free_rsp_aligned_page_count) else
                $fatal("MMU:free rsp id %d is not valid, aligned size is not equal",rsp.free_rsp_id);
            end 
            if(fail_rsp)begin
                total_fail_free_req++;
                on_flight_free_req--;
                this.clear_free_req(req);
                ->print_trigger;
                continue;
            end
            //3. check the ram, the range [free_rsp_page_idx,free_rsp_page_idx+free_req_page_count-1] must not be 0
            ram_samaphore.get();
            for (int i=req.free_req_page_idx; i<req.free_req_page_idx + aligned_page_size; i++) begin
                assert (ram[i] !=0) else $fatal("MMU:free rsp id %d is not valid, page idx %d is not equal to the alloc id",rsp.free_rsp_id,i);
                ram[i] = 0;
            end
            ram_samaphore.put();
            //3.remove the req from the free_req_map
            total_success_free_req++;
            on_flight_free_req--;

            page_use_samaphore.get();
            page_in_use -= req.free_req_page_count;
            current_memory_usage = page_in_use*1.0/TOTAL_MEMORY_PAGE_IDX;

            all_freed_memory_size += req.free_req_page_count * 512;//512 bytes per page
            //the gap time is current ns,change to second
            gap_time = $time - start_time;
            ave_free_memory_per_sec = all_freed_memory_size*1.0/(gap_time*1.0e-9)/(`GB);


            page_use_samaphore.put();

            this.clear_free_req(req);
            ->print_trigger;
        end
    end
    endtask
endclass 



interface mmu_if(input clk);
    //some default parameters 
    logic rst_n;
    logic alloc_req_submit;
    logic [`REQ_ID_WIDTH-1:0] alloc_req_id;
    logic [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_req_page_count;
    logic free_req_submit;
    logic [`REQ_ID_WIDTH-1:0] free_req_id;
    logic [`ALL_PAGE_IDX_WIDTH-1:0] free_req_page_idx;
    logic [`REQ_SIZE_TYPE_WIDTH-1:0] free_req_page_count;
    logic alloc_rsp_pop;
    logic free_rsp_pop;
    logic [`REQ_ID_WIDTH-1:0] alloc_rsp_id;
    logic [`ALL_PAGE_IDX_WIDTH-1:0] alloc_rsp_page_idx;
    logic alloc_rsp_fail;
    logic [`FAIL_REASON_WIDTH-1:0] alloc_rsp_fail_reason;
    logic [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_rsp_origin_size; //may not aligned
    logic [`REQ_SIZE_TYPE_WIDTH-1:0] alloc_rsp_actual_size; //aligned size

    logic [`REQ_ID_WIDTH-1:0] free_rsp_id;
    logic free_rsp_fail;
    logic [`FAIL_REASON_WIDTH-1:0] free_rsp_fail_reason;
    logic [`REQ_SIZE_TYPE_WIDTH-1:0] free_rsp_origin_size;
    logic [`REQ_SIZE_TYPE_WIDTH-1:0] free_rsp_actual_size;

    logic alloc_req_fifo_full;
    logic free_req_fifo_full;
    logic alloc_rsp_fifo_not_empty;
    logic free_rsp_fifo_not_empty;

    clocking cb @(posedge clk);
        default input #1step output #0;
        output rst_n;
        output alloc_req_submit;
        output alloc_req_id;
        output alloc_req_page_count;
        output free_req_submit;
        output free_req_id;
        output free_req_page_idx;
        output free_req_page_count;
        output alloc_rsp_pop;
        output free_rsp_pop;
        input alloc_rsp_id;
        input alloc_rsp_page_idx;
        input alloc_rsp_fail;
        input alloc_rsp_fail_reason;
        input alloc_rsp_origin_size;
        input alloc_rsp_actual_size;
        input free_rsp_id;
        input free_rsp_fail;
        input free_rsp_fail_reason;
        input free_rsp_origin_size;
        input free_rsp_actual_size;
        input alloc_req_fifo_full;
        input free_req_fifo_full;
        input alloc_rsp_fifo_not_empty;
        input free_rsp_fifo_not_empty;
    endclocking

endinterface

//alloc test define
`define PATTERN_ALL_4K 1
`define PATTERN_ALL_2K 2
`define PATTERN_ALL_1K 3
`define PATTERN_ALL_512 4
`define PATTERN_VALID_MIX 5 
`define RANDOM_ALIGNED_MIX 8
`define RANDOM_NOT_ALIGNED_MIX 6
`define RANDOM_ALIGNED_MAY_INVALID_MIX 7
`define RANDOM_NOT_ALIGNED_MAY_INVALID_MIX 9
//free test define
`define FREE_EQUAL_ALLOC 1 //equal with the alloc, no error expect,may be not aligned
`define FREE_SPLIT_ALLOC 2 //split the alloc into more part
`define FREE_INVALID 3 //maybe 0 or over 4k
`define NO_FREE 4 //not free the alloc


module mmu_tree_tb;

    timeunit 1ns;       
    timeprecision 1ps;  

    localparam CLK_PERIOD = 2ns;
    localparam SEED = 158;
    localparam MAX_REQ_SIZE = 16384;
    localparam NEED_SHUFFLE = 0;
    localparam PRESSURE_TEST = 0;
    localparam DEFAULT_ALLOC_MODE = `PATTERN_ALL_4K;
    localparam DEFAULT_FREE_MODE = `NO_FREE;
    localparam PRESSURE_TEST_PER_PACKET = 128;
    // localparam MAX_TIME_OUT = 4000_000; //4000_000 ns
    localparam MAX_TIME_OUT = 0; //ulimit ns
    localparam FREE_SUBMIT_LATENCY = 5;//default 1 ,same as the alloc latency
    localparam FREE_RSP_LATENCY = 1;//default2:make free fifo full,make sure the free finish when alloc finish
    localparam ALLOC_RSP_LATENCY = 1; //default2:simulate the dsa, if the pop method is slow
    localparam INIT_ALLOC_REQUEST_SIZE = `INIT_ALLOC_REQUEST_SIZE;

    localparam RAMDOM_512_WEIGHT = 25;
    localparam RAMDOM_1K_WEIGHT = 25;
    localparam RAMDOM_2K_WEIGHT = 25;
    localparam RAMDOM_4K_WEIGHT = 25;

    bit clk, rst;
    
    //some test fifo
    alloc_req alloc_req_fifo[$]; 
    free_req free_req_fifo[$];
    mailbox checked_alloc_rsp_box; //tester can use this alloc rsp to generate free request
    mailbox alloc_rsp_box; //communicate to the checker
    mailbox free_rsp_box;
    reg [`REQ_ID_WIDTH:0] last_alloc_req_id;
    reg [`REQ_ID_WIDTH:0] last_free_req_id;
    semaphore alloc_req_fifo_semaphore;
    semaphore free_req_fifo_semaphore;
    MemoryChecker memory_checker;
    event alloc_req_fifo_empty;

    initial begin
        clk = 0;
        forever begin
            #CLK_PERIOD clk = ~clk;
        end
    end
    initial begin
        //set all ram in module to 0
        top.mmu_tree_inst.find_table_inst.fdt_1k.memory = '{default:0};
        top.mmu_tree_inst.find_table_inst.fdt_2k.memory = '{default:0};
        top.mmu_tree_inst.find_table_inst.fdt_4k.memory = '{default:0};
        top.mmu_tree_inst.find_table_inst.fdt_512.memory = '{default:0};

        top.mmu_tree_inst.and_tree_inst.at_tree_1k.dpram_inst.memory = '{default:0};
        top.mmu_tree_inst.and_tree_inst.at_tree_2k.dpram_inst.memory = '{default:0};
        top.mmu_tree_inst.and_tree_inst.at_tree_4k.dpram_inst.memory = '{default:0};
        top.mmu_tree_inst.and_tree_inst.at_tree_512.dpram_inst.memory = '{default:0};

        top.mmu_tree_inst.or_tree_inst.or_tree_ram.spram_inst.memory = '{default:0};
    end
    initial begin
        begin
            $fsdbDumpfile("mmu_tree.fsdb"); 
            $fsdbDumpvars(0,"+all");  
            $fsdbDumpSVA(0);   
            $fsdbDumpMDA(0);  
            $fsdbDumpClassObject("mmu_tree_tb.memory_checker","+object_level=2");
	    end
	end

    mmu_if mif(clk);

    //here init all global variables
    initial begin
        checked_alloc_rsp_box = new();
        alloc_rsp_box = new();
        free_rsp_box = new();//here
        last_alloc_req_id = 1;
        last_free_req_id = 1;
        alloc_req_fifo_semaphore = new(1);
        free_req_fifo_semaphore = new(1);
        memory_checker = new(alloc_rsp_box,free_rsp_box,checked_alloc_rsp_box);
    end


    initial begin
        mif.cb.rst_n <= 0;
        repeat(10) @(mif.cb);
        mif.cb.rst_n <= 1;
    end
    
    mmu_top top(
        .clk(mif.clk),
        .rst_n(mif.rst_n),
        //input
        .alloc_req_submit(mif.alloc_req_submit),
        .alloc_req_id(mif.alloc_req_id),
        .alloc_req_page_count(mif.alloc_req_page_count),
    
        .free_req_submit(mif.free_req_submit),
        .free_req_id(mif.free_req_id),
        .free_req_page_idx(mif.free_req_page_idx),
        .free_req_page_count(mif.free_req_page_count),
    
        .alloc_rsp_pop(mif.alloc_rsp_pop),
        .free_rsp_pop(mif.free_rsp_pop),
    
        //output
        .alloc_rsp_id(mif.alloc_rsp_id),
        .alloc_rsp_page_idx(mif.alloc_rsp_page_idx),
        .alloc_rsp_fail(mif.alloc_rsp_fail),
        .alloc_rsp_fail_reason(mif.alloc_rsp_fail_reason),
        .alloc_rsp_origin_size(mif.alloc_rsp_origin_size),
        .alloc_rsp_actual_size(mif.alloc_rsp_actual_size),

        .free_rsp_id(mif.free_rsp_id),
        .free_rsp_fail(mif.free_rsp_fail),
        .free_rsp_fail_reason(mif.free_rsp_fail_reason),
        .free_rsp_origin_size(mif.free_rsp_origin_size),
        .free_rsp_actual_size(mif.free_rsp_actual_size),
    
        .alloc_req_fifo_full(mif.alloc_req_fifo_full),
        .free_req_fifo_full(mif.free_req_fifo_full),
    
        .alloc_rsp_fifo_not_empty(mif.alloc_rsp_fifo_not_empty),
        .free_rsp_fifo_not_empty(mif.free_rsp_fifo_not_empty)
    );

    //the entry point of the test,wait for 50 cycles, then start the test
    initial begin
        repeat (50) @(mif.cb);//wait the mmu reset
        $display("MMU:start the test, time:%0t", $time);
        //check do we have pressure test
        if (!PRESSURE_TEST)begin
            alloc_requeset_generator(DEFAULT_ALLOC_MODE,INIT_ALLOC_REQUEST_SIZE);
        end else begin
            fork
                begin
                    alloc_request_gen_thread();
                end
            join_none
        end

        //join any, include a timeout check
        fork
            alloc_request_consume_thread();
            alloc_rsp_pop_thread();
            free_request_generator_thread();
            free_request_consume_thread();
            free_rsp_pop_thread();
            memory_checker.check_alloc_rsp_thread();
            memory_checker.check_free_rsp_thread();
            memory_checker_report_thread();
            memory_checker_check_test_over_thread();
        join_any
    end

    task memory_checker_report_thread();
    begin
        while (1) begin  
            memory_checker.print_static_thread();
        end        
    end
endtask

    task memory_checker_check_test_over_thread();
    begin
        bit over;
        while(1)begin
            repeat(100) @(mif.cb);
            memory_checker.test_over_check(over);
            if (over) begin
                $display("MMU:Test over, time:%0t ns", $time);
                $finish;
            end
            if ($time > MAX_TIME_OUT && MAX_TIME_OUT!=0) begin
                $display("MMU:Test time out, time:%0t ns", $time);
                $finish;
            end
        end 
    end
    endtask

    
    //ok now we start write the thread
    task alloc_request_gen_thread();
    begin
        alloc_requeset_generator(DEFAULT_ALLOC_MODE,INIT_ALLOC_REQUEST_SIZE);
        while (PRESSURE_TEST) begin
            //use event here, to wait a able alloc, to play as a flow control
            @alloc_req_fifo_empty;
            //generate PRESSURE_TEST_PER_PACKET request
            alloc_requeset_generator(DEFAULT_ALLOC_MODE,PRESSURE_TEST_PER_PACKET);
        end
    end
    endtask

    task alloc_request_consume_thread();
    begin
        //fetch the request from the alloc_req_fifo, and submit to the mmu
        //if mmu alloc request alloc fifo is not full, then trigger the event
        alloc_req req;
        while (1) begin
            alloc_req_fifo_semaphore.get();
            if (alloc_req_fifo.size()==0) begin
                alloc_req_fifo_semaphore.put();
                ->alloc_req_fifo_empty;
                @(mif.cb);
                continue;
            end
            req = alloc_req_fifo.pop_front();
            memory_checker.register_alloc_req(req);
            alloc_req_fifo_semaphore.put();
            wait(mif.cb.alloc_req_fifo_full == 0) @(mif.cb);
            mif.cb.alloc_req_submit <= 1;
            mif.cb.alloc_req_id <= req.alloc_req_id;
            mif.cb.alloc_req_page_count <= req.alloc_req_page_count;
            @(mif.cb);
            mif.cb.alloc_req_submit <= 0;//submit keep 1 cycle

            //wait 3 cycle to generate the free request
            repeat(1) @(mif.cb);
        end
    end
    endtask

    task alloc_rsp_pop_thread();
    begin
        alloc_rsp rsp;
        while (1) begin
            fetch_alloc_rsp(rsp);
            memory_checker.alloc_rsp_box.put(rsp);
        end
    end
    endtask

    //free come from alloc, so we dont need to worry about infinite free request
    task free_request_generator_thread();
    begin
        alloc_rsp rsp;
        //do a wait, simulate the memory in using
        while (DEFAULT_FREE_MODE!=`NO_FREE) begin
            //read from the checked_alloc_rsp_box, generate the free request
            checked_alloc_rsp_box.get(rsp);
            free_request_generator(rsp,DEFAULT_FREE_MODE);
        end
    end
    endtask

    task free_request_consume_thread();
    begin
        //fetch the request from the free_req_fifo, and submit to the mmu
        //if mmu free request fifo is not full, then trigger the event
        free_req req;
        while (1) begin
            free_req_fifo_semaphore.get();
            if (free_req_fifo.size()==0) begin
                free_req_fifo_semaphore.put();
                @(mif.cb);
                continue;
            end
            req = free_req_fifo.pop_front();
            memory_checker.register_free_req(req);
            free_req_fifo_semaphore.put();
            wait(mif.cb.free_req_fifo_full == 0) @(mif.cb);
            mif.cb.free_req_submit <= 1;
            mif.cb.free_req_id <= req.free_req_id;
            mif.cb.free_req_page_idx <= req.free_req_page_idx;
            mif.cb.free_req_page_count <= req.free_req_page_count;
            @(mif.cb);
            mif.cb.free_req_submit <= 0;//submit keep 1 cycle

            //wait 3 cycle to generate the alloc request
            repeat(FREE_SUBMIT_LATENCY) @(mif.cb);
        end
    end
    endtask

    task free_rsp_pop_thread();
    begin
        free_rsp rsp;
        while (1) begin
            fetch_free_rsp(rsp);
            memory_checker.free_rsp_box.put(rsp);
        end
    end
    endtask
    

    task  free_request_generator(
        input alloc_rsp rsp,
        input integer free_mode
    );
        begin
        free_req req;
        integer i;
        integer rand_invalid;
        case (free_mode)
        `FREE_EQUAL_ALLOC:
            begin
                req.free_req_id = last_free_req_id;
                last_free_req_id++;
                if (last_free_req_id>MAX_REQ_SIZE -1) begin
                    last_free_req_id = 1;
                end
                req.free_req_page_idx = rsp.alloc_rsp_page_idx;//use the prev not aligned page idx
                req.free_req_page_count = rsp.alloc_request_size;
                free_req_fifo_semaphore.get();
                free_req_fifo.push_back(req);
                free_req_fifo_semaphore.put();
            end
        `FREE_SPLIT_ALLOC:
            begin
                //we must generate aligned free request, 512 not spilt,1k split 2 512
                //2k split 2 1k,4k split 4 * 1k
                case (rsp.alloc_request_aligned_size)
                `REQ_512:
                    begin
                        req.free_req_id = last_free_req_id;
                        last_free_req_id++;
                        if (last_free_req_id>MAX_REQ_SIZE -1) begin
                            last_free_req_id = 1;
                        end
                        req.free_req_page_idx = rsp.alloc_rsp_page_idx;//use the prev not aligned page idx
                        req.free_req_page_count = 1;
                        free_req_fifo_semaphore.get();
                        free_req_fifo.push_back(req);
                        free_req_fifo_semaphore.put();
                    end
                `REQ_1K:
                    begin
                        for (i=0; i<2; i++) begin
                            req.free_req_id = last_free_req_id;
                            last_free_req_id++;
                            if (last_free_req_id>MAX_REQ_SIZE -1) begin
                                last_free_req_id = 1;
                            end
                            req.free_req_page_idx = rsp.alloc_rsp_page_idx + i;
                            req.free_req_page_count = 1;
                            free_req_fifo_semaphore.get();
                            free_req_fifo.push_back(req);
                            free_req_fifo_semaphore.put();
                        end
                    end
                `REQ_2K:
                    begin
                        for (i=0; i<2; i++) begin
                            req.free_req_id = last_free_req_id;
                            last_free_req_id++;
                            if (last_free_req_id>MAX_REQ_SIZE -1) begin
                                last_free_req_id = 1;
                            end
                            req.free_req_page_idx = rsp.alloc_rsp_page_idx + i*2;
                            req.free_req_page_count = 2;
                            free_req_fifo_semaphore.get();
                            free_req_fifo.push_back(req);
                            free_req_fifo_semaphore.put();
                        end
                    end
                `REQ_4K:
                    begin
                        for (i=0; i<4; i++) begin
                            req.free_req_id = last_free_req_id;
                            last_free_req_id++;
                            if (last_free_req_id>MAX_REQ_SIZE -1) begin
                                last_free_req_id = 1;
                            end
                            req.free_req_page_idx = rsp.alloc_rsp_page_idx + i*2;
                            req.free_req_page_count = 2;
                            free_req_fifo_semaphore.get();
                            free_req_fifo.push_back(req);
                            free_req_fifo_semaphore.put();
                        end
                    end
                endcase 
            end
        `FREE_INVALID:
            begin
                //make 1/10 to generate over 4k or 0 request
                //every time we generate a invalid request, we must follow a valid request
                rand_invalid = $urandom_range(0,20);
                if (rand_invalid==0||rand_invalid==20) begin
                    req.free_req_id = last_free_req_id;
                    last_free_req_id++;
                    if (last_free_req_id>MAX_REQ_SIZE -1) begin
                        last_free_req_id = 1;
                    end
                    req.free_req_page_idx = rsp.alloc_rsp_page_idx;//use the prev not aligned page idx
                    if (rand_invalid==0) begin
                        req.free_req_page_count = 0; //invalid equal zero
                    end else begin
                        req.free_req_page_count = 9; //invalid over 4k
                    end
                    free_req_fifo_semaphore.get();
                    free_req_fifo.push_back(req);
                    free_req_fifo_semaphore.put();
                end
                //a correct free is need, so we generate a correct free request
                req.free_req_id = last_free_req_id;
                last_free_req_id++;
                if (last_free_req_id>MAX_REQ_SIZE -1) begin
                    last_free_req_id = 1;
                end
                req.free_req_page_idx = rsp.alloc_rsp_page_idx;//use the prev not aligned page idx
                req.free_req_page_count = rsp.alloc_request_size;//correct to free the memory
                free_req_fifo_semaphore.get();
                free_req_fifo.push_back(req);
                free_req_fifo_semaphore.put();
            end
        endcase
    end
    endtask

    
    //generate the alloc request base on the mode
    task alloc_requeset_generator(
        integer type_to_gen,
        integer size_to_gen
    );
        begin
            integer alloc_size_array[4];
            alloc_size_array = '{0, 0, 0, 0};
            case(type_to_gen)
                `PATTERN_ALL_4K,`PATTERN_ALL_2K,`PATTERN_ALL_1K,`PATTERN_ALL_512:
                begin
                    case(type_to_gen)
                        `PATTERN_ALL_4K: alloc_size_array[3] = size_to_gen;
                        `PATTERN_ALL_2K: alloc_size_array[2] = size_to_gen;
                        `PATTERN_ALL_1K: alloc_size_array[1] = size_to_gen;
                        `PATTERN_ALL_512: alloc_size_array[0] = size_to_gen;
                    endcase
                    generate_alloc_request_fifo_pattern(alloc_size_array,NEED_SHUFFLE);            
                end
                `PATTERN_VALID_MIX:
                begin
                    alloc_size_array[3] = size_to_gen/4;
                    alloc_size_array[2] = size_to_gen/4;
                    alloc_size_array[1] = size_to_gen/4;
                    alloc_size_array[0] = size_to_gen/4;
                    generate_alloc_request_fifo_pattern(alloc_size_array,NEED_SHUFFLE);
                end
                `RANDOM_ALIGNED_MIX:
                begin
                    generate_alloc_request_fifo_random(size_to_gen,0,0);
                end
                `RANDOM_NOT_ALIGNED_MIX:
                begin
                    generate_alloc_request_fifo_random(size_to_gen,0,1);
                end
                `RANDOM_ALIGNED_MAY_INVALID_MIX:
                begin
                    generate_alloc_request_fifo_random(size_to_gen,1,0);
                end
                `RANDOM_NOT_ALIGNED_MAY_INVALID_MIX:
                begin
                    generate_alloc_request_fifo_random(size_to_gen,1,1);
                end
            endcase
        end        
    endtask 


    //generate the fix pattern alloc request and push into the fifo
    task automatic generate_alloc_request_fifo_pattern(
        input integer alloc_size_array[4],//4k,2k,1k,512 count
        input bit need_suffle = 1
    );
        begin
            reg [`REQ_SIZE_TYPE_WIDTH-1:0] page_count;
            alloc_req req;
            integer i,j,p;
            integer total_size;
            total_size = alloc_size_array[3]+alloc_size_array[2]+alloc_size_array[1]+alloc_size_array[0];
            assert (total_size <= MAX_REQ_SIZE) else $fatal("MMU:alloc request fifo size is not enough");
            if(!need_suffle)begin
                for (j=0;j<4;j++) begin
                    page_count = 1 << j;
                    for(i=0;i<alloc_size_array[j];i++) begin
                        req.alloc_req_id = last_alloc_req_id;
                        req.alloc_req_page_count = page_count;    
                        last_alloc_req_id++;
                        if(last_alloc_req_id>MAX_REQ_SIZE -1)begin
                            last_alloc_req_id=1; //id can not be 0
                        end
                        alloc_req_fifo_semaphore.get();
                        alloc_req_fifo.push_back(req);
                        alloc_req_fifo_semaphore.put();
                    end
                end
            end else begin
                //use a dynamic array to store the request
                alloc_req req_array[] = new [total_size];
                p = 0;
                for (j=0;j<4;j++) begin
                    page_count = 1 << j;
                    for(i=0;i<alloc_size_array[j];i++) begin
                        req.alloc_req_id = last_alloc_req_id;
                        req.alloc_req_page_count = page_count;    
                        last_alloc_req_id++;
                        if(last_alloc_req_id>MAX_REQ_SIZE -1)begin
                            last_alloc_req_id=1; //id can not be 0
                        end
                        req_array[p] = req;
                        p++;
                    end
                end
                //shuffle the request
                req_array.shuffle();
                //push the request into the fifo
                alloc_req_fifo_semaphore.get();
                foreach(req_array[i]) begin
                    alloc_req_fifo.push_back(req_array[i]);
                end
                alloc_req_fifo_semaphore.put();
            end
        end
    endtask

    //generate alloc request fifo, 
    task  generate_alloc_request_fifo_random(
        input integer total_size,
        input bit can_be_invalid = 0,
        input bit can_be_not_aligned = 0
    );
        begin
            integer i,j;
            integer random_page_count;
            alloc_req req;
            integer weight;
            assert (total_size <= MAX_REQ_SIZE) else $fatal("MMU:alloc request fifo size is not enough");
            for(i=0;i<total_size;i++) begin
                req.alloc_req_id = last_alloc_req_id;
                last_alloc_req_id++;
                if (last_alloc_req_id>MAX_REQ_SIZE -1) begin //id can not be 0
                    last_alloc_req_id = 1;
                end
                //we have a 1,2,4,8 weight, and the random value need generate from this weight
                //here generate the random page count
                weight = $urandom_range(0,100);
                if (can_be_not_aligned) begin
                    if (weight < RAMDOM_512_WEIGHT) begin
                        random_page_count = 1;
                    end else if (weight < RAMDOM_512_WEIGHT+RAMDOM_1K_WEIGHT) begin
                        random_page_count = 2;
                    end else if (weight < RAMDOM_512_WEIGHT+RAMDOM_1K_WEIGHT+RAMDOM_2K_WEIGHT) begin
                        random_page_count = $urandom_range(3,4);
                    end else begin
                        random_page_count = $urandom_range(5,8);
                    end
                end else begin
                    if (weight < RAMDOM_512_WEIGHT) begin
                        random_page_count = 1;
                    end else if (weight < RAMDOM_512_WEIGHT+RAMDOM_1K_WEIGHT) begin
                        random_page_count = 2;
                    end else if (weight < RAMDOM_512_WEIGHT+RAMDOM_1K_WEIGHT+RAMDOM_2K_WEIGHT) begin
                        random_page_count = 4;
                    end else begin
                        random_page_count = 8;
                    end
                end

                if(can_be_invalid)begin
                    j=$urandom_range(0,50);
                    if(j==0)begin
                        random_page_count = 0; //zero
                    end else if(j==50) begin
                        random_page_count = 9; //over 4k
                    end
                end
                req.alloc_req_page_count = random_page_count;
                alloc_req_fifo_semaphore.get();
                alloc_req_fifo.push_back(req);
                alloc_req_fifo_semaphore.put();
            end
        end
    endtask

    task fetch_alloc_rsp(
        output alloc_rsp rsp
    );
        begin
            //wait free rsp fifo empty
            wait (mif.cb.free_rsp_fifo_not_empty == 0);
            wait (mif.cb.alloc_rsp_fifo_not_empty == 1) @(mif.cb);
            mif.cb.alloc_rsp_pop <= 1; //we have read the alloc rsp, then pop it
            @(mif.cb);
            mif.cb.alloc_rsp_pop <= 0;
            repeat(ALLOC_RSP_LATENCY)@(mif.cb);
            rsp.alloc_rsp_id = mif.cb.alloc_rsp_id;
            rsp.alloc_rsp_page_idx = mif.cb.alloc_rsp_page_idx;
            rsp.alloc_rsp_fail = mif.cb.alloc_rsp_fail;
            rsp.alloc_rsp_fail_reason = mif.cb.alloc_rsp_fail_reason;
            rsp.alloc_request_size = mif.cb.alloc_rsp_origin_size;
            rsp.alloc_request_aligned_size = mif.cb.alloc_rsp_actual_size;
        end
    endtask

    task fetch_free_rsp(
        output free_rsp rsp
    );
        begin
            wait (mif.cb.free_rsp_fifo_not_empty == 1)@(mif.cb);
            mif.cb.free_rsp_pop <= 1; //we have read the free rsp, then pop it
            @(mif.cb);
            mif.cb.free_rsp_pop <= 0;
            repeat(FREE_RSP_LATENCY) @(mif.cb);
            rsp.free_rsp_id = mif.cb.free_rsp_id;
            rsp.free_rsp_fail = mif.cb.free_rsp_fail;
            rsp.free_rsp_fail_reason = mif.cb.free_rsp_fail_reason;
            rsp.free_rsp_origin_page_count = mif.cb.free_rsp_origin_size;
            rsp.free_rsp_aligned_page_count = mif.cb.free_rsp_actual_size;
        end
    endtask

endmodule
