`include "params.vh"

// TODO: not yet implemented - block data transfer, single data swap


// TODO: I assume much of the interface of this decoder will have to be changed, since the instuction decoding is different
// I'll use my best judgement for what eg flags to use
// TODO: why is pc_plus4 generated in the decoder?
// TODO branch calculation unit should output the next_pc value if the branch isnt taken
        // or just AND the pc_op signal with the condition, probably easier. the pc_op signal (as well as write signals) can be an input to the conditional unit
// TODO: how should I deal with conditional data operations? this matters for the wr_en signals as well. AND the write signal with the condition?
    // Yes


// TODO I think my current approach for doing nothing with op2_shift_func doesn't work. Make sure carry bit is eg set correctly
    // Also make sure operation 00, #0 isn't one of the mneomics (pseudonyms?) for a different operation


// TODO: need mux logic for if the address == 15 to take the next_pc value
    // Yes. After all register file outputs. Maybe even in the register file?
    // ALSO include pc_offset as input to the register file


// TODO connect read port D to input of memory

// Address generation modes, P and W bits
// Bit 2 is the W bit (0 if no writeback)
// Bit 1 is the P bit (0 if postfix) 
`define PRE_INDEX   2'b11   // Use Rn, then update with Op3
`define POST_INDEX  2'b00   // W bit is redundant, always set to 0, but still writes
`define OFFSET      2'b01
`define NONPRIVILEGED_WRITE 2'b10  // not implemented, but used in privileged mode

// Load addressing modes. Eg HALF_WORD | SEXT
`define SEXT        3'b100
`define ZEXT        3'b000
`define BYTE        3'b000
`define HALF_WORD   3'b001
`define WORD        3'b010

