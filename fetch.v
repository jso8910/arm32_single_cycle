`include "params.vh"

module fetchLogic(
    input 	                    clk,
    input 	                    rst,
    input [`WWIDTH-1:0] 	    next_pc,
    output reg [`WWIDTH-1:0]    this_pc,
    output [`IWIDTH-1:0]        inst
);
    // Fetch logic module, which acts as R15 (PC)
    // next_pc is the value which is read as the value of the PC (stores the next value of the program counter)
    // this_pc is the value which is currently stored and fed to the instruction memory
    // next_pc should be driven OUTSIDE this module. Generally, it will be equal to this_pc + 4

    wire [`DWIDTH-1:0] inst_mem_out;
    assign inst = inst_mem_out[`IWIDTH-1:0];
    always @(posedge clk or negedge rst) begin
        if (!rst)
            this_pc <= {`WWIDTH{1'b0}};
        else
            this_pc <= next_pc;
    end
    sram inst_mem (
        .dataOut(inst_mem_out),
        .func(3'b010),   // Read a single word
        .dataIn({`DWIDTH{1'b0}}),
        .cs(1'b0),
        .we(1'b0),
        .clk(clk),
        .addr(this_pc[`AWIDTH-1:0]),
        .bulk_store_enable(1'b0),
        .bulk_load_enable(1'b0),
        .bulk_reglist(16'b0),
        .bulk_data_reg(512'b0)
    );
endmodule