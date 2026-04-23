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
    input                       is_imm_rot, // Whether `in` comes from an immediate operand. If it does, don't do RRX
    input                       cin,        // Previous carry value from CPSR
    output reg [IN_WIDTH-1:0]   result,
    output reg                  cout        // cout is the LSB that was shifted out
);
    // Unit used for instructions where the register Rm is shifted by Rs's bottom 8 bits
    reg [IN_WIDTH*2 - 1:0] in_double;
    always @(*) begin
        // Only support shifting by 1 on this modified core
        if (amount == 8'b1) begin
            case (func)
                `LSR: begin
                    in_double = {{IN_WIDTH{1'b0}}, in};
                    result = in_double[amount +: IN_WIDTH];
                    cout = in_double[amount - 1];
                end
                // Unsupported operation, assume no shifts
                default: begin
                    in_double = {in, in};
                    result = in;
                    cout = 1'b0;
                end
            endcase
        end else if (amount == 8'b0 && func == `LSR) begin
            // LSR #0 is actually LSR #32
            in_double = {in, in};
            result = {IN_WIDTH{1'b0}};
            cout = in[31];
        end else begin
            in_double = {in, in};
            result = in;
            cout = 1'b0;
        end
    end
endmodule