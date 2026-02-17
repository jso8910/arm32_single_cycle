`include "params.vh"

module regfile
#(parameter RWIDTH = WWIDTH)
(
    input [4:0]         wr_addr,
    input [4:0] 	    rd_addr_a,
    input [4:0] 	    rd_addr_b,
    input 		        wr_en,
    input 		        clk,
    input 		        rst,
    input [RWIDTH-1:0]  data_in,
    output [RWIDTH-1:0] reg_a, reg_b
);
    // Register file with two read ports, and one write port
    // Asynchronous read, synchronous write
    // NOTE: I think I should write on "we" w/o a clock? Because I need to write to multiple registers per cycle
        // Eg mull (long) or any operation that involves updating the CPSR flags
    // TODO: make sure to change address size based on number of registers—pretty sure I only need 4 bits [3:0] for ARM32
        // But also I need to include non GPRs like CPSR, so there may be more
endmodule