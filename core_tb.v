`timescale 1ns / 1ps
module arm32_core_tb;

    // 1. Signals
    reg clk;
    reg rst;

    // 2. Instantiate the Unit Under Test (UUT)
    arm32_core_system uut (
        .clk(clk),
        .rst(rst)
    );

    // 3. Clock Generation (100MHz)
    always #5 clk = ~clk;

    // 4. Stimulus Block
    integer prev_pc;
    integer prev_prev_pc;
    initial begin
        for (integer i = 0; i < 64; i++) begin
            // Initialize signals
            clk = 0;
            rst = 0;

            // Hold reset for a few cycles
            #20;
            rst = 1;

            $readmemh("workloads/binsearch/dmem.mem", uut.dram.MEM, 0, 255);
            $readmemh("workloads/binsearch/imem.mem", uut.inst_mem.MEM, 0, 255);

            uut.regfile_inst.regarray[0] = i; // Load some initial values into register as input

            prev_pc = -4;
            prev_prev_pc = -8;
            // If PC is the same as it was 2 cycles ago, we've hit an infinite loop
            while (uut.pc != prev_prev_pc) begin
                prev_prev_pc = prev_pc;
                prev_pc = uut.pc;
                @(posedge clk);
            end
            // $display("%d:\t%d\t%d\t%d\t%d", uut.pc, uut.regfile_inst.regarray[0], uut.regfile_inst.regarray[1], uut.regfile_inst.regarray[2], uut.regfile_inst.regarray[3]);
            if (uut.regfile_inst.regarray[1] != i) begin
                $display("Test failed for input %d: expected %d, got %d", i, i, uut.regfile_inst.regarray[1]);
            end
        end
        
        $display("Simulation finished. Check waveforms for results.");
        $finish;
    end

    // // 5. Optional: Dump waveforms for viewing in GTKWave or Vivado
    initial begin
        $dumpfile("arm32_simulation.vcd");
        $dumpvars(0, arm32_core_tb);
    end

endmodule
