`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kudryashov D.S.
// 
// Create Date: 25.04.2026 15:22:36
// Design Name: 
// Module Name: CW_PC
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Programm counter
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CW_PC (
    // System signals
    input  wire        CLK,
    input  wire        RST,
    
    // STI 1.0
    input  wire        S_EX_REQ,
    input  wire        S_ADDR,
    input  wire  [2:0] S_CMD,
    input  wire  [7:0] S_D_WR,
    output wire        S_EX_ACK,
    output reg   [7:0] S_D_RD,
    
    // PC signals
    output reg  [15:0] PC,
    input  wire [15:0] PCD,
    input  wire        PC_LD,
    input  wire        PC_INC
    );
    
    //--------------> initial
    initial begin
        PC = 16'h0001;
    end
    
    //--------------> sequential logic
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            PC <= 16'h0001;
        end else begin
            if (PC_LD) begin
                PC <= PCD;
            end else if (PC_INC) begin
                PC <= PC + 1'b1;
            end
        end
    end
    
    //-------------> combinational logic
    assign S_EX_ACK = 1'b1;
    
    always @* begin
        if (S_EX_REQ && (S_CMD == 3'b101)) begin
            if (!S_ADDR) begin
                S_D_RD = PC[7:0];
            end else begin
                S_D_RD = PC[15:8];
            end
        end else begin
            S_D_RD = 8'h00;
        end
    end
    
endmodule
