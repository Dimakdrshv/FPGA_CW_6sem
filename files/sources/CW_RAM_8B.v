`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Panina T. A.
// 
// Create Date: 29.04.2026 22:35:09
// Design Name: 
// Module Name: CW_RAM_8B
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Top-level Data Memory (RAM) module with STI 1.0 bus interface
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CW_RAM_8B #(
    parameter MUAW = 7,     
    parameter UAW  = MUAW + 3
) (
    input            CLK,
    input            S_EX_REQ,
    input  [UAW-1:0] S_ADDR,
    input  [2:0]     S_CMD,
    input  [7:0]     S_D_WR,
    output           S_EX_ACK,
    output [7:0]     S_D_RD
);

wire WE;
assign WE = S_EX_REQ & ~S_CMD[2];

genvar i;
generate
    for(i = 0; i < 8; i = i + 1) begin: generate_spram
        wire [7:0] MEMORY;
    
        CW_SPRAM_UADW #(
            .UAW(MUAW),
            .UDW(8)
        ) BK_MEMORY_ (
            .CLK          (CLK),
            .Address      (S_ADDR[UAW-1:3]),
            .Write_Enable (WE & (S_ADDR[2:0] == i)),
            .Write_Data   (S_D_WR),
            .Read_Data    (MEMORY)
        );
    end
endgenerate

wire RE;
assign RE = S_EX_REQ && S_CMD[2];

assign S_D_RD = RE ? 
               ((generate_spram[0].MEMORY & {8{S_ADDR[2:0] == 3'd0}}) |
                (generate_spram[1].MEMORY & {8{S_ADDR[2:0] == 3'd1}}) |
                (generate_spram[2].MEMORY & {8{S_ADDR[2:0] == 3'd2}}) |
                (generate_spram[3].MEMORY & {8{S_ADDR[2:0] == 3'd3}}) |
                (generate_spram[4].MEMORY & {8{S_ADDR[2:0] == 3'd4}}) |
                (generate_spram[5].MEMORY & {8{S_ADDR[2:0] == 3'd5}}) |
                (generate_spram[6].MEMORY & {8{S_ADDR[2:0] == 3'd6}}) |
                (generate_spram[7].MEMORY & {8{S_ADDR[2:0] == 3'd7}})) : 8'h00;

assign S_EX_ACK = 1'b1;

endmodule
