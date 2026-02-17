`include "params.vh"

module sram
#(parameter SIZE = 2**`AWIDTH)
(
    output reg [`DWIDTH-1:0]     dataOut,
    input [2:0]                 func,   // TODO: Figure out what func is and if it has an ARM equivalent. Seems like it might be byte vs hw vs word
    input [`DWIDTH-1:0]          dataIn,
    input                       cs, we, clk,
    input [`AWIDTH-1:0]          addr
);
    // Definition of lower-endian SRAM module
    // Asynchronous read, synchronous write
    // NOTE: I don't see any particular reason to have a separate CS and WE (considering the RISC decoder assigns them to the same value) so I will disregard CS

    reg [7:0] MEM [0:SIZE-1];

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
                dataOut = {{ (`DWIDTH-8*4) {1'b0} }, MEM[addr + 3], MEM[addr + 2], MEM[addr + 1], MEM[addr]};
            end
            2'b11: begin        // Double-word
                dataOut = {
                    MEM[addr + 7], MEM[addr + 6], MEM[addr + 5], MEM[addr + 4],
                    MEM[addr + 3], MEM[addr + 2], MEM[addr + 1], MEM[addr]
                };
            end
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
                2'b11: begin                    // Double-word
                    MEM[addr] <= dataIn[7:0];
                    MEM[addr + 1] <= dataIn[15:8];
                    MEM[addr + 2] <= dataIn[23:16];
                    MEM[addr + 3] <= dataIn[31:24];
                    MEM[addr + 4] <= dataIn[39:32];
                    MEM[addr + 5] <= dataIn[47:40];
                    MEM[addr + 6] <= dataIn[55:48];
                    MEM[addr + 7] <= dataIn[63:56];
                end
            endcase
        end
    end
endmodule