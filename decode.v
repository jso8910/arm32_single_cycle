`include "params.vh"
// TODO: I assume much of the interface of this decoder will have to be changed, since the instruction decoding is different
// I'll use my best judgement for what eg flags to use
// TODO: why is pc_plus4 generated in the decoder?
// TODO branch calculation unit should output the next_pc value if the branch isnt taken
        // or just AND the pc_op signal with the condition, probably easier. the pc_op signal (as well as write signals) can be an input to the conditional unit
// TODO: how should I deal with conditional data operations? this matters for the wr_en signals as well. AND the write signal with the condition?


// TODO: need mux logic for if the address == 15 to take the next_pc value


// Address generation modes, P and W bits
`define PRE_INDEX   2'b11   // Use Rn, then update with Op3
`define POST_INDEX  2'b00
`define OFFSET      2'b10

// Load addressing modes. Eg HALF_WORD | SEXT
`define SEXT        3'b100
`define ZEXT        3'b000
`define BYTE        3'b000
`define HALF_WORD   3'b001
`define WORD        3'b010

// Instruction encodings
`define BX_INST     24'h12FFF1
`define B_INST      3'b101
`define DATA_PROC_I 3'b001

// ALU operations
`define ALU_AND     4'b0000     // Op1 AND Op2
`define ALU_EOR     4'b0001     // Op1 XOR Op2
`define ALU_SUB     4'b0010     // Op1 - Op2
`define ALU_RSB     4'b0011     // Op2 - Op1
`define ALU_ADD     4'b0100     // Op1 + Op2
`define ALU_ADC     4'b0101     // Op1 + Op2 + C (CPSR)
`define ALU_SBC     4'b0110     // Op1 - Op2 + C - 1 (CPSR)
`define ALU_RSC     4'b0111     // Op2 - Op1 + C - 1 (CPSR) 
`define ALU_TST     4'b1000     // Op1 AND Op2: cond codes
`define ALU_TEQ     4'b1001     // Op1 EOR Op2: cond codes
`define ALU_CMP     4'b1010     // Op1 - Op2:   cond codes
`define ALU_CMN     4'b1011     // Op1 + Op2:   cond codes
`define ALU_ORR     4'b1100     // Op1 OR Op2
`define ALU_MOV     4'b1101     // Op2
`define ALU_BIC     4'b1110     // Op1 AND (NOT Op2)
`define ALU_MVN     4'b1111     // NOT Op2

// Shift functions
`define LSL 2'b00
`define LSR 2'b01
`define ASR 2'b10
`define ROR 2'b11

