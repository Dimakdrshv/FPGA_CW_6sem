`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kudryashov D.S.
// 
// Create Date: 16.04.2026 15:45:30
// Design Name: 
// Module Name: CW_REGFILE
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: REGFILE
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CW_REGFILE(
    input   wire        CLK,
    input   wire        RST,
    input   wire        S_EX_REQ,
    input   wire [4:0]  S_ADDR,
    input   wire [2:0]  S_CMD,
    input   wire [7:0]  S_D_WR,
    output  wire        S_EX_ACK,
    output  wire [7:0]  S_D_RD,
    input   wire [4:0]  ADDR0,
    input   wire [4:0]  ADDR1,
    input   wire [4:0]  ADDR2,
    output  wire [7:0]  DATA0,
    output  wire [7:0]  DATA1,
    input   wire [7:0]  DATA2,
    input   wire        RG_WE,
    output  wire [15:0] X,
    input   wire [15:0] X_D,
    input   wire        X_WE,
    output  wire [15:0] Y,
    input   wire [15:0] Y_D,
    input   wire        Y_WE,
    output  wire [15:0] SP,
    input   wire [15:0] SP_D,
    input   wire        SP_WE
    );
    
    //------------------------> initial
    reg [7:0] REGFILE [0:31];
    
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            REGFILE[i] = 8'h0;
        end
    end
    
    localparam DATA_ADDR0 = 8'h00,
               DATA_ADDR1 = 8'h19,
               X_ADDR0 = 8'h1A,
               X_ADDR1 = 8'h1B,
               Y_ADDR0 = 8'h1C,
               Y_ADDR1 = 8'h1D,
               SP_ADDR0 = 8'h1E,
               SP_ADDR1 = 8'h1F;
    
    //------------------------> sequential logic
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            for (i = 0; i < 32; i = i + 1) begin
                REGFILE[i] <= 8'h0;
            end
        end else begin
            if (X_WE) begin
                REGFILE[X_ADDR0] <= X_D[7:0];
                REGFILE[X_ADDR1] <= X_D[15:8];
            end
            if (Y_WE) begin
                REGFILE[Y_ADDR0] <= Y_D[7:0];
                REGFILE[Y_ADDR1] <= Y_D[15:8];
            end 
            if (SP_WE) begin
                REGFILE[SP_ADDR0] <= SP_D[7:0];
                REGFILE[SP_ADDR1] <= SP_D[15:8];
            end 
            if (RG_WE && ~X_WE && ~Y_WE && ~SP_WE) begin
                REGFILE[ADDR2] <= DATA2;
            end
        end
    end
    
    //-------------------------> combinational logic
    assign DATA0 = REGFILE[ADDR0];
    assign DATA1 = REGFILE[ADDR1];
    
    assign X = {REGFILE[X_ADDR1], REGFILE[X_ADDR0]};
    assign Y = {REGFILE[Y_ADDR1], REGFILE[Y_ADDR0]};
    assign SP = {REGFILE[SP_ADDR1], REGFILE[SP_ADDR0]};
    
    assign S_EX_ACK = 1'b1;
    assign S_D_RD = (S_EX_REQ & S_CMD == 3'b101) ? REGFILE[S_ADDR] : S_D_RD;
    
endmodule
