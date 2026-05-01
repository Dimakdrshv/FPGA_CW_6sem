`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Panina T.A.
// 
// Create Date: 01.05.2026 20:18:14
// Design Name: 
// Module Name: CW_PRG_ROM_32B
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Program memory module storing 32-bit processor instructions
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CW_PRG_ROM_32B(
    input  wire        S_EX_REQ,
    input  wire [11:2] S_ADDR,
    output wire        S_EX_ACK,
    output wire [31:0] S_D_RD
);

reg [31:0] ROM [0:1023];
initial $readmemh("prg_mem.mem", ROM);

assign S_D_RD = ROM[S_ADDR];
assign S_EX_ACK = 1'b1;

endmodule
