`include "params.vh"

module regfile
#(parameter RWIDTH = `WWIDTH)
(
    input [3:0]         wr_addr_a,  // changed
    input [3:0]         wr_addr_b,  // new
    input [3:0] 	    rd_addr_a,
    input [3:0] 	    rd_addr_b,
    input [3:0] 	    rd_addr_c,  // new
    input [3:0] 	    rd_addr_d,  // new
    input 		        wr_en_a,    // changed
    input 		        wr_en_b,    // new
    input 		        clk,
    input 		        rst,
    input [3:0]         pc_offset,  // new
    input               bulk_store_enable,
    input               bulk_load_enable,
    input               bulk_writeback,
    input [15:0]        bulk_reglist,
    input [`AWIDTH-1:0] bulkAddrResult,
    input [RWIDTH*16-1:0] bulk_data_sram,
    input [RWIDTH-1:0]  next_pc,    // new
    input [RWIDTH-1:0]  data_in_a,  // changed
    input [RWIDTH-1:0]  data_in_b,  // new
    output [RWIDTH-1:0] reg_a, reg_b, reg_c, reg_d,
    output [RWIDTH*16-1:0] bulk_data_reg
);
    // Register file with two read ports, and two write port (this is a change)
    // Asynchronous read, synchronous write
    reg [RWIDTH-1:0] regarray [0:14];     // 15 GPRs + R15 as the PC
    integer i;
    integer data_idx;

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

            // Bulk load logic....
            if (bulk_load_enable) begin
                // Iterate up to (not including) 15 - PC is accounted for elsewhere
                for (i = 0; i < 15; i++) begin
                    // If the register is set in bulk_reglist, write the bulk_data_sram value
                    if (bulk_reglist[i]) begin
                        regarray[i] <= bulk_data_sram[i*32 +: 32];
                    end
                end
                // If writeback, write to wr_addr_a *unless it is in reglist*
                if (bulk_writeback && ~bulk_reglist[wr_addr_a]) begin
                    regarray[wr_addr_a] <= bulkAddrResult;
                end
            end
            // We also need to do writeback on a bulk store
            if (bulk_store_enable && bulk_writeback)
                regarray[wr_addr_a] <= bulkAddrResult;
        end
    end

    // Read logic
    assign reg_a = (rd_addr_a == 4'b1111) ? (next_pc + pc_offset) : regarray[rd_addr_a];
    assign reg_b = (rd_addr_b == 4'b1111) ? (next_pc + pc_offset) : regarray[rd_addr_b];
    assign reg_c = (rd_addr_c == 4'b1111) ? (next_pc + pc_offset) : regarray[rd_addr_c];
    assign reg_d = (rd_addr_d == 4'b1111) ? (next_pc + pc_offset) : regarray[rd_addr_d];

    // Bulk read
    assign bulk_data_reg = {
        next_pc + pc_offset, regarray[14], regarray[13], regarray[12],
        regarray[11], regarray[10], regarray[9], regarray[8],
        regarray[7], regarray[6], regarray[5], regarray[4],
        regarray[3], regarray[2], regarray[1], regarray[0]
    };
endmodule