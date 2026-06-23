`timescale 1ns / 1ps

module arm32_matmul_tb;

    reg clk;
    reg rst;

    integer failures;
    integer cycle_count;

    reg timed_out;

    parameter MAX_CYCLES = 100000;

    parameter A_ADDR = 32'h00000020;
    parameter B_ADDR = 32'h00000060;
    parameter C_ADDR = 32'h000000a0;
    parameter HALT_PC = 32'h00000068;

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
                "workloads/matmul/imem.mem",
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
                    "[FAIL] Matrix multiplication timed out at PC 0x%08x",
                    uut.pc
                );
            end
        end
    endtask

    task run_matmul_case;
        input integer case_number;

        integer m;
        integer n;
        integer p;
        integer output_count;
        integer index;
        integer failures_before;

        begin
            failures_before = failures;

            prepare_test;

            case (case_number)
                0: begin
                    m = 2;
                    n = 3;
                    p = 2;
                    output_count = 4;

                    write_word(A_ADDR + 0, 32'd1);
                    write_word(A_ADDR + 4, 32'd2);
                    write_word(A_ADDR + 8, 32'd3);
                    write_word(A_ADDR + 12, 32'd4);
                    write_word(A_ADDR + 16, 32'd5);
                    write_word(A_ADDR + 20, 32'd6);

                    write_word(B_ADDR + 0, 32'd7);
                    write_word(B_ADDR + 4, 32'd8);
                    write_word(B_ADDR + 8, 32'd9);
                    write_word(B_ADDR + 12, 32'd10);
                    write_word(B_ADDR + 16, 32'd11);
                    write_word(B_ADDR + 20, 32'd12);

                    expected[0] = 32'd58;
                    expected[1] = 32'd64;
                    expected[2] = 32'd139;
                    expected[3] = 32'd154;
                end

                1: begin
                    m = 2;
                    n = 2;
                    p = 2;
                    output_count = 4;

                    write_word(A_ADDR + 0, 32'hffffffff);
                    write_word(A_ADDR + 4, 32'd2);
                    write_word(A_ADDR + 8, 32'd3);
                    write_word(A_ADDR + 12, 32'hfffffffc);

                    write_word(B_ADDR + 0, 32'd5);
                    write_word(B_ADDR + 4, 32'hfffffffa);
                    write_word(B_ADDR + 8, 32'd7);
                    write_word(B_ADDR + 12, 32'd8);

                    expected[0] = 32'd9;
                    expected[1] = 32'd22;
                    expected[2] = 32'hfffffff3;
                    expected[3] = 32'hffffffce;
                end

                2: begin
                    m = 1;
                    n = 3;
                    p = 1;
                    output_count = 1;

                    write_word(A_ADDR + 0, 32'd2);
                    write_word(A_ADDR + 4, 32'd3);
                    write_word(A_ADDR + 8, 32'd4);

                    write_word(B_ADDR + 0, 32'hffffffff);
                    write_word(B_ADDR + 4, 32'd5);
                    write_word(B_ADDR + 8, 32'd2);

                    expected[0] = 32'd21;
                end

                3: begin
                    m = 2;
                    n = 0;
                    p = 3;
                    output_count = 6;

                    expected[0] = 32'd0;
                    expected[1] = 32'd0;
                    expected[2] = 32'd0;
                    expected[3] = 32'd0;
                    expected[4] = 32'd0;
                    expected[5] = 32'd0;
                end

                default: begin
                    m = 0;
                    n = 0;
                    p = 0;
                    output_count = 0;
                end
            endcase

            for (index = 0; index < output_count; index = index + 1)
                write_word(C_ADDR + 4*index, 32'hdeadbeef);

            uut.regfile_inst.regarray[0] = A_ADDR;
            uut.regfile_inst.regarray[1] = B_ADDR;
            uut.regfile_inst.regarray[2] = C_ADDR;
            uut.regfile_inst.regarray[3] = m;
            uut.regfile_inst.regarray[4] = n;
            uut.regfile_inst.regarray[5] = p;

            release_reset;
            wait_for_halt;

            if (!timed_out) begin
                for (index = 0; index < output_count; index = index + 1) begin
                    if (read_word(C_ADDR + 4*index) !== expected[index]) begin
                        failures = failures + 1;

                        $display(
                            "[FAIL] Matmul case %0d, output %0d: expected 0x%08x, got 0x%08x",
                            case_number,
                            index,
                            expected[index],
                            read_word(C_ADDR + 4*index)
                        );
                    end
                end
            end

            if (failures == failures_before)
                $display(
                    "[PASS] Matrix multiplication case %0d",
                    case_number
                );
        end
    endtask

    initial begin
        clk = 0;
        rst = 0;
        failures = 0;

        run_matmul_case(0);
        run_matmul_case(1);
        run_matmul_case(2);
        run_matmul_case(3);

        if (failures == 0)
            $display("All matrix multiplication tests passed.");
        else
            $display(
                "Matrix multiplication tests completed with %0d failure(s).",
                failures
            );

        $finish;
    end

    initial begin
        $dumpfile("arm32_matmul.vcd");
        $dumpvars(0, arm32_matmul_tb);
    end

endmodule
