`include "params.vh"

module nextPcLogic(
    input [31:0]	this_pc,
    input 	jal_flag,
    input 	jump,
    input 	br_flag,
    input 	br_taken,

    input [12:0] br_imm,

    input [31:0] jalr_target,
    input [31:0] jal_target,


    output [31:0]	next_pc
);
endmodule