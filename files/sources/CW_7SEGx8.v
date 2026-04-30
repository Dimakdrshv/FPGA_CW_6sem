`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kudryashov D.S.
// 
// Create Date: 30.04.2026 17:19:48
// Design Name: 
// Module Name: CW_7SEGx8
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 7-SEG
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CW_7SEGx8
(
    input  wire        CLK,
    input  wire        RST,
    
    input  wire        CE, // 1kHz impulse
    input  wire [31:0] HEX_IN,
    input  wire [7:0]  BLANK, // 0 - on, 1 - off (segment)
    input  wire [7:0]  DP_IN, // 1 - on, 0 - off (dot)
    
    output reg  [7:0]  AN, // 0 - on, 1 - off
    output reg  [7:0]  CAT // 0 - on, 1 - off
);

    //-----------------> initial
    reg  [2:0] COUNTER;
    reg  [6:0] CAT_HEX;
    wire [3:0] NUMBER;
    wire       I_EN;
    wire       DP;
    
    initial begin
        COUNTER = 3'b000;
    end
    
    //-----------------> sequantial logic
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            COUNTER <= 3'b000;
        end else begin
            if (CE) begin
                COUNTER <= COUNTER + 1'b1;
            end
        end
    end
    
    //-----------------> combinational logic
    assign NUMBER = HEX_IN[COUNTER * 4 +: 4];
    assign I_EN   = ~BLANK[COUNTER];
    assign DP     = ~DP_IN[COUNTER];
    
    always @* begin
        case (COUNTER)
            3'b000:  AN = 8'b1111_1110;
            3'b001:  AN = 8'b1111_1101; 
            3'b010:  AN = 8'b1111_1011;
            3'b011:  AN = 8'b1111_0111;
            3'b100:  AN = 8'b1110_1111;
            3'b101:  AN = 8'b1101_1111;
            3'b110:  AN = 8'b1011_1111;
            3'b111:  AN = 8'b0111_1111;
            
            default: AN = 8'b1111_1111;
        endcase
    end
    
    always @* begin
        case (NUMBER)
            4'h0:    CAT_HEX = 7'b1000000;
            4'h1:    CAT_HEX = 7'b1111001;
            4'h2:    CAT_HEX = 7'b0100100;
            4'h3:    CAT_HEX = 7'b0110000;
            4'h4:    CAT_HEX = 7'b0011001;
            4'h5:    CAT_HEX = 7'b0010010;
            4'h6:    CAT_HEX = 7'b0000010;
            4'h7:    CAT_HEX = 7'b1111000;
            4'h8:    CAT_HEX = 7'b0000000;
            4'h9:    CAT_HEX = 7'b0010000;
            4'hA:    CAT_HEX = 7'b0001000;
            4'hB:    CAT_HEX = 7'b0000011;
            4'hC:    CAT_HEX = 7'b1000110;
            4'hD:    CAT_HEX = 7'b0100001;
            4'hE:    CAT_HEX = 7'b0000110;
            4'hF:    CAT_HEX = 7'b0001110;
            
            default: CAT_HEX = 7'b1111111;
        endcase
        
        if (I_EN) begin
            CAT = {DP, CAT_HEX};
        end else begin
            CAT = 8'b1111_1111;
        end
    end
    
endmodule
