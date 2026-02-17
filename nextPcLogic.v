`include "params.vh"

module nextPcLogic(
    input [`WWIDTH-1:0]	this_pc,
    input [`WWIDTH-1:0]  pc_mod,     // If the PC is going to be anything other than PC+4, it is here
    input               pc_write,   // 1 if pc_mod should be taken as the value of the PC
    // input 	jal_flag,
    // input 	jump,
    // input 	br_flag,
    // input 	br_taken,

    // input [12:0] br_imm,

    // input [31:0] jalr_target,
    // input [31:0] jal_target,


    output [`WWIDTH-1:0]	next_pc
);
    // This is essentially just a mux for the PC — normally increment it,
    // otherwise drive it with the result from eg a branch
    // Recall, branches are calculated from next_pc
    assign next_pc = pc_write ? pc_mod : this_pc + 3'h4;
endmodule