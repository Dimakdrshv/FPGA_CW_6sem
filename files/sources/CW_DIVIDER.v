`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Semenikhin A.V.
// 
// Create Date: 26.04.2026 15:07:16
// Design Name: 
// Module Name: CW_DIVIDER
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Frequency divider
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CW_DIVIDER #(
    parameter MOD = 12)
    (
    input      CLK,
    input      RST,
    output reg CE
    );
    
    localparam CNT_WDT = $clog2(MOD);
    
    reg [CNT_WDT-1:0] CNT;

	initial begin
        CNT = {CNT_WDT{1'b0}};
        CE  = 1'b0;
    end
 
	always @(posedge CLK, posedge RST) begin
        if (RST) begin
            CNT <= {CNT_WDT{1'b0}};
            CE <= 1'b0;
        end else begin
			if (CNT == (MOD - 1)) begin
                CNT <= {CNT_WDT{1'b0}};
				CE <= 1'b1;
			end else begin
				CE <= 1'b0;
				CNT <= CNT + 1;
			end
        end
	end
        
endmodule
	
