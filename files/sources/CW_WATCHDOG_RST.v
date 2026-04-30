`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kudryashov D.S.
// 
// Create Date: 30.04.2026 16:56:42
// Design Name: 
// Module Name: CW_WATCHDOG_RST
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Watchdog reset
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CW_WATCHDOG_RST
(
    input  wire CLK,
    input  wire RST,
    input  wire CE, // impulse on 1 kHz
    output reg  N_ST
);
    
    //-----------> initial
    initial begin
        N_ST = 1'b0;
    end
    
    //-----------> sequantial logic
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            N_ST <= 1'b0;
        end else begin
            if (CE) begin
                N_ST <= ~N_ST;
            end else begin
                N_ST <= N_ST;
            end
        end
    end
    
endmodule
