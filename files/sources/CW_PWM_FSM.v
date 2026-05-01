`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Semenikhin A.V.
// 
// Create Date: 01.05.2026 16:46:01
// Design Name: 
// Module Name: CW_PWM_FSM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: PWM Generator
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CW_PWM_FSM #(
    parameter UDW = 4
) (
    input CLK,
    input RST,
    input RE,
    input CE,
    input [UDW-1:0] PWM_IN,
    output reg PWM_P,
    output reg PWM_N
);

    reg [UDW-1:0] PWM_REG;
    reg [UDW-1:0] FSM_STATE;
    
    initial begin
        PWM_REG = {UDW{1'b0}};
        FSM_STATE = {UDW{1'b0}};
    end
    
    wire [UDW-1:0] STATE_ZERO = {UDW{1'b0}};
    wire [UDW-1:0] STATE_MAX = {UDW{1'b1}};
    wire [UDW-1:0] STATE_MAX_M1 = STATE_MAX - 1;
    
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            FSM_STATE <= STATE_ZERO;
            PWM_P <= 1'b0;
            PWM_N <= 1'b1;
            PWM_REG <= STATE_ZERO;
        end
        else if (RE) begin
            FSM_STATE <= STATE_ZERO;
            PWM_P <= 1'b0;
            PWM_N <= 1'b1;
        end
        else if (CE) begin
            case (FSM_STATE)
                STATE_ZERO: begin
                    //0
                    FSM_STATE <= STATE_MAX_M1;
                    PWM_P <= 1'b0;
                    PWM_N <= 1'b1;
                end
                
                STATE_MAX: begin
                    //2^UDW - 1
                    FSM_STATE <= 1;
                    if (PWM_REG == STATE_ZERO) begin
                        PWM_P <= 1'b0;
                        PWM_N <= 1'b1;
                    end
                    else begin
                        PWM_P <= 1'b1;
                        PWM_N <= 1'b0;
                    end
                end
                
                STATE_MAX_M1: begin
                    //2^UDW - 2
                    FSM_STATE <= STATE_MAX;
                    PWM_REG <= PWM_IN;
                    
                    if (PWM_REG > STATE_MAX_M1) begin
                        PWM_P <= 1'b1;
                        PWM_N <= 1'b0;
                    end
                    else begin
                        PWM_P <= 1'b0;
                        PWM_N <= 1'b1;
                    end
                end
                
                default: begin
                    //k
                    FSM_STATE <= FSM_STATE + 1;
                    
                    if (FSM_STATE < PWM_REG) begin
                        PWM_P <= 1'b1;
                        PWM_N <= 1'b0;
                    end
                    else begin
                        PWM_P <= 1'b0;
                        PWM_N <= 1'b1;
                    end
                end
            endcase
        end
    end
    

endmodule