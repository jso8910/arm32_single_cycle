`include "params.vh"

module extender
#(parameter IN_WIDTH = `IMM_WIDTH, parameter TOT_WIDTH = `DWIDTH, parameter EXT_WIDTH = TOT_WIDTH - IN_WIDTH)
(
    input [IN_WIDTH-1:0]        ext_in,
    input                       ExtOp,  // zext (0) vs sext (1)
    output [TOT_WIDTH-1:0]      ext_out
);
    assign ext_out = ExtOp ? {{ EXT_WIDTH{ext_in[IN_WIDTH-1]} }, ext_in} : {{ EXT_WIDTH{1'b0} }, ext_in};
endmodule