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
        if (amount != 8'b0 && amount < IN_WIDTH) begin
            case (func)
                `LSL: begin
                    // Eg if in = 0101, in_double = 01010000
                    // Then to shift left, we start with the window starting at the end and shift the window right
                    in_double = {in, {IN_WIDTH{1'b0}}};
                    result = in_double[IN_WIDTH*2 - 1 - amount -: IN_WIDTH];
                    cout = in_double[IN_WIDTH*2 - amount];
                end
                `LSR: begin
                    in_double = {{IN_WIDTH{1'b0}}, in};
                    result = in_double[amount +: IN_WIDTH];
                    cout = in_double[amount - 1];
                end
                `ASR: begin
                    in_double = {{IN_WIDTH{in[IN_WIDTH-1]}}, in};
                    result = in_double[amount +: IN_WIDTH];
                    cout = in_double[amount - 1];
                end
                `ROR: begin
                    in_double = {in, in};
                    // Rotate by `amount`
                    result = in_double[amount +: IN_WIDTH];
                    cout = in_double[amount + IN_WIDTH];
                end
            endcase
        end else if (amount >= IN_WIDTH) begin
            // Shift by >= 32 is a special case
            case (func)
                `LSL: begin
                    in_double = {in, {IN_WIDTH{1'b0}}};
                    result = {IN_WIDTH{1'b0}};
                    cout = amount == IN_WIDTH ? in[0] : 1'b0;
                end
                `LSR: begin
                    in_double = {{IN_WIDTH{1'b0}}, in};
                    result = {IN_WIDTH{1'b0}};
                    cout = amount == IN_WIDTH ? in[IN_WIDTH - 1] : 1'b0;
                end
                `ASR: begin
                    in_double = {{IN_WIDTH{in[IN_WIDTH-1]}}, in};
                    result = {IN_WIDTH{in[IN_WIDTH - 1]}};;
                    cout = in[IN_WIDTH - 1];
                end
                `ROR: begin
                    in_double = {in, in};
                    // Rotate by `amount[3:0]` (ie amount % 32)
                    // NOTE: when changing the word width, this logic must be changed
                    result = in_double[amount[3:0] +: IN_WIDTH];
                    // cout is bit 31 if amount == 32
                    cout = amount == IN_WIDTH ? in[IN_WIDTH-1] : in_double[amount[3:0] + IN_WIDTH];
                end
            endcase
        end else if (func == `ROR && ~is_imm_rot) begin
            in_double = {in, in};
            // ROR #0 is RRX — rotated right by 1, but with bit 33 = CIN
            cout = in[0];
            result = {cin, in[31:1]};
        end else if (func == `LSR) begin
            // LSR #0 is actually LSR #32
            in_double = {in, in};
            result = {IN_WIDTH{1'b0}};
            cout = in[31];
        end else begin
            in_double = {in, in};
            result = in;
            cout = func == `LSL ? cin : 1'b0;   // If LSL 0, C bit is preserved
        end
    end
endmodule