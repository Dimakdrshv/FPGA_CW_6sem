`timescale 1ns / 1ps

module CW_DIVIDER #(
    parameter DIVIDER = 12)
    (
    input      CLK,
    input      RST,
    output reg CE
    );
    
    localparam CNT_WDT = $clog2(DIVIDER);
    
    reg [CNT_WDT-1:0] CNT;
 
    always @(posedge CLK)
        if(RST) begin
            CNT <= {CNT_WDT{1'b0}};
            CE <= 1'b0;
        end
        else begin
            if(CNT == (DIVIDER - 1)) 
                CNT <= {CNT_WDT{1'b0}};
            else 
                CNT <= CNT + 1;
            CE <= (CNT == (DIVIDER - 1));
        end
        
endmodule
	
