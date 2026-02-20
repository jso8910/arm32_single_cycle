`include "params.vh"

// TODO need to make sure that, for LDM, if the base is in the register list, the value from memory is the one written
    // perhaps just use a mux 
    // Make sure op2_is_imm_shift is FALSE or pc_offset is otherwise equal to 8, since r15 being stored yields address + 12

    // bulk_store_enable, bulk_load_enable, bulk_reglist, wr_addr_a = ..., wr_en_a = false

module sram
#(parameter SIZE = 2**`AWIDTH)
(
    output reg [`DWIDTH-1:0]    dataOut,
    output reg [`DWIDTH*16-1:0] bulk_data_sram,
    output reg [`AWIDTH-1:0]    bulkAddrResult,     // What the new address is after a bulk operation
    input [2:0]                 func,
    input                       bulk_store_enable,
    input                       bulk_load_enable,
    input [15:0]                bulk_reglist,          // Number of elements handled by bulk operation
    input [`DWIDTH*16-1:0]      bulk_data_reg,
    input [`DWIDTH-1:0]         dataIn,
    input                       cs, we, clk,
    input [`AWIDTH-1:0]         addr
);
    // Definition of lower-endian SRAM module
    // Asynchronous read, synchronous write
    // NOTE: I don't see any particular reason to have a separate CS and WE (considering the RISC decoder assigns them to the same value) so I will disregard CS
    // This SRAM module supports both bulk read and write operations, for up to 16 registers at once
    integer i, num_registers;

    wire [4:0] total_regs_bulk = bulk_reglist[0] + bulk_reglist[1] + bulk_reglist[2] + bulk_reglist[3] + // Total number of registers being loaded/stored in bulk
                                   bulk_reglist[4] + bulk_reglist[5] + bulk_reglist[6] + bulk_reglist[7] +
                                   bulk_reglist[8] + bulk_reglist[9] + bulk_reglist[10] + bulk_reglist[11] +
                                   bulk_reglist[12] + bulk_reglist[13] + bulk_reglist[14] + bulk_reglist[15];

    reg [7:0] MEM [0:SIZE-1];
    reg [31:0] raw_word;
    reg [`AWIDTH-1:0] aligned_addr;

    // Read logic
    always @(*) begin
        case (func[1:0])
            2'b00: begin        // Single byte
                if (func[2])    // sign ext
                    dataOut = {{ (`DWIDTH-8) {MEM[addr][7]} }, MEM[addr]};
                else            // Zero extend
                    dataOut = {{ (`DWIDTH-8) {1'b0}}, MEM[addr]};
            end
            2'b01: begin        // Half-word
                if (func[2])    // sign extend
                    dataOut = {{ (`DWIDTH-8*2) {MEM[addr + 1][7]} }, MEM[addr + 1], MEM[addr]};
                else            // Zero extend
                    dataOut = {{ (`DWIDTH-8*2) {1'b0} }, MEM[addr + 1], MEM[addr]};
            end
            2'b10: begin        // Word - can't be sign extended
                // If the word is not on a word boundary (addr[1:0] == 00), we must handle that
                // ARM32 handles this by rotating bytes right such that the address is in the least significant 4 bits
                raw_word = {MEM[addr + 3], MEM[addr + 2], MEM[addr + 1], MEM[addr]};
                aligned_addr = {addr[`AWIDTH-1:2], 2'b00};
                case (addr[1:0])
                    2'b00: dataOut = raw_word;
                    2'b01: dataOut = {raw_word[7:0], raw_word[31:8]};   // ROR 8
                    2'b10: dataOut = {raw_word[15:0], raw_word[31:16]}; // ROR 16
                    2'b11: dataOut = {raw_word[23:0], raw_word[31:24]}; // ROR 24
                endcase
            end
            default: dataOut = {`DWIDTH {1'b1}};    // Undefined behavior
        endcase

        // Bulk reads
        // In this case, `func` changes meaning

        // Avoid unintentional latches
        bulk_data_sram = 512'b0;
        num_registers = 0;

        if (bulk_load_enable) begin
            // Bit 1 of func is post (0)/pre (1)
            // Bit 0 is down (0)/up (1)
            case (func[1:0])
                2'b00: begin    // Post-decrement
                    // In this case, the largest index register is in addr
                    // The lowest index register ends up in addr - 4*(total_regs_bulk - 1)
                    // bulkAddrResult is addr - 4*total_regs_bulk
                    for (i = 15; i >= 0; i--) begin
                        if (bulk_reglist[i]) begin
                            bulk_data_sram[i*32 +: 32] = {MEM[addr - 4*num_registers + 3],
                                                MEM[addr - 4*num_registers + 2],
                                                MEM[addr - 4*num_registers + 1],
                                                MEM[addr - 4*num_registers]};
                            num_registers++;
                        end
                    end
                end
                2'b01: begin    // Post-increment
                    // In this case, the largest index register ends up in addr + 4*(total_regs_bulk - 1)
                    // The lowest index register ends up in addr
                    // bulkAddrResult is addr + 4*total_regs_bulk
                    for (i = 0; i < 16; i++) begin
                        if (bulk_reglist[i]) begin
                            bulk_data_sram[i*32 +: 32] = {MEM[addr + 4*num_registers + 3],
                                                MEM[addr + 4*num_registers + 2],
                                                MEM[addr + 4*num_registers + 1],
                                                MEM[addr + 4*num_registers]};
                            num_registers++;
                        end
                    end
                end
                2'b10: begin    // Pre-decrement
                    // In this case, the largest index register ends up in addr - 4*total_regs_bulk
                    // The lowest index register ends up in addr - 4
                    // bulkAddrResult is addr - 4*total_regs_bulk
                    for (i = 15; i >= 0; i--) begin
                        if (bulk_reglist[i]) begin
                            bulk_data_sram[i*32 +: 32] = {MEM[addr - 4*(num_registers + 1) + 3],
                                                MEM[addr - 4*(num_registers + 1) + 2],
                                                MEM[addr - 4*(num_registers + 1) + 1],
                                                MEM[addr - 4*(num_registers + 1)]};
                            num_registers++;
                        end
                    end
                end
                2'b11: begin    // Pre-increment
                    // In this case, the largest index register ends up in addr + 4*total_regs_bulk
                    // The lowest index register ends up in addr + 4
                    // bulkAddrResult is addr + 4*total_regs_bulk
                    for (i = 0; i < 16; i++) begin
                        if (bulk_reglist[i]) begin
                            bulk_data_sram[i*32 +: 32] = {MEM[addr + 4*(num_registers + 1) + 3],
                                                MEM[addr + 4*(num_registers + 1) + 2],
                                                MEM[addr + 4*(num_registers + 1) + 1],
                                                MEM[addr + 4*(num_registers + 1)]};
                            num_registers++;
                        end
                    end
                end
            endcase
        end
        // Set the bulk address. Needs to be set independent of whether a read is occurring
        // so it can be accessed for writeback on write
        // This is the address which is written to the register file when writeback is selected
        case (func[0])
            1'b0: bulkAddrResult = addr - 4*total_regs_bulk;
            1'b1: bulkAddrResult = addr + 4*total_regs_bulk;
        endcase
    end

    // Write logic
    always @(posedge clk) begin
        if (we) begin
            case (func[1:0])
                2'b00: begin                    // Byte
                    MEM[addr] <= dataIn[7:0];
                end
                2'b01: begin                    // Half-word
                    MEM[addr] <= dataIn[7:0];
                    MEM[addr + 1] <= dataIn[15:8];
                end
                2'b10: begin                    // Word
                    MEM[addr] <= dataIn[7:0];
                    MEM[addr + 1] <= dataIn[15:8];
                    MEM[addr + 2] <= dataIn[23:16];
                    MEM[addr + 3] <= dataIn[31:24];
                end
                default: dataOut <= {`DWIDTH {1'b1}};    // Undefined behavior
            endcase
        end


        // Bulk writes
        // In this case, `func` changes meaning
        num_registers = 0;
        if (bulk_store_enable) begin
            // Bit 1 of func is post (0)/pre (1)
            // Bit 0 is down (0)/up (1)
            case (func[1:0])
                2'b00: begin    // Post-decrement
                    // In this case, the largest index register is in addr
                    // The lowest index register ends up in addr - 4*(total_regs_bulk - 1)
                    // bulkAddrResult is addr - 4*total_regs_bulk
                    for (i = 15; i >= 0; i--) begin
                        if (bulk_reglist[i]) begin
                            {MEM[addr - 4*num_registers + 3],
                                                MEM[addr - 4*num_registers + 2],
                                                MEM[addr - 4*num_registers + 1],
                                                MEM[addr - 4*num_registers]} <= bulk_data_reg[i*32 +: 32];
                            num_registers++;
                        end
                    end
                end
                2'b01: begin    // Post-increment
                    // In this case, the largest index register ends up in addr + 4*(total_regs_bulk - 1)
                    // The lowest index register ends up in addr
                    // bulkAddrResult is addr + 4*total_regs_bulk
                    for (i = 0; i < 16; i++) begin
                        if (bulk_reglist[i]) begin
                            {MEM[addr + 4*num_registers + 3],
                                                MEM[addr + 4*num_registers + 2],
                                                MEM[addr + 4*num_registers + 1],
                                                MEM[addr + 4*num_registers]} <= bulk_data_reg[i*32 +: 32];
                            num_registers++;
                        end
                    end
                end
                2'b10: begin    // Pre-decrement
                    // In this case, the largest index register ends up in addr - 4*total_regs_bulk
                    // The lowest index register ends up in addr - 4
                    // bulkAddrResult is addr - 4*total_regs_bulk
                    for (i = 15; i >= 0; i--) begin
                        if (bulk_reglist[i]) begin
                            {MEM[addr - 4*(num_registers + 1) + 3],
                                                MEM[addr - 4*(num_registers + 1) + 2],
                                                MEM[addr - 4*(num_registers + 1) + 1],
                                                MEM[addr - 4*(num_registers + 1)]} <= bulk_data_reg[i*32 +: 32];
                            num_registers++;
                        end
                    end
                end
                2'b11: begin    // Pre-increment
                    // In this case, the largest index register ends up in addr + 4*total_regs_bulk
                    // The lowest index register ends up in addr + 4
                    // bulkAddrResult is addr + 4*total_regs_bulk
                    for (i = 0; i < 16; i++) begin
                        if (bulk_reglist[i]) begin
                            {MEM[addr + 4*(num_registers + 1) + 3],
                                                MEM[addr + 4*(num_registers + 1) + 2],
                                                MEM[addr + 4*(num_registers + 1) + 1],
                                                MEM[addr + 4*(num_registers + 1)]} <= bulk_data_reg[i*32 +: 32];
                            num_registers++;
                        end
                    end
                end
            endcase
        end
    end
endmodule