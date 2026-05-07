`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Aboba
// Engineer: Ilyasov A.E.
// 
// Create Date: 27.04.2026 12:41:51
// Design Name: 
// Module Name: CW_REG_STI
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: LED Registers
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CW_REG_STI
(
    input wire         CLK,
    input wire         RST,
    input wire         S_EX_REQ,
    input wire         S_ADDR,
    input wire  [ 2:0] S_CMD,
    input wire  [ 7:0] S_D_WR,
   
    output wire        S_EX_ACK,
    output wire [ 7:0] S_D_RD, 
    output wire [15:0] OUT

);
    
    // S_D_RD
    assign S_D_RD = S_ADDR ? OUT[15:8] : OUT[7:0];
    
    // DC
    reg CE_0, CE_1;
    always @(*) begin
        if (S_EX_REQ && (S_CMD == 3'b001)) begin
            if (S_ADDR) begin
                CE_0 = 1'b0;  CE_1 = 1'b1;
            end else begin
                CE_0 = 1'b1; CE_1 = 1'b0;
            end
        end else begin 
            CE_0 = 1'b0; CE_1 = 1'b0;
        end    
    end

    reg [7:0] RG_0 = 8'h00;
    reg [7:0] RG_1 = 8'h00;
    always @(posedge CLK, posedge RST)
    begin   
        if (RST) begin
            RG_0 <= 8'h00;
            RG_1 <= 8'h00;
        end else begin
            if (CE_0)
                RG_0 <= S_D_WR;
            if (CE_1)
                RG_1 <= S_D_WR;
        end
    end

    assign S_EX_ACK = 1'b1;
    assign OUT = {RG_1, RG_0};
    
endmodule
