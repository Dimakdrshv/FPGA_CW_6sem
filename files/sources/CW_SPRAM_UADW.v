`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Panina T.A.
// 
// Create Date: 01.05.2026 19:43:38
// Design Name: 
// Module Name: CW_SPRAM_UADW
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Parametrized Data RAM module for STI 1.0
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CW_SPRAM_UADW #(
    parameter UDW = 8,
    parameter UAW = 7
) (
    input            CLK,
    input  [UAW-1:0] Address,
    input            Write_Enable,
    input  [UDW-1:0] Write_Data,
    output [UDW-1:0] Read_Data
);

reg [UDW-1:0] RG_MEM [(2**UAW)-1:0];

always @ (posedge CLK)
    if(Write_Enable)
        RG_MEM[Address] <= Write_Data;

assign Read_Data = RG_MEM[Address];

endmodule
