`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kudryashov D.S.
// 
// Create Date: 17.04.2026 13:28:03
// Design Name: 
// Module Name: CW_SREG
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: Status register
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CW_SREG (
    input wire        CLK,
    input wire        RST,
    input wire        S_EX_REQ,
    input wire  [2:0] S_CMD,
    input wire  [7:0] S_D_WR,
    input wire        SREG_WE,
    input wire        EIRQ_SET,
    input wire        EIRQ_RESET,
    input wire  [1:0] SREG_D,
    output wire       S_EX_ACK,
    output wire [7:0] S_D_RD,
    output reg  [2:0] SREG
    );
    
    //----------------> initial
    initial begin
        SREG = 3'b100;
    end
    
    //---------------> sequential logic
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            SREG <= 3'b100;
        end else begin
            if (SREG_WE) begin
                SREG[1:0] <= SREG_D;
            end
            
            if (EIRQ_SET) begin
                SREG[2] <= 1'b1;
            end else if (EIRQ_RESET) begin
                SREG[2] <= 1'b0;
            end else if (S_EX_REQ && (S_CMD == 3'b001)) begin
                SREG[2] <= S_D_WR[2];
            end
        end
    end
    
    //------------------> combinational logic
    assign S_EX_ACK = 1'b1;
    assign S_D_RD = ((S_CMD == 3'b101) && S_EX_REQ) ? {5'b00000, SREG} : 8'h00; 
    
endmodule
