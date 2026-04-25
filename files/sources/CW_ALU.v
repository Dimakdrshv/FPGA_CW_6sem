`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kudryashov D.S.
// 
// Create Date: 16.04.2026 22:07:00
// Design Name: 
// Module Name: CW_ALU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Processor ALU
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CW_ALU (
    input wire [3:0] ALU_INST,
    input wire [7:0] OPR0,
    input wire [7:0] OPR1,
    input wire [2:0] BT_NUM,
    input wire [1:0] SREG,
    output reg [7:0] ALU_RES,
    output reg       JMP,
    output reg [1:0] ALU_SREG
    );
    
    //------------------> ALU_RES and JMP              
    always @* begin
        case (ALU_INST)
            4'b0000: ALU_RES = OPR0;
            4'b0001: ALU_RES = OPR0 + OPR1;
            4'b0010: ALU_RES = OPR0 - OPR1;
            4'b0011: ALU_RES = OPR0 & OPR1;
            4'b0100: ALU_RES = OPR0 | OPR1;
            4'b0101: ALU_RES = OPR0 << BT_NUM;
            4'b0110: ALU_RES = OPR0 >> BT_NUM;
            default: ALU_RES = 8'h0;
        endcase
        
        case (ALU_INST)
            4'b0111: JMP = ~|(SREG[1:0] & (1 << BT_NUM));
            4'b1000: JMP = |(SREG[1:0] & (1 << BT_NUM));
            default: JMP = 1'b0;
        endcase
    end
    
    //----------------> ALU_SREG CARRY
    wire C_ADD = (OPR0[7] & OPR1[7]) | (~ALU_RES[7] & OPR1[7]) | (~ALU_RES[7] & OPR0[7]); //(0) inf_input MX_C1
    wire C_SUB = (~OPR0[7] & OPR1[7]) | (ALU_RES[7] & OPR1[7]) | (ALU_RES[7] & ~OPR0[7]); //(1) inf_input MX_C1  
    always @* begin
        case (ALU_INST)
            4'b0001: ALU_SREG[0] = C_ADD;
            4'b0010: ALU_SREG[0] = C_SUB;
            default: ALU_SREG[0] = SREG[0];
        endcase
    end
    
    //----------------> ALU_SREG ZERO
    always @* begin
        case (ALU_INST)
            4'b0000,
            4'b0001,
            4'b0010,
            4'b0011,
            4'b0100,
            4'b0101,
            4'b0110: ALU_SREG[1] = ~(|ALU_RES);
            default: ALU_SREG[1] = SREG[1];
        endcase
    end
    
endmodule
