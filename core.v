`timescale 1ns / 1ps
`include "params.vh"

module arm32_core(
    input clk,
    input rst,
    input [`IWIDTH-1:0]     inst,
    input [`DWIDTH-1:0]     dram_dout,
    input [`WWIDTH-1:0]     op_a, reg_b, op_c, op_d,

    // Regfile inputs

    output                  condition_fulfilled,
    // DMEM controls
    output                  cs_data,
    output [2:0]            load_addressing_mode,
    output                  we_data,

    // Operand outputs

    // ALU outputs
    output [`DWIDTH-1:0]    alu_out_1, alu_out_2,

    // Regfile control signals
    output [3:0]            rd_addr_a, rd_addr_b, rd_addr_c, rd_addr_d,
    output [3:0]            wr_addr_a, wr_addr_b,
    output                  wr_en_a, wr_en_b,
    output [3:0]            pc_offset,
    output [`WWIDTH-1:0]    next_pc_seq,
    output [1:0]            address_gen_mode,

    // IMEM controls
    output [`AWIDTH-1:0] pc

);
    // Net declarations
    // ---Fetch
    wire [`WWIDTH-1:0] this_pc;
    wire [`WWIDTH-1:0] next_pc;

    // ---Decoder
    wire imm_flag;
    wire pc_op;
    wire set_cpsr;
    wire [3:0] condition_code;
    wire [1:0] op2_shift_func;
    wire [7:0] op2_imm_shift_by;
    wire op2_is_imm_shift;
    wire [`WWIDTH-1:0] imm_val;
    wire mem_op;
    wire [4:0] alu_op;

    //--ALU
    wire [`WWIDTH-1:0] op_b;
    reg [3:0] prev_nzcv;
    wire shifter_cout;
    wire [3:0] nzcv;
    // External memory control signals
    assign pc = this_pc;

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
        // We want to select the value from SRAM 
        .next_pc(next_pc),
        .this_pc(this_pc)
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
        .pc_offset(pc_offset),
    );

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            prev_nzcv <= 4'b0000;
        end else if (set_cpsr)
            prev_nzcv <= nzcv;
    end
endmodule

module arm32_core_system(
    input clk,
    input rst
);
    wire [`IWIDTH-1:0]     inst;
    wire [`DWIDTH-1:0]     dram_dout;
    wire [`WWIDTH-1:0]     op_a, reg_b, op_c, op_d;

    wire                  condition_fulfilled;
    // DMEM controls
    wire                  cs_data;
    wire [2:0]            load_addressing_mode;
    wire                  we_data;

    // Operand outputs

    // ALU outputs
    wire [`DWIDTH-1:0]    alu_out_1, alu_out_2;

    // Regfile control signals
    wire [3:0]            rd_addr_a, rd_addr_b, rd_addr_c, rd_addr_d;
    wire [3:0]            wr_addr_a, wr_addr_b;
    wire                  wr_en_a, wr_en_b;
    wire [3:0]            pc_offset;
    wire [`WWIDTH-1:0]    next_pc_seq;
    wire [1:0]            address_gen_mode;

    // Instruction memory
    wire [`AWIDTH-1:0] pc;
    wire [`DWIDTH-1:0] inst_mem_out;
    assign inst = inst_mem_out[`IWIDTH-1:0];
    sram inst_mem (
        .dataOut(inst_mem_out),
        .func(3'b010),   // Read a single word
        .dataIn({32{1'b0}}),
        .cs(1'b0),
        .we(1'b0),
        .clk(clk),
        .addr(pc[`AWIDTH-1:0]),
    );

    // Data memory
    sram dram (
        .dataOut(dram_dout),
        .func(load_addressing_mode),
        .dataIn(op_d),
        .cs(cs_data),
        .we(we_data & condition_fulfilled),
        .clk(clk),
        .addr(address_gen_mode[0] ? alu_out_1[7:0] : op_a[7:0])  // If pre_index/offset, use alu output
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
        .reg_d(op_d),
    );

    // CPU core
    arm32_core core_inst (
        .clk(clk),
        .rst(rst),
        .inst(inst),
        .dram_dout(dram_dout),
        .op_a(op_a), .reg_b(reg_b), .op_c(op_c), .op_d(op_d),
        .condition_fulfilled(condition_fulfilled),
        .cs_data(cs_data),
        .load_addressing_mode(load_addressing_mode),
        .we_data(we_data),
        .alu_out_1(alu_out_1), .alu_out_2(alu_out_2),
        .rd_addr_a(rd_addr_a), .rd_addr_b(rd_addr_b), .rd_addr_c(rd_addr_c), .rd_addr_d(rd_addr_d),
        .wr_addr_a(wr_addr_a), .wr_addr_b(wr_addr_b),
        .wr_en_a(wr_en_a), .wr_en_b(wr_en_b),
        .pc_offset(pc_offset),
        .next_pc_seq(next_pc_seq),
        .address_gen_mode(address_gen_mode),
        .pc(pc)
    );
endmodule