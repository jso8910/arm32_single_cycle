`include "params.vh"
// TODO: I assume much of the interface of this decoder will have to be changed, since the instruction decoding is different
// I'll use my best judgement for what eg flags to use
// TODO: why is pc_plus4 generated in the decoder?
module decode(
    input [`IWIDTH-1:0]         inst,
    input [`WWIDTH-1:0] 	    next_pc,
    output wire                 imm_flag,
                                we_data,
                                cs_data,
                                wr_en_a,
                                wr_en_b,
    output wire [3:0]           wr_addr_a, wr_addr_b,
    output wire [3:0]           rd_addr_a, rd_addr_b, rd_addr_c,
    output wire [1:0]           op2_shift_func

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
    // ARMv7-A decoder
    // User/privileged modes not implemented - all memory is accessible by anything
    // Thumb mode not implemented
    // always @(*)
endmodule