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
// Description: STI 1.0 CPU bus router
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CW_CPU_INFS8B(
    input        T_S_EX_REQ,
    input  [5:0] T_S_ADDR,
    input  [2:0] T_S_CMD,
    input  [7:0] T_S_D_WR,
 
    input        I1_S_EX_ACK,
    input  [7:0] I1_S_D_RD,
    input        I2_S_EX_ACK,
    input  [7:0] I2_S_D_RD,
    input        I3_S_EX_ACK,
    input  [7:0] I3_S_D_RD,

    output       T_S_EX_ACK,
    output [7:0] T_S_D_RD,
       
    output       I1_S_EX_REQ,
    output [4:0] I1_S_ADDR, 
    output [2:0] I1_S_CMD,
    output [7:0] I1_S_D_WR,
    output       I2_S_EX_REQ,
    output       I2_S_ADDR, 
    output [2:0] I2_S_CMD,
    output [7:0] I2_S_D_WR,
    output       I3_S_EX_REQ,
    output       I3_S_ADDR,
    output [2:0] I3_S_CMD,
    output [7:0] I3_S_D_WR
);
    
reg [2:0] EN;
always @* begin
    casex ({T_S_CMD, T_S_ADDR})
        {3'b101, 6'b0xxxxx}: EN = 3'b001; // 000000b - 011111b : Select POH (I1)
        {3'bx01, 6'b100000}: EN = 3'b010; // 100000b           : Select SREG (I2)
        {3'b101, 6'b10001x}: EN = 3'b100; // 100010b - 100011b : Select PC (I3)
        default:   EN = 3'b000;
    endcase
end

assign I1_S_D_WR = T_S_D_WR;
assign I2_S_D_WR = T_S_D_WR;
assign I3_S_D_WR = T_S_D_WR;

assign I1_S_CMD  = T_S_CMD;
assign I2_S_CMD  = T_S_CMD;
assign I3_S_CMD  = T_S_CMD;
 
assign I1_S_ADDR = T_S_ADDR[4:0];
assign I2_S_ADDR = 1'b0;          
assign I3_S_ADDR = T_S_ADDR[0];

assign I1_S_EX_REQ = T_S_EX_REQ & EN[0];
assign I2_S_EX_REQ = T_S_EX_REQ & EN[1];
assign I3_S_EX_REQ = T_S_EX_REQ & EN[2];

assign T_S_EX_ACK = (I1_S_EX_ACK | ~EN[0]) & 
                    (I2_S_EX_ACK | ~EN[1]) & 
                    (I3_S_EX_ACK | ~EN[2]);

assign T_S_D_RD   = (I1_S_D_RD | ~{8{EN[0]}}) & 
                    (I2_S_D_RD | ~{8{EN[1]}}) & 
                    (I3_S_D_RD | ~{8{EN[2]}});

endmodule

