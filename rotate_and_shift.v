`include "params.vh"

`define LSL 2'b00
`define LSR 2'b01
`define ASR 2'b10
`define ROR 2'b11

module register_shift_unit
#(parameter IN_WIDTH = `WWIDTH)
(
    input [IN_WIDTH-1:0]        in,
    input [1:0]                 func,
    input [7:0]                 amount,
    input                       enable,
    output reg [IN_WIDTH-1:0]   result
);
    // Unit used for instructions where the register Rm is shifted by Rs's bottom 8 bits
    reg [IN_WIDTH*2 - 1:0] in_double;
    always @(*) begin
        if (enable) begin
            case (func)
                `LSL: begin
                    // Eg if in = 0101, in_double = 01010000
                    // Then to shift left, we start with the window starting at the end and shift the window right
                    in_double = {in, {IN_WIDTH{1'b0}}};
                    result = in_double[IN_WIDTH*2 - 1 - amount -: IN_WIDTH];
                end
                `LSR: begin
                    in_double = {{IN_WIDTH{1'b0}}, in};
                    result = in_double[amount +: IN_WIDTH];
                end
                `ASR: begin
                    in_double = {{IN_WIDTH{in[IN_WIDTH-1]}}, in};
                    result = in_double[amount +: IN_WIDTH];
                end
                `ROR: begin
                    in_double = {in, in};
                    // Rotate by `amount`
                    result = in_double[amount +: IN_WIDTH];
                end
            endcase
        end else
            result = in;
    end
endmodule

module immediate_rotate_unit
#(parameter OUT_WIDTH = `WWIDTH)
(
    input [7:0]             in,
    input [3:0]             amount,
    output [OUT_WIDTH-1:0]  result
);
    // Rotate unit used to rotate Imm12 values

    wire [OUT_WIDTH-1:0] zext_val;
    // Initialize zero extender
    extender #(.IN_WIDTH(8), .TOT_WIDTH(OUT_WIDTH)) zext_imm_rotate(.ext_in(in), .ExtOp(1'b0), .ext_out(zext_val));
    wire [OUT_WIDTH*2 - 1:0] in_double = {zext_val, zext_val};
    // Rotate right by 2*amount
    assign result = in_double[amount*2 +: OUT_WIDTH];
endmodule