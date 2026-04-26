`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.04.2026 18:40:28
// Design Name: 
// Module Name: CW_IN_REG_STI
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CW_IN_REG_STI (
    input  wire        CLK,
    input  wire        RST,
    input  wire  [7:0] IN,

    //Сигналы протокола STI 1.0 (не используются)
    input  wire  [7:0] S_D_WR,     
    input  wire  [2:0] S_CMD,     
    input  wire        S_EX_REQ,   

    output wire  [7:0] S_D_RD,
    output wire        S_EX_ACK
);

    // Внутренние регистры для цепочки синхронизации
    reg [7:0] sync_stage_1;
    reg [7:0] sync_stage_2;

    always @(posedge CLK) begin
        if (RST) begin
            sync_stage_1 <= 8'b0;
        end else begin
            sync_stage_1 <= IN;
        end
    end

    always @(posedge CLK) begin
        if (RST) begin
            sync_stage_2 <= 8'b0;
        end else begin
            sync_stage_2 <= sync_stage_1;
        end
    end

    assign S_D_RD = sync_stage_2;
    assign S_EX_ACK = 1'b1;

    //Предотвращение предупреждений компилятора о неиспользуемых входах
    wire unused_inputs_check;
    assign unused_inputs_check = &{S_D_WR, S_CMD, S_EX_REQ}; 

endmodule
