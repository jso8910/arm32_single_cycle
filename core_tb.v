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
    initial begin
        // Initialize signals
        clk = 0;
        rst = 0;

        // Hold reset for a few cycles
        #20;
        rst = 1;
        
        $display("Reset de-asserted. Starting simulation...");

        // Note: In a real ARM core, you'd load a program into memory here.
        // For a "very basic" test, we can use 'hierarchical references' 
        // to force values directly into your internal register file.
        $readmemh("test.mem", uut.dram.MEM);
        $readmemh("test.mem", uut.inst_mem.MEM);

        @(posedge clk);
        $display("%d:\t%d\t%d\t%d\t%d", uut.pc, uut.regfile_inst.regarray[0], uut.regfile_inst.regarray[1], uut.regfile_inst.regarray[2], uut.regfile_inst.regarray[14]);
        @(posedge clk);
        $display("%d:\t%d\t%d\t%d\t%d", uut.pc, uut.regfile_inst.regarray[0], uut.regfile_inst.regarray[1], uut.regfile_inst.regarray[2], uut.regfile_inst.regarray[14]);
        @(posedge clk);
        $display("%d:\t%d\t%d\t%d\t%d", uut.pc, uut.regfile_inst.regarray[0], uut.regfile_inst.regarray[1], uut.regfile_inst.regarray[2], uut.regfile_inst.regarray[14]);
        @(posedge clk);
        $display("%d:\t%d\t%d\t%d\t%d", uut.pc, uut.regfile_inst.regarray[0], uut.regfile_inst.regarray[1], uut.regfile_inst.regarray[2], uut.regfile_inst.regarray[14]);
        @(posedge clk);
        $display("%d:\t%d\t%d\t%d\t%d", uut.pc, uut.regfile_inst.regarray[0], uut.regfile_inst.regarray[1], uut.regfile_inst.regarray[2], uut.regfile_inst.regarray[14]);
        @(posedge clk);
        $display("%d:\t%d\t%d\t%d\t%d", uut.pc, uut.regfile_inst.regarray[0], uut.regfile_inst.regarray[1], uut.regfile_inst.regarray[2], uut.regfile_inst.regarray[14]);
        @(posedge clk);
        $display("%d:\t%d\t%d\t%d\t%d", uut.pc, uut.regfile_inst.regarray[0], uut.regfile_inst.regarray[1], uut.regfile_inst.regarray[2], uut.regfile_inst.regarray[14]);
        @(posedge clk);
        $display("%d:\t%d\t%d\t%d\t%d", uut.pc, uut.regfile_inst.regarray[0], uut.regfile_inst.regarray[1], uut.regfile_inst.regarray[2], uut.regfile_inst.regarray[14]);
        @(posedge clk);
        $display("%d:\t%d\t%d\t%d\t%d", uut.pc, uut.regfile_inst.regarray[0], uut.regfile_inst.regarray[1], uut.regfile_inst.regarray[2], uut.regfile_inst.regarray[14]);
        @(posedge clk);
        $display("%d:\t%d\t%d\t%d\t%d", uut.pc, uut.regfile_inst.regarray[0], uut.regfile_inst.regarray[1], uut.regfile_inst.regarray[2], uut.regfile_inst.regarray[14]);
        @(posedge clk);
        $display("%d:\t%d\t%d\t%d\t%d", uut.pc, uut.regfile_inst.regarray[0], uut.regfile_inst.regarray[1], uut.regfile_inst.regarray[2], uut.regfile_inst.regarray[14]);
        @(posedge clk);
        $display("%d:\t%d\t%d\t%d\t%d", uut.pc, uut.regfile_inst.regarray[0], uut.regfile_inst.regarray[1], uut.regfile_inst.regarray[2], uut.regfile_inst.regarray[14]);
        @(posedge clk);
        $display("%d:\t%d\t%d\t%d\t%d", uut.pc, uut.regfile_inst.regarray[0], uut.regfile_inst.regarray[1], uut.regfile_inst.regarray[2], uut.regfile_inst.regarray[14]);
        @(posedge clk);
        $display("%d:\t%d\t%d\t%d\t%d", uut.pc, uut.regfile_inst.regarray[0], uut.regfile_inst.regarray[1], uut.regfile_inst.regarray[2], uut.regfile_inst.regarray[14]);

        
        // @(posedge clk);
        // $display("%d", $signed(uut.regfile_inst.regarray[0]));
        // @(posedge clk);
        // $display("%d", $signed(uut.regfile_inst.regarray[0]));
        // @(posedge clk);
        // $display("%d", $signed(uut.regfile_inst.regarray[1]));
        // @(posedge clk);
        // $display("%d", $signed(uut.regfile_inst.regarray[2]));
        // @(posedge clk);
        // $display("%d", $signed(uut.regfile_inst.regarray[2]));
        // @(posedge clk);
        // $display("%d", $signed(uut.regfile_inst.regarray[2]));
        // @(posedge clk);
        // $display("%d", uut.regfile_inst.regarray[2]);
        // @(posedge clk);
        // $display("%d", $signed(uut.regfile_inst.regarray[2]));
        // @(posedge clk);
        // $display("%d", $signed(uut.regfile_inst.regarray[2]));
        // @(posedge clk);
        // $display("%d", $signed(uut.regfile_inst.regarray[2]));
        // @(posedge clk);
        // $display("%d", $signed(uut.regfile_inst.regarray[2]));
        // @(posedge clk);
        // $display("%d", $signed(uut.regfile_inst.regarray[2]));
        // @(posedge clk);
        // $display("%d", $signed(uut.regfile_inst.regarray[2]));
        // @(posedge clk);
        // $display("%d", $signed(uut.regfile_inst.regarray[2]));
        // @(posedge clk);
        // $display("%d", $signed(uut.regfile_inst.regarray[2]));
        // @(posedge clk);
        // $display("%d", $signed(uut.regfile_inst.regarray[2]));
        // $display("%b", uut.alu_op);
        
        // #100;
        
        $display("Simulation finished. Check waveforms for results.");
        $finish;
    end

    // // 5. Optional: Dump waveforms for viewing in GTKWave or Vivado
    initial begin
        $dumpfile("arm32_simulation.vcd");
        $dumpvars(0, arm32_core_tb);
    end

endmodule