// instuction encodings
`define BX_INST     24'h12FFF1
`define B_INST      3'b101
`define DATA_PROC_I 3'b001
`define DATA_PROC_R 3'b000
`define MUL_PART_A  6'b000000
`define MUL_PART_B  4'b1001
`define MULL_PART_A 5'b00001
`define SDT_START   2'b01
`define HW_TFR      2'b00
`define SHBIT_SWP   2'b00
`define BLOCK_TFR   3'b100
`define SWP_UPPER   5'b00010
`define SWP_LOWER   8'b00001001

// ALU operations
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

// Shift functions
`define LSL 2'b00
`define LSR 2'b01
`define ASR 2'b10
`define ROR 2'b11

module decode(
    input [`IWIDTH-1:0]         inst,
    input [`WWIDTH-1:0] 	    next_pc,

    output wire                 cs_data,
    output reg                  imm_flag,       // When imm_flag is set, rd_addr_b is ignored in place of imm_val ROR imm_rot_amt
                                we_data,
                                wr_en_a,
                                wr_en_b,
                                pc_op,          // Flag for whether r15 could be modified (potential branch or any operation with r15). Write signal
                                set_cpsr,
    output wire [3:0]           condition_code,
    output reg [4:0]            alu_op,

    // Operand addresses/generation information. wr is write signals for destinations, rd (read) is for sources
    output reg [3:0]            wr_addr_a, wr_addr_b,
    output reg [3:0]            rd_addr_a, rd_addr_b, rd_addr_c, rd_addr_d,
    output reg [1:0]            op2_shift_func,
    output reg [7:0]            op2_imm_shift_by,
    output reg                  op2_is_imm_shift,   // Defaults to 1 (with imm_shift_by = 0) to avoid any weird behavior. Selects between imm and reg_c
    output reg [`WWIDTH-1:0]      imm_val,
    output reg [1:0]            address_gen_mode,
    output reg [2:0]            load_addressing_mode,
    output reg                  mem_op,             // Is this a memory operation?
    output wire [3:0]           pc_offset           // If the PC is used as an operand, it will have 4 or 8 added to it (depending on the shift type)
);
    // ARMv4 decoder
    // User/privileged modes not implemented - all memory is accessible by anything
    // Thumb mode not implemented


    assign condition_code = inst[31:28];
    assign cs_data = 1'b0;  // CS is currently unused
    // If the shift value comes from an immediate, add 4 to PC, else add 8 to PC (when used as an operand)
    // This accounts for the PC+4+offset in a branch instuction
    // Keep in mind, when I say add 4 or 8 to PC, that means add 4 to next_pc. So it's actually an offset of 8 or 12 from the current instuction
    // For a bl instruction, we need to keep the original PC + 4
    assign pc_offset = inst[27:25] == `B_INST ? 4'd0 : (op2_is_imm_shift ? 4'd4 : 4'd8);

    always @(*) begin
        // This is probably going to end up being quite bad, but I'm curious to what extent a synthesis software would optimize it
        // Like I assume that there are better ways to do comparisons (eg identifying what parts of the instuction are unique or something)
        // but would a synthesizer identify that?

        if (inst[27:25] == `B_INST) begin
            pc_op = 1'b1;
            set_cpsr = 1'b0;

            // ALU operation
            // We are going to want to add the immediate offset (24 bits) to R15
            // So set rd_a = Rn, imm_val = 0
            alu_op = `ALU_ADD;
            imm_flag = 1'b1;
            // Must add 4 to the imm_val for the branch to work correctly
            imm_val = {{6{inst[23]}}, inst[23:0], 2'b00} + 4;  // 26 bit value, sign extended with 6 bits
            op2_shift_func = 2'b0;      // LSL is used as a placeholder, since LSL #0 has no meaning
            op2_imm_shift_by = 8'b0;
            op2_is_imm_shift = 1'b1;

            // Registers
            // No destination register here
            wr_en_a = 1'b0;
            wr_en_b = inst[24];     // Link bit - ALU outputs next_pc (in1) from out2 on an add operation
            wr_addr_a = 4'b0;
            wr_addr_b = 4'b1110;    // Link register
            rd_addr_a = 4'b1111;    // Operand 1 (added to immediate in this case) is PC
            rd_addr_b = 4'b0;
            rd_addr_c = 4'b0;
            rd_addr_d = 4'b0;

            // Memory
            mem_op = 1'b0;
            we_data = 1'b0;
            address_gen_mode = 2'b00;       // Irrelevant
            load_addressing_mode = 3'b000;  // Irrelevant
        end else if (inst[27:25] == `DATA_PROC_I) begin     // Immediate data processing instuction
            // These operations don't write their results
            if (inst[24:21] == `ALU_TST || inst[24:21] == `ALU_TEQ || inst[24:21] == `ALU_CMP || inst[24:21] == `ALU_CMN) begin
                pc_op = 1'b0;
                wr_en_a = 1'b0;
            end else begin
                pc_op = inst[15:12] == 4'b1111;    // If Rd is PC
                wr_en_a = ~pc_op;           // We won't use the register file write if it is a pc_op
            end
            set_cpsr = inst[20];

            // ALU operation
            alu_op = {1'b0, inst[24:21]};
            imm_flag = 1'b1;    // (inst[25])
            imm_val = {{24{1'b0}}, inst[7:0]};      // 8 bit immediate, zero extended to 32 bits
            op2_shift_func = `ROR;                  // Rotate the immediate
            op2_imm_shift_by = 8'b0;                // Immediate rotates are unsupported
            op2_is_imm_shift = 1'b1;

            // Registers
            wr_en_b = 1'b0;
            wr_addr_a = inst[15:12];   // Rd
            wr_addr_b = 4'b0;
            rd_addr_a = inst[19:16];   // Rn
            rd_addr_b = 4'b0;
            rd_addr_c = 4'b0;
            rd_addr_d = 4'b0;

            // Memory
            mem_op = 1'b0;
            we_data = 1'b0;
            address_gen_mode = 2'b00;       // Irrelevant
            load_addressing_mode = 3'b000;  // Irrelevant
        // Shifted register data processing instuction
        // The thing which differentiates this from other operations is that either bit 7 or 4 will be 0
        // Whereas in eg mul, inst[7:4] = 1001
        // The only other instuction with 27:25 == 000 and bit 7 == 0 is bx which has a unique 24:20 == 0b10010, which would imply a TEQ but S bit not set
        end else if (inst[27:25] == `DATA_PROC_R && (inst[7] == 0 || inst[4] ==  0) && inst[24:20] != 5'b10010) begin
            // These operations don't write their results
            if (inst[24:21] == `ALU_TST || inst[24:21] == `ALU_TEQ || inst[24:21] == `ALU_CMP || inst[24:21] == `ALU_CMN) begin
                pc_op = 1'b0;
                wr_en_a = 1'b0;
            end else begin
                pc_op = inst[15:12] == 4'b1111;    // If Rd is PC
                wr_en_a = ~pc_op;           // We won't use the register file write if it is a pc_op
            end
            set_cpsr = inst[20];

            // ALU operation
            alu_op = {1'b0, inst[24:21]};
            imm_flag = 1'b0;    // (inst[25])
            imm_val = 32'b0;
            op2_shift_func = inst[6:5];
            op2_imm_shift_by = {{3{1'b0}}, inst[11:7]};
            op2_is_imm_shift = ~inst[4];

            // Registers

            wr_en_b = 1'b0;
            wr_addr_a = inst[15:12];   // Rd
            wr_addr_b = 4'b0;
            rd_addr_a = inst[19:16];   // Rn
            rd_addr_b = inst[3:0];     // Rm
            rd_addr_c = inst[11:8];    // Rs (or a random slice of the immediate which will be ignoed, who knows!)
            rd_addr_d = 4'b0;

            // Memory
            mem_op = 1'b0;
            we_data = 1'b0;
            address_gen_mode = 2'b00;       // Irrelevant
            load_addressing_mode = 3'b000;  // Irrelevant
        // Single data load, starts with 01. But if 25 (1 if register) is 1 and 4 is 1 (should be 0 for shifted register), this is undefined
        end else if (inst[27:26] == `SDT_START && ~(inst[25] && inst[4])) begin
            pc_op = inst[15:12] == 4'b1111;    // Rd is PC. If Rn is PC, writeback cannot be specified
            set_cpsr = 1'b0;

            // Memory
            mem_op = 1'b1;
            we_data = ~inst[20];        // inst[20] is 1 if LDR, 0 if STR. So: negate
            address_gen_mode = {inst[21], inst[24]};
            // inst[22] is 0 if word, 1 if byte
            load_addressing_mode = `ZEXT | (inst[22] ? `BYTE : `WORD);

            // ALU operation
            // inst[23] indicates whether to do Rn + Offset or Rd - Offset
            alu_op = inst[23] ? `ALU_ADD : `ALU_SUB;
            imm_flag = ~inst[25];                               // inst[25] == 0 if immediate
            imm_val = {{20{1'b0}}, inst[11:0]};                 // 12 bit immediate, zero extended
            op2_shift_func = imm_flag ? 2'b00 : inst[6:5];      // A shift function, or LSL (00)
            op2_imm_shift_by = imm_flag ? 8'b0 : {{3{1'b0}}, inst[11:7]};
            op2_is_imm_shift = 1'b1;

            // Registers
            wr_en_a = ~(address_gen_mode == `OFFSET);   // All modes other than offset write
            wr_en_b = inst[20];         // 1 if LDR, 0 if STR
            wr_addr_a = inst[19:16];    // Rn, for writeback
            wr_addr_b = inst[15:12];    // Rd, for LDR operations
            rd_addr_a = inst[19:16];    // Rn
            rd_addr_b = inst[3:0];      // Rm - or nonsense if imm_flag
            rd_addr_c = 4'b0000;        // A register cannot be used as the shift
            rd_addr_d = inst[15:12];    // Rd - Read port D is connected to the input
        // Halfword data transfer, register offset. Explicitly excluding swap operations from this
        end else if (inst[27:25] == `HW_TFR && inst[22] == 1'b0 && inst[7] == 1'b1 && inst[4] == 1'b1 && inst[6:5] != `SHBIT_SWP) begin
            pc_op = inst[15:12] == 4'b1111;    // Rd is PC. If Rn is PC, writeback cannot be specified
            set_cpsr = 1'b0;

            // Memory
            mem_op = 1'b1;
            we_data = ~inst[20];        // inst[20] is 1 if LDR, 0 if STR. So: negate
            address_gen_mode = {inst[21], inst[24]};
            // [6:5] = 01 if unsigned halfword, 10 if signed byte, 11 if signed halfword
            load_addressing_mode = (inst[6] ? `SEXT : `ZEXT) | (inst[5] ? `HALF_WORD : `BYTE);

            // ALU operation
            // inst[23] indicates whether to do Rn + Offset or Rd - Offset
            alu_op = inst[23] ? `ALU_ADD : `ALU_SUB;
            imm_flag = 1'b0;
            imm_val = 32'b0;
            op2_shift_func = 2'b00;      // LSL (00)
            op2_imm_shift_by = 8'b0;
            op2_is_imm_shift = 1'b1;

            // Registers
            // Write Port A is used for writeback, Port B is used for writing for LDR (has value from memory)
            wr_en_a = ~(address_gen_mode == `OFFSET);   // All modes other than offset write
            wr_en_b = inst[20];         // 1 if LDR, 0 if STR
            wr_addr_a = inst[19:16];    // Rn, for writeback
            wr_addr_b = inst[15:12];    // Rd, for LDR operations
            rd_addr_a = inst[19:16];    // Rn
            rd_addr_b = inst[3:0];      // Rm
            rd_addr_c = 4'b0000;        // No shift
            rd_addr_d = inst[15:12];    // Rd - Read port D is connected to the input of memory
        // Halfword data transfer, immediate offset. Explicitly excluding swap operations from this
        end else if (inst[27:25] == `HW_TFR && inst[22] == 1'b1 && inst[7] == 1'b1 && inst[4] == 1'b1 && inst[6:5] != `SHBIT_SWP) begin
            pc_op = inst[15:12] == 4'b1111;    // Rd is PC. If Rn is PC, writeback cannot be specified
            set_cpsr = 1'b0;

            // Memory
            mem_op = 1'b1;
            we_data = ~inst[20];        // inst[20] is 1 if LDR, 0 if STR. So: negate
            address_gen_mode = {inst[21], inst[24]};
            // [6:5] = 01 if unsigned halfword, 10 if signed byte, 11 if signed halfword
            load_addressing_mode = (inst[6] ? `SEXT : `ZEXT) | (inst[5] ? `HALF_WORD : `BYTE);

            // ALU operation
            // inst[23] indicates whether to do Rn + Offset or Rd - Offset
            alu_op = inst[23] ? `ALU_ADD : `ALU_SUB;
            imm_flag = 1'b1;
            imm_val = {{24{1'b0}}, inst[11:8], inst[3:0]};
            op2_shift_func = 2'b00;      // LSL (00)
            op2_imm_shift_by = 8'b0;
            op2_is_imm_shift = 1'b1;

            // Registers
            // Write Port A is used for writeback, Port B is used for writing for LDR (has value from memory)
            wr_en_a = ~(address_gen_mode == `OFFSET);   // All modes other than offset write
            wr_en_b = inst[20];         // 1 if LDR, 0 if STR
            wr_addr_a = inst[19:16];    // Rn, for writeback
            wr_addr_b = inst[15:12];    // Rd, for LDR operations
            rd_addr_a = inst[19:16];    // Rn
            rd_addr_b = 4'b0000;        // No register addition
            rd_addr_c = 4'b0000;        // No shift
            rd_addr_d = inst[15:12];    // Rd - Read port D is connected to the input of memory
        end else begin // Undefined instuction, do nothing
            // This also includes instuctions I have not implemented, like:
            //      - MRS, MSR (PSR transfer)
            //      - Bulk data transfers (and anything defined in plan.md)

            pc_op = 1'b0;
            set_cpsr = 1'b0;

            // ALU operation
            alu_op = 1'b0;
            imm_flag = 1'b0;
            imm_val = 32'b0;
            op2_shift_func = 2'b0;
            op2_imm_shift_by = 8'b0;
            op2_is_imm_shift = 1'b1;

            // Registers
            wr_en_a = 1'b0;
            wr_en_b = 1'b0;
            wr_addr_a = 4'b0;
            wr_addr_b = 4'b0;
            rd_addr_a = 4'b0;
            rd_addr_b = 4'b0;
            rd_addr_c = 4'b0;

            // Memory
            mem_op = 1'b0;
            we_data = 1'b0;
            address_gen_mode = 2'b00;       // Irrelevant
            load_addressing_mode = 3'b000;  // Irrelevant
        end
    end
endmodule