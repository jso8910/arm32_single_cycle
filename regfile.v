`include "params.vh"

module regfile
#(parameter RWIDTH = `WWIDTH)
(
    input [3:0]         wr_addr_a,  // changed
    input [3:0]         wr_addr_b,  // new
    input [3:0] 	    rd_addr_a,
    input [3:0] 	    rd_addr_b,
    input 		        wr_en_a,    // changed
    input 		        wr_en_b,    // new
    input 		        clk,
    input 		        rst,
    input [RWIDTH-1:0]  next_pc,    // new
    input [RWIDTH-1:0]  data_in_a,  // changed
    input [RWIDTH-1:0]  data_in_b,  // new
    output [RWIDTH-1:0] reg_a, reg_b
);
    // Register file with two read ports, and two write port (this is a change)
    // Asynchronous read, synchronous write
    reg [RWIDTH-1:0] regarray [0:14];     // 15 GPRs + R15 as the PC
    integer i;

    // Write logic
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (i = 0; i < 15; i++) begin
                regarray[i] <= {RWIDTH{1'b0}};
            end
        end else begin
        // R15 isn't stored in this register file, it is written to by
        // sending a value to nextPcLogic and setting pc_write
        if (wr_en_b && wr_addr_b != 15)
            regarray[wr_addr_b] <= data_in_b;

        // Port A is second to give priority
        if (wr_en_a && wr_addr_a != 15)
            regarray[wr_addr_a] <= data_in_a;
        end
    end

    // Read logic
    assign reg_a = (rd_addr_a == 4'b1111) ? next_pc : regarray[rd_addr_a];
    assign reg_b = (rd_addr_b == 4'b1111) ? next_pc : regarray[rd_addr_b];
endmodule