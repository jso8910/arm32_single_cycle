`timescale 1ns / 1ps

module arm32_sort_tb;

    reg clk;
    reg rst;

    integer failures;
    integer cycle_count;

    reg timed_out;

    parameter MAX_CYCLES = 20000;

    parameter ARRAY_ADDR = 32'h00000040;
    parameter HALT_PC = 32'h0000004c;

    reg [31:0] expected [0:15];

    arm32_core_system uut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    task clear_memories;
        integer index;
        begin
            for (index = 0; index < 256; index = index + 1) begin
                uut.dram.MEM[index] = 8'h00;
                uut.inst_mem.MEM[index] = 8'h00;
            end
        end
    endtask

    task write_word;
        input integer byte_address;
        input [31:0] value;
        begin
            uut.dram.MEM[byte_address + 0] = value[7:0];
            uut.dram.MEM[byte_address + 1] = value[15:8];
            uut.dram.MEM[byte_address + 2] = value[23:16];
            uut.dram.MEM[byte_address + 3] = value[31:24];
        end
    endtask

    function [31:0] read_word;
        input integer byte_address;
        begin
            read_word = {
                uut.dram.MEM[byte_address + 3],
                uut.dram.MEM[byte_address + 2],
                uut.dram.MEM[byte_address + 1],
                uut.dram.MEM[byte_address + 0]
            };
        end
    endfunction

    task prepare_test;
        begin
            rst = 0;

            repeat (2)
                @(posedge clk);

            #1;

            clear_memories;

            $readmemh(
                "workloads/sort/imem.mem",
                uut.inst_mem.MEM,
                0,
                255
            );
        end
    endtask

    task release_reset;
        begin
            @(negedge clk);
            rst = 1;
        end
    endtask

    task wait_for_halt;
        begin
            cycle_count = 0;
            timed_out = 0;

            while ((uut.pc !== HALT_PC) &&
                   (cycle_count < MAX_CYCLES)) begin
                @(posedge clk);
                #1;

                cycle_count = cycle_count + 1;
            end

            if (cycle_count >= MAX_CYCLES) begin
                timed_out = 1;
                failures = failures + 1;

                $display(
                    "[FAIL] Sort timed out at PC 0x%08x",
                    uut.pc
                );
            end
        end
    endtask

    task run_sort_case;
        input integer case_number;

        integer length;
        integer check_count;
        integer index;
        integer failures_before;

        begin
            failures_before = failures;

            prepare_test;

            case (case_number)
                0: begin
                    length = 0;
                    check_count = 1;

                    write_word(ARRAY_ADDR, 32'hdeadbeef);
                    expected[0] = 32'hdeadbeef;
                end

                1: begin
                    length = 1;
                    check_count = 1;

                    write_word(ARRAY_ADDR + 0, 32'd42);

                    expected[0] = 32'd42;
                end

                2: begin
                    length = 5;
                    check_count = 5;

                    write_word(ARRAY_ADDR + 0, 32'd7);
                    write_word(ARRAY_ADDR + 4, 32'hfffffffe);
                    write_word(ARRAY_ADDR + 8, 32'd5);
                    write_word(ARRAY_ADDR + 12, 32'd1);
                    write_word(ARRAY_ADDR + 16, 32'd3);

                    expected[0] = 32'hfffffffe;
                    expected[1] = 32'd1;
                    expected[2] = 32'd3;
                    expected[3] = 32'd5;
                    expected[4] = 32'd7;
                end

                3: begin
                    length = 8;
                    check_count = 8;

                    write_word(ARRAY_ADDR + 0, 32'd4);
                    write_word(ARRAY_ADDR + 4, 32'd4);
                    write_word(ARRAY_ADDR + 8, 32'hffffffff);
                    write_word(ARRAY_ADDR + 12, 32'd9);
                    write_word(ARRAY_ADDR + 16, 32'd0);
                    write_word(ARRAY_ADDR + 20, 32'hffffffff);
                    write_word(ARRAY_ADDR + 24, 32'd2);
                    write_word(ARRAY_ADDR + 28, 32'd8);

                    expected[0] = 32'hffffffff;
                    expected[1] = 32'hffffffff;
                    expected[2] = 32'd0;
                    expected[3] = 32'd2;
                    expected[4] = 32'd4;
                    expected[5] = 32'd4;
                    expected[6] = 32'd8;
                    expected[7] = 32'd9;
                end

                default: begin
                    length = 0;
                    check_count = 0;
                end
            endcase

            uut.regfile_inst.regarray[0] = ARRAY_ADDR;
            uut.regfile_inst.regarray[1] = length;

            release_reset;
            wait_for_halt;

            if (!timed_out) begin
                for (index = 0; index < check_count; index = index + 1) begin
                    if (read_word(ARRAY_ADDR + 4*index) !== expected[index]) begin
                        failures = failures + 1;

                        $display(
                            "[FAIL] Sort case %0d, element %0d: expected 0x%08x, got 0x%08x",
                            case_number,
                            index,
                            expected[index],
                            read_word(ARRAY_ADDR + 4*index)
                        );
                    end
                end
            end

            if (failures == failures_before)
                $display("[PASS] Sort case %0d", case_number);
        end
    endtask

    initial begin
        clk = 0;
        rst = 0;
        failures = 0;

        run_sort_case(0);
        run_sort_case(1);
        run_sort_case(2);
        run_sort_case(3);

        if (failures == 0)
            $display("All sorting tests passed.");
        else
            $display(
                "Sorting tests completed with %0d failure(s).",
                failures
            );

        $finish;
    end

    initial begin
        $dumpfile("arm32_sort.vcd");
        $dumpvars(0, arm32_sort_tb);
    end

endmodule
