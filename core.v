`include "params.vh"

module arm32_core(
    input clk,
    input rst
);
    // Net declarations
    // ---Fetch
    wire [`WWIDTH-1:0] this_pc;
    wire [`WWIDTH-1:0] next_pc;
    wire [`WWIDTH-1:0] next_pc_seq;

    // ---Register file
    wire [`WWIDTH-1:0] reg_b;

    // ---Decoder
    wire [`IWIDTH-1:0] inst;
    wire cs_data;
    wire imm_flag;
    wire pc_op;
    wire set_cpsr;
    wire [3:0] condition_code;
    wire we_data;
    wire wr_en_a, wr_en_b;
    wire [3:0] wr_addr_a, wr_addr_b;
    wire [3:0] rd_addr_a, rd_addr_b, rd_addr_c, rd_addr_d;
    wire [1:0] op2_shift_func;
    wire [7:0] op2_imm_shift_by;
    wire op2_is_imm_shift;
    wire [`WWIDTH-1:0] imm_val;
    wire [1:0] address_gen_mode;
    wire [2:0] load_addressing_mode;
    wire mem_op;
    wire [3:0] pc_offset;
    wire [4:0] alu_op;

    //--ALU
    wire [`WWIDTH-1:0] op_a, op_b, op_c, op_d;
    reg [3:0] prev_nzcv;
    wire shifter_cout;
    wire [31:0] alu_out_1, alu_out_2;
    wire [3:0] nzcv;
    wire condition_fulfilled;

    //--SRAM
    wire [`DWIDTH-1:0] dram_dout;

    // Data RAM
    sram dram (
        .dataOut(dram_dout),
        .func(load_addressing_mode),
        .dataIn(op_d),
        .cs(cs),
        .we(we_data),
        .clk(clk),
        .addr(address_gen_mode[0] ? alu_out_1[7:0] : op_a[7:0])  // If pre_index/offset, use alu output
    );

    // Fetch logic

    nextPcLogic pcgen(
        .this_pc(this_pc),
        .pc_mod(alu_out_1),
        .pc_write(pc_op & condition_fulfilled),
        .next_pc(next_pc),
        .next_pc_seq(next_pc_seq)
    );

    fetchLogic fetch(
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .this_pc(this_pc),
        .inst(inst)
    );

    // Register file
    regfile regfile_inst (
        .wr_addr_a(wr_addr_a),
        .wr_addr_b(wr_addr_b),
        .rd_addr_a(rd_addr_a),
        .rd_addr_b(rd_addr_b),
        .rd_addr_c(rd_addr_c),
        .rd_addr_d(rd_addr_d),
        .wr_en_a(wr_en_a & condition_fulfilled),
        .wr_en_b(wr_en_b & condition_fulfilled),
        .clk(clk),
        .rst(rst),
        .pc_offset(pc_offset),
        .next_pc(next_pc_seq),
        .data_in_a(alu_out_1),
        .data_in_b(mem_op ? dram_dout : alu_out_2),
        .reg_a(op_a),
        .reg_b(reg_b),
        .reg_c(op_c),
        .reg_d(op_d)
    );

    // Shifter
    register_shift_unit register_shift_unit_op2 (
        .in(imm_flag ? imm_val : reg_b),
        .func(op2_shift_func),
        .amount(op2_is_imm_shift ? op2_imm_shift_by : op_c[7:0]),
        .is_imm_rot(imm_flag),
        .cin(prev_nzcv[1]),
        .result(op_b),
        .cout(shifter_cout)
    );

    // ALU definitions
    alu alu_inst (
        .op_a(op_a),
        .op_b(op_b),
        .op_c(op_c),
        .op_d(op_d),
        .func(alu_op),
        .prev_nzcv(prev_nzcv),
        .shifter_cout(shifter_cout),
        .alu_out_1(alu_out_1),
        .alu_out_2(alu_out_2),
        .nzcv(nzcv)
    );

    // Conditional unit
    condition_unit cond(
        .nzcv(prev_nzcv),
        .condition_code(condition_code),
        .cond_met(condition_fulfilled)
    );

    // Decoder definitions

    decode decode_inst (
        .inst(inst),
        .next_pc(next_pc_seq),
        .cs_data(cs_data),
        .imm_flag(imm_flag),
        .we_data(we_data),
        .wr_en_a(wr_en_a),
        .wr_en_b(wr_en_b),
        .pc_op(pc_op),
        .set_cpsr(set_cpsr),
        .condition_code(condition_code),
        .alu_op(alu_op),
        .wr_addr_a(wr_addr_a),
        .wr_addr_b(wr_addr_b),
        .rd_addr_a(rd_addr_a),
        .rd_addr_b(rd_addr_b),
        .rd_addr_c(rd_addr_c),
        .rd_addr_d(rd_addr_d),
        .op2_shift_func(op2_shift_func),
        .op2_imm_shift_by(op2_imm_shift_by),
        .op2_is_imm_shift(op2_is_imm_shift),
        .imm_val(imm_val),
        .address_gen_mode(address_gen_mode),
        .load_addressing_mode(load_addressing_mode),
        .mem_op(mem_op),
        .pc_offset(pc_offset)
    );

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            prev_nzcv <= 4'b0000;
        end else if (set_cpsr)
            prev_nzcv <= nzcv;
    end

endmodule

`timescale 1ns / 1ps

module arm32_core_tb;

    // 1. Signals
    reg clk;
    reg rst;

    // 2. Instantiate the Unit Under Test (UUT)
    arm32_core uut (
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
        $readmemh("test.mem", uut.fetch.inst_mem.MEM);
        
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
        while (uut.regfile_inst.regarray[3] == 0) begin
            @(posedge clk);
            $display("%d, %d, %b", $signed(uut.regfile_inst.regarray[2]), $signed(uut.regfile_inst.regarray[3]), uut.nzcv);
        end
        
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