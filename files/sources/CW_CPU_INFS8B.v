`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Panina T.A.
// 
// Create Date: 25.04.2026 18:29:46
// Design Name: 
// Module Name: CW_CPU_INFS8B
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: STI 1.0 system bus router
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CW_CPU_INFS8B(
    input         T_S_EX_REQ,
    input  [15:0] T_S_ADDR,
    input  [2:0]  T_S_CMD,
    input  [7:0]  T_S_D_WR,
  
    input         I0_S_EX_ACK,
    input  [7:0]  I0_S_D_RD,
    input         I1_S_EX_ACK,
    input  [7:0]  I1_S_D_RD,
    input         I2_S_EX_ACK,
    input  [7:0]  I2_S_D_RD,
    input         I3_S_EX_ACK,
    input  [7:0]  I3_S_D_RD,
    input         I4_S_EX_ACK,
    input  [7:0]  I4_S_D_RD,
    input         I5_S_EX_ACK,
    input  [7:0]  I5_S_D_RD,
    input         I6_S_EX_ACK,
    input  [7:0]  I6_S_D_RD,
    input         I7_S_EX_ACK,
    input  [7:0]  I7_S_D_RD,

    output        T_S_EX_ACK,
    output [7:0]  T_S_D_RD,
        
    output        I0_S_EX_REQ,
    output [5:0]  I0_S_ADDR,
    output [2:0]  I0_S_CMD,
    output [7:0]  I0_S_D_WR,
    output        I1_S_EX_REQ,
    output        I1_S_ADDR, 
    output [2:0]  I1_S_CMD,
    output [7:0]  I1_S_D_WR,
    output        I2_S_EX_REQ,
    output        I2_S_ADDR, 
    output [2:0]  I2_S_CMD,
    output [7:0]  I2_S_D_WR,
    output        I3_S_EX_REQ,
    output [1:0]  I3_S_ADDR,
    output [2:0]  I3_S_CMD,
    output [7:0]  I3_S_D_WR,
    output        I4_S_EX_REQ,
    output [2:0]  I4_S_ADDR,
    output [2:0]  I4_S_CMD,
    output [7:0]  I4_S_D_WR,
    output        I5_S_EX_REQ,
    output        I5_S_ADDR,
    output [2:0]  I5_S_CMD,
    output [7:0]  I5_S_D_WR,
    output        I6_S_EX_REQ,
    output [2:0]  I6_S_ADDR,
    output [2:0]  I6_S_CMD,
    output [7:0]  I6_S_D_WR,
    output        I7_S_EX_REQ,
    output [9:0]  I7_S_ADDR,
    output [2:0]  I7_S_CMD,
    output [7:0]  I7_S_D_WR
);
    
reg [7:0] EN;
always @* begin
    EN = 8'b0000_0000;
    casex ({T_S_CMD, T_S_ADDR})
        {3'bx00, 16'b1001_1011_10xx_xxxx}: EN[0] = 1'b1; // I0: 9B80h - 9BBFh (Регистры ядра)
        {3'bx00, 16'h180C}:                EN[1] = 1'b1; // I1: 180Ch         (Регистр А)
        {3'bx00, 16'h3E61}:                EN[2] = 1'b1; // I2: 3E61h         (Регистр B)
        {3'bx00, 16'b0101_0000_1111_10xx}: EN[3] = 1'b1; // I3: 50F8h - 50FBh (RGB матрица)
        {3'bx00, 16'b1000_0111_1100_0xxx}: EN[4] = 1'b1; // I4: 87C0h - 87C7h (7-сегментные)
        {3'bx00, 16'b1000_0001_0000_011x}: EN[5] = 1'b1; // I5: 8106h - 8107h (Светодиоды)
        {3'bx00, 16'b0000_0010_0111_0xxx}: EN[6] = 1'b1; // I6: 0270h - 0277h (Монитор прерываний)
        {3'bx01, 16'b1001_00xx_xxxx_xxxx}: EN[7] = 1'b1; // I7: 9000h - 93FFh (Память данных)
        default: EN = 8'b0000_0000;
    endcase
end

assign I0_S_D_WR = T_S_D_WR;
assign I1_S_D_WR = T_S_D_WR;
assign I2_S_D_WR = T_S_D_WR;
assign I3_S_D_WR = T_S_D_WR;
assign I4_S_D_WR = T_S_D_WR;
assign I5_S_D_WR = T_S_D_WR;
assign I6_S_D_WR = T_S_D_WR;
assign I7_S_D_WR = T_S_D_WR;

assign I0_S_CMD = T_S_CMD;
assign I1_S_CMD = T_S_CMD;
assign I2_S_CMD = T_S_CMD;
assign I3_S_CMD = T_S_CMD;
assign I4_S_CMD = T_S_CMD;
assign I5_S_CMD = T_S_CMD;
assign I6_S_CMD = T_S_CMD;
assign I7_S_CMD = T_S_CMD;
 
assign I0_S_ADDR = T_S_ADDR[5:0];
assign I1_S_ADDR = 1'b0;          
assign I2_S_ADDR = 1'b0;          
assign I3_S_ADDR = T_S_ADDR[1:0];
assign I4_S_ADDR = T_S_ADDR[2:0];
assign I5_S_ADDR = T_S_ADDR[0];
assign I6_S_ADDR = T_S_ADDR[2:0];
assign I7_S_ADDR = T_S_ADDR[9:0];

assign I0_S_EX_REQ = T_S_EX_REQ & EN[0];
assign I1_S_EX_REQ = T_S_EX_REQ & EN[1];
assign I2_S_EX_REQ = T_S_EX_REQ & EN[2];
assign I3_S_EX_REQ = T_S_EX_REQ & EN[3];
assign I4_S_EX_REQ = T_S_EX_REQ & EN[4];
assign I5_S_EX_REQ = T_S_EX_REQ & EN[5];
assign I6_S_EX_REQ = T_S_EX_REQ & EN[6];
assign I7_S_EX_REQ = T_S_EX_REQ & EN[7];

assign T_S_EX_ACK = (I0_S_EX_ACK | ~EN[0]) & 
                    (I1_S_EX_ACK | ~EN[1]) & 
                    (I2_S_EX_ACK | ~EN[2]) & 
                    (I3_S_EX_ACK | ~EN[3]) & 
                    (I4_S_EX_ACK | ~EN[4]) & 
                    (I5_S_EX_ACK | ~EN[5]) & 
                    (I6_S_EX_ACK | ~EN[6]) & 
                    (I7_S_EX_ACK | ~EN[7]);

assign T_S_D_RD   = (I0_S_D_RD | ~{8{EN[0]}}) & 
                    (I1_S_D_RD | ~{8{EN[1]}}) & 
                    (I2_S_D_RD | ~{8{EN[2]}}) & 
                    (I3_S_D_RD | ~{8{EN[3]}}) & 
                    (I4_S_D_RD | ~{8{EN[4]}}) & 
                    (I5_S_D_RD | ~{8{EN[5]}}) & 
                    (I6_S_D_RD | ~{8{EN[6]}}) & 
                    (I7_S_D_RD | ~{8{EN[7]}});

endmodule

