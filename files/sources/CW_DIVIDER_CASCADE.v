`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kudryashov D.S.
// 
// Create Date: 07.05.2026 17:08:14
// Design Name: 
// Module Name: CW_DIVIDER_CASCADE
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Cascaded clock divider stage (second stage)
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CW_DIVIDER_CASCADE
#(
    parameter MOD = 10
)
(
    input  wire CLK,
    input  wire RST,
    input  wire CE,
    output reg  CEO
);
    
    localparam CNT_WDT = $clog2(MOD);
    reg [CNT_WDT - 1 : 0] CNT;
    
    initial begin
        CNT = {(CNT_WDT){1'b0}};
        CEO = 1'b0;
    end
    
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            CNT <= {(CNT_WDT){1'b0}};
            CEO <= 1'b0;
        end else begin
            if (CE) begin
                if (CNT == (MOD - 1)) begin
                    CNT <= {(CNT_WDT){1'b0}};
                end else begin
                    CNT <= CNT + 1'b1;
                end
            end
            CEO <= (CNT == (MOD - 1)) & CE;
        end
    end
    
endmodule
