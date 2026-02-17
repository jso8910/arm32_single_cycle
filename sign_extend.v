`include "params.vh"

module extender
#(parameter EXT_WIDTH = DWIDTH - IMM_WIDTH;)
(
    input [IMM_WIDTH-1:0]   ext_in,
    input                   ExtOp,
    output [DWIDTH-1:0]     ext_out
);
endmodule