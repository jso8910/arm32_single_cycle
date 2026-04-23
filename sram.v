`include "params.vh"

// TODO need to make sure that, for LDM, if the base is in the register list, the value from memory is the one written
    // perhaps just use a mux 
    // Make sure op2_is_imm_shift is FALSE or pc_offset is otherwise equal to 8, since r15 being stored yields address + 12

    // bulk_store_enable, bulk_load_enable, bulk_reglist, wr_addr_a = ..., wr_en_a = false

module sram
#(parameter SIZE = 2**`AWIDTH)
(
    output reg [`DWIDTH-1:0]    dataOut,
    input [2:0]                 func,
    input [`DWIDTH-1:0]         dataIn,
    input                       cs, we, clk,
    input [`AWIDTH-1:0]         addr
);
    // Definition of lower-endian SRAM module
    // Asynchronous read, synchronous write
    // NOTE: I don't see any particular reason to have a separate CS and WE (considering the RISC decoder assigns them to the same value) so I will disregard CS
    // This SRAM module supports both bulk read and write operations, for up to 16 registers at once
    integer i, num_registers;

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
                default: ;			// Undefined behavior
            endcase
        end
    end
endmodule
