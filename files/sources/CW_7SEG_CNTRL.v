`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kudryashov D.S.
// 
// Create Date: 30.04.2026 19:00:25
// Design Name: 
// Module Name: CW_7SEG_CNTRL
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 7-seg controller
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CW_7SEG_CNTRL
(
    input  wire       CLK,
    input  wire       RST,
    input  wire       CE,
    
    input  wire       S_EX_REQ,
    input  wire [2:0] S_ADDR,
    input  wire [2:0] S_CMD,
    input  wire [7:0] S_D_WR,
    output wire       S_EX_ACK,
    output reg  [7:0] S_D_RD,
    
    output wire [7:0] AN,
    output wire [7:0] CAT
);

    //--------------> initial
    reg  [31:0] HEX_IN;
    reg  [7:0]  BLANK;
    reg  [7:0]  DP_IN;
    wire        CE_HEX_0, CE_HEX_1, CE_HEX_2, CE_HEX_3;
    wire        CE_BLANK;
    wire        CE_DP_IN;      
    
    initial begin
        HEX_IN = {(32){1'b0}};
        BLANK  = 8'hFF;
        DP_IN  = 8'h00;
    end
    
    //--------------> combinational logic
    assign CE_HEX_3 = S_EX_REQ && (S_CMD == 3'b001) && (S_ADDR == 3'b000);
    assign CE_HEX_2 = S_EX_REQ && (S_CMD == 3'b001) && (S_ADDR == 3'b001);
    assign CE_HEX_1 = S_EX_REQ && (S_CMD == 3'b001) && (S_ADDR == 3'b010);
    assign CE_HEX_0 = S_EX_REQ && (S_CMD == 3'b001) && (S_ADDR == 3'b011);
    assign CE_BLANK = S_EX_REQ && (S_CMD == 3'b001) && (S_ADDR == 3'b100);
    assign CE_DP_IN = S_EX_REQ && (S_CMD == 3'b001) && (S_ADDR == 3'b101);
    
    always @* begin
        case (S_ADDR)
            3'b000:  S_D_RD = HEX_IN[31:24];
            3'b001:  S_D_RD = HEX_IN[23:16];
            3'b010:  S_D_RD = HEX_IN[15:8];
            3'b011:  S_D_RD = HEX_IN[7:0];
            3'b100:  S_D_RD = BLANK;
            3'b101:  S_D_RD = DP_IN;
            default: S_D_RD = 8'b0000_0000;
        endcase
    end
    
    assign S_EX_ACK = 1'b1;
    
    //--------------> sequantial logic
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            HEX_IN <= {(32){1'b0}};
            BLANK  <= 8'hFF;
            DP_IN  <= 8'h00;
        end else begin
            HEX_IN[31:24] <= CE_HEX_3 ? S_D_WR : HEX_IN[31:24];
            HEX_IN[23:16] <= CE_HEX_2 ? S_D_WR : HEX_IN[23:16];
            HEX_IN[15:8]  <= CE_HEX_1 ? S_D_WR : HEX_IN[15:8];
            HEX_IN[7:0]   <= CE_HEX_0 ? S_D_WR : HEX_IN[7:0];
            BLANK         <= CE_BLANK ? S_D_WR : BLANK;
            DP_IN         <= CE_DP_IN ? S_D_WR : DP_IN;
        end
    end
    
    //--------------> 7-seg driver
    CW_7SEGx8 cw_7segx8
    (
        .CLK(CLK),
        .RST(RST),
        .CE(CE),
        .HEX_IN(HEX_IN),
        .BLANK(BLANK),
        .DP_IN(DP_IN),
        .AN(AN),
        .CAT(CAT)
    );

endmodule