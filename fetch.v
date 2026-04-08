`include "params.vh"

module fetchLogic(
    input 	                    clk,
    input 	                    rst,
    input [`WWIDTH-1:0] 	    next_pc,
    output reg [`WWIDTH-1:0]    this_pc
);
    // Fetch logic module, which acts as R15 (PC)
    // next_pc is the value which is read as the value of the PC (stores the next value of the program counter)
    // this_pc is the value which is currently stored and fed to the instruction memory
    // next_pc should be driven OUTSIDE this module. Generally, it will be equal to this_pc + 4
    always @(posedge clk or negedge rst) begin
	// If write enable, we are basically resetting
        if (!rst)
            this_pc <= {`WWIDTH{1'b0}};
        else
            this_pc <= next_pc;
    end
endmodule
