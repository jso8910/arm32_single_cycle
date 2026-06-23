`timescale 1ns / 1ps

module arm32_sum_tb;

    reg clk;
    reg rst;

    integer failures;
    integer cycle_count;
    integer halt_hits;

    reg timed_out;

    parameter MAX_CYCLES = 20000;

    parameter ARRAY_ADDR = 32'h00000040;

    /*
     * Address of:
     *
     * finished:
     *     b finished
     *
     * For the array-summation program previously given, this is 0x20.
     */
    parameter HALT_PC = 32'h00000020;

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

    task begin_reset;
        begin
            rst = 0;

            /*
             * Allow all synchronous reset logic to observe reset.
             */
            repeat (3)
                @(posedge clk);

            #1;

            clear_memories;

            $readmemh(
                "workloads/sum/imem.mem",
                uut.inst_mem.MEM,
                0,
                255
            );
        end
    endtask

    /*
     * Reset must be released before directly writing the register file.
     *
     * The inputs are written shortly after a falling edge, leaving almost
     * a complete half-cycle before the processor's next rising edge.
     */
    task start_program;
        input [31:0] array_address;
        input [31:0] array_length;

        begin
            @(negedge clk);

            rst = 1;

            #1;

            uut.regfile_inst.regarray[0] = array_address;
            uut.regfile_inst.regarray[1] = array_length;
        end
    endtask

    task wait_for_halt;
        begin
            cycle_count = 0;
            halt_hits = 0;
            timed_out = 0;

            /*
             * A pipelined processor may fetch one or more instructions after
             * the branch before returning to HALT_PC. Therefore, count visits
             * to HALT_PC rather than requiring the PC to remain constant.
             */
            while ((halt_hits < 3) &&
                   (cycle_count < MAX_CYCLES)) begin

                @(posedge clk);
                #1;

                if (uut.pc === HALT_PC)
                    halt_hits = halt_hits + 1;

                cycle_count = cycle_count + 1;
            end

            if (cycle_count >= MAX_CYCLES) begin
                timed_out = 1;
                failures = failures + 1;

                $display(
                    "[FAIL] Array summation timed out: PC=0x%08x r0=0x%08x r1=0x%08x r2=0x%08x r3=0x%08x",
                    uut.pc,
                    uut.regfile_inst.regarray[0],
                    uut.regfile_inst.regarray[1],
                    uut.regfile_inst.regarray[2],
                    uut.regfile_inst.regarray[3]
                );
            end
        end
    endtask

    task run_sum_case;
        input integer case_number;

        integer length;
        integer failures_before;

        reg [31:0] expected_result;

        begin
            failures_before = failures;

            begin_reset;

            case (case_number)
                /*
                 * Empty array:
                 *
                 * sum = 0
                 */
                0: begin
                    length = 0;
                    expected_result = 32'h00000000;
                end

                /*
                 * [1, 2, 3, 4, 5]
                 *
                 * sum = 15
                 */
                1: begin
                    length = 5;

                    write_word(ARRAY_ADDR + 0, 32'h00000001);
                    write_word(ARRAY_ADDR + 4, 32'h00000002);
                    write_word(ARRAY_ADDR + 8, 32'h00000003);
                    write_word(ARRAY_ADDR + 12, 32'h00000004);
                    write_word(ARRAY_ADDR + 16, 32'h00000005);

                    expected_result = 32'h0000000f;
                end

                /*
                 * [-5, 10, -3, 7]
                 *
                 * sum = 9
                 */
                2: begin
                    length = 4;

                    write_word(ARRAY_ADDR + 0, 32'hfffffffb);
                    write_word(ARRAY_ADDR + 4, 32'h0000000a);
                    write_word(ARRAY_ADDR + 8, 32'hfffffffd);
                    write_word(ARRAY_ADDR + 12, 32'h00000007);

                    expected_result = 32'h00000009;
                end

                /*
                 * 0xffffffff + 1 wraps to zero.
                 */
                3: begin
                    length = 2;

                    write_word(ARRAY_ADDR + 0, 32'hffffffff);
                    write_word(ARRAY_ADDR + 4, 32'h00000001);

                    expected_result = 32'h00000000;
                end

                /*
                 * 0x7fffffff + 1 = 0x80000000
                 */
                4: begin
                    length = 2;

                    write_word(ARRAY_ADDR + 0, 32'h7fffffff);
                    write_word(ARRAY_ADDR + 4, 32'h00000001);

                    expected_result = 32'h80000000;
                end

                default: begin
                    length = 0;
                    expected_result = 32'h00000000;
                end
            endcase

            /*
             * Do this only after reset has been released.
             */
            start_program(ARRAY_ADDR, length);

            wait_for_halt;

            if (!timed_out) begin
                if (uut.regfile_inst.regarray[2] !== expected_result) begin
                    failures = failures + 1;

                    $display(
                        "[FAIL] Sum case %0d: expected 0x%08x, got 0x%08x",
                        case_number,
                        expected_result,
                        uut.regfile_inst.regarray[2]
                    );
                end
            end

            if (failures == failures_before) begin
                $display(
                    "[PASS] Sum case %0d: result 0x%08x in %0d cycles",
                    case_number,
                    uut.regfile_inst.regarray[2],
                    cycle_count
                );
            end
        end
    endtask

    initial begin
        clk = 0;
        rst = 0;
        failures = 0;

        run_sum_case(0);
        run_sum_case(1);
        run_sum_case(2);
        run_sum_case(3);
        run_sum_case(4);

        if (failures == 0) begin
            $display("All array summation tests passed.");
        end
        else begin
            $display(
                "Array summation tests completed with %0d failure(s).",
                failures
            );
        end

        $finish;
    end

    initial begin
        $dumpfile("arm32_sum.vcd");
        $dumpvars(0, arm32_sum_tb);
    end

endmodule