module decode(
    input [`IWIDTH-1:0]         inst,
    input [`WWIDTH-1:0] 	    next_pc,

    output reg                  imm_flag,       // When imm_flag is set, rd_addr_b is ignored in place of imm_val ROR imm_rot_amt
                                we_data,
                                cs_data,
                                wr_en_a,
                                wr_en_b,
                                pc_op,          // Flag for whether r15 could be modified (potential branch or any operation with r15)
                                branch_link,    // Used to decide between ALU out and next_pc for write port a input
                                set_cpsr,
    output reg [3:0]            condition_code,
    output reg [3:0]            alu_op,

    // Operand addresses/generation information. wr is write signals for destinations, rd (read) is for sources
    output reg [3:0]            wr_addr_a, wr_addr_b,
    output reg [3:0]            rd_addr_a, rd_addr_b, rd_addr_c,
    output reg [1:0]            op2_shift_func,
    output reg [3:0]            imm_rot_amt,
    output reg [23:0]           imm_val,
    output reg                  imm_ext_mode,   // 1 if sign extended, 0 if zero extended
    output reg [1:0]            address_gen_mode,
    output reg [3:0]            load_addressing_mode,
    output reg                  mem_op             // Is this a memory operation?

    // output wire                 mux_alu_dmem,
    //                             mux_alu_ext, 
    //                             cs_data,
    //                             we_data,
    //                             wr_en,
    //                             br_flag,
    //                             jump, 
    //                             r_type,
    //                             jalr_flag,
    //                             jal_flag,
    //                             u_type,
    //                             imm_flag,
    //                             ld_str_flag,
    //                             ExtOp, 
    //                             auipc_flag,
    //                             add_or_sub, 
    //                             shift_type,
    // output wire [`IWIDTH-1:0]    pc_plus4,

    // output wire [2:0] 	        func,
    // output wire [4:0] 	        alu_shift_amt,
    // output wire [11:0] 	        imm_ld_ext_in,
    // output wire [11:0] 	        imm_str_ext_in,
    // output wire [12:0] 	        br_imm,

    // output wire [`WWIDTH-1:0]    jalr_target, jal_target, auipc_target, lui_target,
    // output wire [`AWIDTH-1:0]    reg_rd_addr_a, reg_rd_addr_b, reg_wr_addr
);
    // ARMv4 decoder
    // User/privileged modes not implemented - all memory is accessible by anything
    // Thumb mode not implemented


    assign condition_code = inst[31:28];
    assign cs_data = 1'b0;  // CS is currently unused

    always @(*) begin
        // This is probably going to end up being quite bad, but I'm curious to what extent a synthesis software would optimize it
        // Like I assume that there are better ways to do comparisons (eg identifying what parts of the instruction are unique or something)
        // but would a synthesizer identify that?

        // bx
        if (inst[27:4] == `BX_INST) begin
            pc_op = 1'b1;
            branch_link = 1'b0;     // Don't link
            set_cpsr = 1'b0;

            // ALU operation
            // We are going to want to add Rn to 0
            // So set rd_a = Rn, imm_val = 0
            alu_op = `ALU_ADD;
            imm_flag = 1'b1;
            imm_val = 24'b0;
            imm_rot_amt = 4'b0;
            imm_ext_mode = 1'b0;
            op2_shift_func = 2'b0;

            // Registers
            // No destination register here
            wr_en_a = 1'b0;
            wr_en_b = 1'b0
            wr_addr_a = 4'b0;
            wr_addr_b = 4'b0;
            rd_addr_a = inst[3:0];
            rd_addr_b = 4'b0;
            rd_addr_c = 4'b0;

            // Memory
            mem_op = 1'b0
            we_data = 1'b0;
            address_gen_mode = 2'b00;       // Irrelevant
            load_addressing_mode = 3'b000;  // Irrelevant
        end else if (inst[27:25] == `B_INST) begin
            pc_op = 1'b1;
            branch_link = inst[24];
            set_cpsr = 1'b0;

            // ALU operation
            // We are going to want to add the immediate offset (24 bits) to R15
            // So set rd_a = Rn, imm_val = 0
            alu_op = `ALU_ADD;
            imm_flag = 1'b1;
            imm_val = instr[23:0];
            imm_rot_amt = 4'b0;
            imm_ext_mode = 1'b1;   // Sign extended
            op2_shift_func = 2'b0;

            // Registers
            // No destination register here
            wr_en_a = inst[24];     // Link bit
            wr_en_b = 1'b0
            wr_addr_a = inst[24] ? 4'b1110 : 4'b0;    // Link register
            wr_addr_b = 4'b0;
            rd_addr_a = 4'b1111;
            rd_addr_b = 4'b0;
            rd_addr_c = 4'b0;

            // Memory
            mem_op = 1'b0
            we_data = 1'b0;
            address_gen_mode = 2'b00;       // Irrelevant
            load_addressing_mode = 3'b000;  // Irrelevant
        end else if (inst[27:25] == `DATA_PROC_I) begin     // Immediate data processing instruction
            pc_op = 1'b0;
            branch_link = 1'b0;
            set_cpsr = addr[20];

            // ALU operation
            // We are going to want to add the immediate offset (24 bits) to R15
            // So set rd_a = Rn, imm_val = 0
            alu_op = addr[24:21];
            imm_flag = 1'b1;    // (inst[25])
            imm_val = {{16{1'b0}}, instr[7:0]};     // 8 bit immediate, zero extended to 24 bits for convenience
            imm_rot_amt = instr[11:8];
            imm_ext_mode = 1'b0;    // Zero extended
            op2_shift_func = 2'b0;  // N/A for immediate

            // Registers
            wr_en_a  1'b1;
            wr_en_b = 1'b0
            wr_addr_a = instr[15:12];   // Rd
            wr_addr_b = 4'b0;
            rd_addr_a = instr[19:16];   // Rn
            rd_addr_b = 4'b0;
            rd_addr_c = 4'b0;

            // Memory
            mem_op = 1'b0
            we_data = 1'b0;
            address_gen_mode = 2'b00;       // Irrelevant
            load_addressing_mode = 3'b000;  // Irrelevant
        // Shifted register data processing instruction
        // The thing which differentiates this from other operations is that either bit 7 or 4 will be 0
        // Whereas in eg mul, instr[7:4] = 1001
        // The only other instruction with 27:25 == 000 and bit 7 == 0 is bx, already accounted for
        end else if (inst[27:25] == 3'b000 && (inst[7] == 0 || inst[4] ==  0)) begin
            // TODO: account for immediate shift
            // TODO figure out how best to set rd_addr_c to be the shift register. I don't think I do, but do I need any signal outputted to indicate that third value (or the immediate) is a shift?
                // Can that simply be implied by the fact that imm_flag == 0? Is that sufficient to show that there is a shift?
                // Do I need a flag for immediate vs register shift?
            pc_op = 1'b0;
            branch_link = 1'b0;
            set_cpsr = addr[20];

            // ALU operation
            // We are going to want to add the immediate offset (24 bits) to R15
            // So set rd_a = Rn, imm_val = 0
            alu_op = addr[24:21];
            imm_flag = 1'b0;    // (inst[25])
            imm_val = 24'b0;
            imm_rot_amt = 4'b0;
            imm_ext_mode = 1'b0;    // Zero extended
            op2_shift_func = instr[6:5];

            // Registers
            wr_en_a  1'b1;
            wr_en_b = 1'b0
            wr_addr_a = instr[15:12];   // Rd
            wr_addr_b = 4'b0;
            rd_addr_a = instr[19:16];   // Rn
            rd_addr_b = instr[3:0];     // Rm
            rd_addr_c = 4'b0;

            // Memory
            mem_op = 1'b0
            we_data = 1'b0;
            address_gen_mode = 2'b00;       // Irrelevant
            load_addressing_mode = 3'b000;  // Irrelevant
        end
    end
endmodule