`include "params.vh"

module extender
#(parameter IN_WDITH = `IMM_WIDTH, parameter TOT_WIDTH = `DWIDTH, parameter EXT_WIDTH = TOT_WIDTH - IN_WDITH)
(
    input [IN_WDITH-1:0]        ext_in,
    input                       ExtOp,  // zext vs sext
    output [TOT_WIDTH-1:0]      ext_out
);
endmodule