`include "params.vh"
module mux_2_to_1
#(parameter MWIDTH = DWIDTH)
(
    input [MWIDTH-1:0]  in_1,
    input [MWIDTH-1:0]  in_2,
    input               sel,
    output [MWIDTH-1:0] out
);
    assign out = sel ? in_1 : in_2;
endmodule