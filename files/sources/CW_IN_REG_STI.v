`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Semenikhin A.V.
// 
// Create Date: 26.04.2026 18:40:28
// Design Name: 
// Module Name: CW_IN_REG_STI
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Operator's Register
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CW_IN_REG_STI (
    input  wire        CLK,
    input  wire        RST,
    input  wire  [7:0] IN,

    //Unused STI 1.0 Ports
    input  wire  [7:0] S_D_WR,     
    input  wire  [2:0] S_CMD,     
    input  wire        S_EX_REQ,
    input  wire        S_ADDR,   

    output wire  [7:0] S_D_RD,
    output wire        S_EX_ACK
);

    //Chain of registers
    reg [7:0] sync_stage_1;
    reg [7:0] sync_stage_2;

    initial begin
        sync_stage_1 = 8'h00;
        sync_stage_2 = 8'h00;
    end

    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            sync_stage_1 <= 8'h00;
            sync_stage_2 <= 8'h00;
        end else begin
            sync_stage_1 <= IN;
            sync_stage_2 <= sync_stage_1;
        end
    end

    assign S_D_RD = sync_stage_2;
    assign S_EX_ACK = 1'b1;


endmodule
