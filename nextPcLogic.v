`include "params.vh"

module nextPcLogic(
    input [`WWIDTH-1:0]	this_pc,
    input [`WWIDTH-1:0]  pc_mod,     // If the PC is going to be anything other than PC+4, it is here
    input               pc_write,   // 1 if pc_mod should be taken as the value of the PC


    output wire [`WWIDTH-1:0]    next_pc_seq,    // Architectural next_pc
    output wire [`WWIDTH-1:0]    next_pc         // Actual next_pc
);
    // This is essentially just a mux for the PC — normally increment it,
    // otherwise drive it with the result from eg a branch
    // Recall, branches are calculated from next_pc
    assign next_pc_seq = this_pc + 4'h4;
    assign next_pc = pc_write ? pc_mod : this_pc + 4'h4;
endmodule