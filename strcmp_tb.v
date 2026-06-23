`timescale 1ns / 1ps

module arm32_strcmp_tb;

    reg clk;
    reg rst;

    integer failures;
    integer cycle_count;

    reg timed_out;

    parameter MAX_CYCLES = 20000;

    parameter STRING1_ADDR = 32'h00000040;
    parameter STRING2_ADDR = 32'h00000080;
    parameter HALT_PC = 32'h0000003c;

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

    task write_byte;
        input integer byte_address;
        input [7:0] value;

        begin
            uut.dram.MEM[byte_address] = value;
        end
    endtask

    task write_empty;
        input integer address;
        begin
            write_byte(address + 0, 8'h00);
        end
    endtask

    task write_app;
        input integer address;
        begin
            write_byte(address + 0, 8'h61);
            write_byte(address + 1, 8'h70);
            write_byte(address + 2, 8'h70);
            write_byte(address + 3, 8'h00);
        end
    endtask

    task write_apple;
        input integer address;
        begin
            write_byte(address + 0, 8'h61);
            write_byte(address + 1, 8'h70);
            write_byte(address + 2, 8'h70);
            write_byte(address + 3, 8'h6c);
            write_byte(address + 4, 8'h65);
            write_byte(address + 5, 8'h00);
        end
    endtask

    task write_apply;
        input integer address;
        begin
            write_byte(address + 0, 8'h61);
            write_byte(address + 1, 8'h70);
            write_byte(address + 2, 8'h70);
            write_byte(address + 3, 8'h6c);
            write_byte(address + 4, 8'h79);
            write_byte(address + 5, 8'h00);
        end
    endtask

    task write_banana;
        input integer address;
        begin
            write_byte(address + 0, 8'h62);
            write_byte(address + 1, 8'h61);
            write_byte(address + 2, 8'h6e);
            write_byte(address + 3, 8'h61);
            write_byte(address + 4, 8'h6e);
            write_byte(address + 5, 8'h61);
            write_byte(address + 6, 8'h00);
        end
    endtask

    task prepare_test;
        begin
            rst = 0;

            repeat (2)
                @(posedge clk);

            #1;

            clear_memories;

            $readmemh(
                "workloads/strcmp/imem.mem",
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
                    "[FAIL] String comparison timed out at PC 0x%08x",
                    uut.pc
                );
            end
        end
    endtask

    task run_strcmp_case;
        input integer case_number;

        reg [31:0] expected_result;
        integer failures_before;

        begin
            failures_before = failures;

            prepare_test;

            case (case_number)
                0: begin
                    write_apple(STRING1_ADDR);
                    write_apple(STRING2_ADDR);
                    expected_result = 32'd0;
                end

                1: begin
                    write_apple(STRING1_ADDR);
                    write_apply(STRING2_ADDR);
                    expected_result = 32'hffffffff;
                end

                2: begin
                    write_banana(STRING1_ADDR);
                    write_apple(STRING2_ADDR);
                    expected_result = 32'd1;
                end

                3: begin
                    write_app(STRING1_ADDR);
                    write_apple(STRING2_ADDR);
                    expected_result = 32'hffffffff;
                end

                4: begin
                    write_apple(STRING1_ADDR);
                    write_app(STRING2_ADDR);
                    expected_result = 32'd1;
                end

                5: begin
                    write_empty(STRING1_ADDR);
                    write_empty(STRING2_ADDR);
                    expected_result = 32'd0;
                end

                default: begin
                    write_empty(STRING1_ADDR);
                    write_empty(STRING2_ADDR);
                    expected_result = 32'd0;
                end
            endcase

            uut.regfile_inst.regarray[0] = STRING1_ADDR;
            uut.regfile_inst.regarray[1] = STRING2_ADDR;

            release_reset;
            wait_for_halt;

            if (!timed_out &&
                uut.regfile_inst.regarray[2] !== expected_result) begin

                failures = failures + 1;

                $display(
                    "[FAIL] String comparison case %0d: expected 0x%08x, got 0x%08x",
                    case_number,
                    expected_result,
                    uut.regfile_inst.regarray[2]
                );
            end

            if (failures == failures_before)
                $display(
                    "[PASS] String comparison case %0d",
                    case_number
                );
        end
    endtask

    initial begin
        clk = 0;
        rst = 0;
        failures = 0;

        run_strcmp_case(0);
        run_strcmp_case(1);
        run_strcmp_case(2);
        run_strcmp_case(3);
        run_strcmp_case(4);
        run_strcmp_case(5);

        if (failures == 0)
            $display("All string comparison tests passed.");
        else
            $display(
                "String comparison tests completed with %0d failure(s).",
                failures
            );

        $finish;
    end

    initial begin
        $dumpfile("arm32_strcmp.vcd");
        $dumpvars(0, arm32_strcmp_tb);
    end

endmodule
