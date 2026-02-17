`include "params.vh"

module sram
#(parameter SIZE = 2**AWIDTH;)
(
    output wire [DWIDTH-1:0]    dataOut,
    input [2:0]                 func,   // TODO: Figure out what func is and if it has an ARM equivalent. Seems like it might be byte vs hw vs word
    input [DWIDTH-1:0]          dataIn,
    input                       cs, we, clk,
    input [AWIDTH-1:0]          addr
);
    // Definition of SRAM module
    // Asynchronous read, synchronous write
endmodule