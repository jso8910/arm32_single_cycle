`include "params.vh"

module alu(
    output wire [31:0]  alu_out,
    input [31:0]        op_a, op_b,
    input               add_or_sub,
    input               r_type,
    input [4:0]         shift,
    input [2:0]         func, // TODO probably need more funcs. will see when I implement decoder
    output wire         cout,
    input               br_taken_out,
    input               imm_flag,
    input               ld_str_flag,
    input               shift_type
);
endmodule