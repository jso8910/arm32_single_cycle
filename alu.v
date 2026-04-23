`include "params.vh"

`define ALU_AND     5'b00000    // Op1 AND Op2
`define ALU_EOR     5'b00001    // Op1 XOR Op2
`define ALU_SUB     5'b00010    // Op1 - Op2
`define ALU_RSB     5'b00011    // Op2 - Op1
`define ALU_ADD     5'b00100    // Op1 + Op2
`define ALU_ADC     5'b00101    // Op1 + Op2 + C (CPSR)
`define ALU_SBC     5'b00110    // Op1 - Op2 + C - 1 (CPSR)
`define ALU_RSC     5'b00111    // Op2 - Op1 + C - 1 (CPSR) 
`define ALU_TST     5'b01000    // Op1 AND Op2: cond codes
`define ALU_TEQ     5'b01001    // Op1 EOR Op2: cond codes
`define ALU_CMP     5'b01010    // Op1 - Op2:   cond codes
`define ALU_CMN     5'b01011    // Op1 + Op2:   cond codes
`define ALU_ORR     5'b01100    // Op1 OR Op2
`define ALU_MOV     5'b01101    // Op2
`define ALU_BIC     5'b01110    // Op1 AND (NOT Op2)
`define ALU_MVN     5'b01111    // NOT Op2

`define ALU_MUL     5'b10000    // Rd <- Rm * Rs
`define ALU_MLA     5'b10001    // Rd <- Rm * Rs + Rn
`define ALU_UMULL   5'b10100    // {RdHi, RdLo} <- Rm * Rs (unsigned)
`define ALU_SMULL   5'b10110    // {RdHi, RdLo} <- Rm * Rs (signed)
`define ALU_UMLAL   5'b10101    // {RdHi, RdLo} <- Rm * Rs + {RdHi, RdLo} (unsigned)
`define ALU_SMLAL   5'b10111    // {RdHi, RdLo} <- Rm * Rs + {RdHi, RdLo} (signed)

module alu(
    input [31:0]        op_a, op_b,
    input [4:0]         func,
    input [3:0]         prev_nzcv,
    input               shifter_cout,
    output wire [31:0]  alu_out_1,
    output reg [3:0]    nzcv
);
    reg [32:0] res_long;
    always @(*) begin
        nzcv[3] = alu_out_1[31];  // Negative flag
        nzcv[2] = alu_out_1 == 32'b0;  // zero flag
        // Logical operations set to shifter output (which maintains previous carry if op is LSL #0)
        case (func)
            `ALU_MOV, `ALU_MVN: nzcv[1] = shifter_cout;
            default: nzcv[1] = res_long[32];
        endcase

        case (func)
            // Addition: (A and B same sign) AND (Result different sign)
            `ALU_ADD: //`ALU_ADC, `ALU_CMN: 
                nzcv[0] = (op_a[31] == op_b[31]) && (res_long[31] != op_a[31]);

            // Subtraction (A - B): (A and B different sign) AND (Result == B's sign)
            `ALU_SUB, `ALU_CMP: 
                nzcv[0] = (op_a[31] != op_b[31]) && (res_long[31] == op_b[31]);

            // Otherwise V is usually unaffected or unchanged
            default: nzcv[0] = prev_nzcv[0];
        endcase
    end

    always @(*) begin
        case (func)
            `ALU_SUB: res_long = {1'b0, op_a} + ~({1'b0, op_b}) + 1;
            `ALU_ADD: res_long = {1'b0, op_a} + op_b;
            `ALU_CMP: res_long = {1'b0, op_a} + ~({1'b0, op_b}) + 1;
            `ALU_MOV: res_long = op_b;
            `ALU_MVN: res_long = ~op_b;
            default: res_long = 64'bx;
        endcase
    end
    assign alu_out_1 = res_long[31:0];
endmodule