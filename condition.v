`include "params.vh"

module condition_unit(
    input [3:0] nzcv,
    input [3:0] condition_code,
    output reg  cond_met
);
    wire n, z, c, v;
    assign {n, z, c, v} = nzcv;
    always @(*) begin
        case (condition_code)
            4'b0000: cond_met = z;
            4'b0001: cond_met = ~z;
            4'b0010: cond_met = c;
            4'b0011: cond_met = ~c;
            4'b0100: cond_met = n;
            4'b0101: cond_met = ~n;
            4'b0110: cond_met = v;
            4'b0111: cond_met = ~v;
            4'b1000: cond_met = c & (~z);
            4'b1001: cond_met = (~c) | z;
            4'b1010: cond_met = n == v;
            4'b1011: cond_met = n != v;
            4'b1100: cond_met = (~z) & (n == v);
            4'b1101: cond_met = z | (n != v);
            default: cond_met = 1'b1;
        endcase
    end
endmodule