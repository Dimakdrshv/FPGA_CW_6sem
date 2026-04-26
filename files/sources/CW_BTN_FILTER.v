`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kudryashov D.S.
// 
// Create Date: 25.04.2026 23:07:16
// Design Name: 
// Module Name: CW_BTN_FILTER
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Button Filter
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CW_BTN_FILTER
#(
    parameter SIZE = 4
)
(
    input  wire BTN_IN,
    input  wire CE,
    input  wire CLK,
    input  wire RST,
    output reg  BTN_CEO
);
    
    //-------------> initial
    reg [SIZE-1:0] COUNTER;
    reg            BTN_OUT;         // for next stages (BTN_OUT)
    reg   [1:0]    BTN_SIGNAL_SYNC;
    
    initial begin
        BTN_CEO         = 1'b0;
        COUNTER         = {(SIZE){1'b0}};
        BTN_OUT         = 1'b0;
        BTN_SIGNAL_SYNC = 2'b00;
    end
    
    //------------> sequantial logic
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            BTN_CEO         <= 1'b0;
            COUNTER         <= {(SIZE){1'b0}};
            BTN_OUT         <= 1'b0;
            BTN_SIGNAL_SYNC <= 2'b00;
        end else begin
            BTN_SIGNAL_SYNC <= {BTN_SIGNAL_SYNC[0], BTN_IN};
            COUNTER         <= (BTN_SIGNAL_SYNC[1] ^~ BTN_OUT) ? {(SIZE){1'b0}} 
                                                               : CE 
                                                               ? COUNTER + 1'b1 
                                                               : COUNTER;
            
            if ((&COUNTER) && CE) begin
                BTN_OUT <= BTN_SIGNAL_SYNC[1];
            end
            
            BTN_CEO <= (&COUNTER) && CE && BTN_SIGNAL_SYNC[1];
        end
    end
    
endmodule
