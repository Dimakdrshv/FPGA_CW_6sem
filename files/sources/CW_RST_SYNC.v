`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kudryashov D.S.
// 
// Create Date: 27.04.2026 11:36:50
// Design Name: 
// Module Name: CW_RST_SYNC
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: RST synchronizer
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CW_RST_SYNC
(
    input  wire CLK,
    input  wire SYS_NRST,
    output reg  RST
);

    //---------------> initial
    reg RST_SYNC;
    
    initial begin
        RST      = 1'b0;
        RST_SYNC = 1'b0;
    end
    
    //---------------> sequential logic
    always @(posedge CLK, negedge SYS_NRST) begin
        if (!SYS_NRST) begin
            RST      <= 1'b1;
            RST_SYNC <= 1'b1;
        end else begin
            RST_SYNC <= 1'b0;
            RST      <= RST_SYNC;
        end
    end
    
endmodule
