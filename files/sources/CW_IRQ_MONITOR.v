`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.04.2026 01:52:44
// Design Name: Semenikhin A.V.
// Module Name: CW_IRQ_MONTIOR
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Interruption request monitor
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CW_IRQ_MONITOR (
    input  wire       CLK,
    input  wire       RST,
    input  wire       CE,

    input  wire       S_EX_REQ,
    input  wire [2:0] S_ADDR,
    input  wire [2:0] S_CMD,
    input  wire [7:0] S_D_WR,

    output wire       S_EX_ACK,
    output reg  [7:0] S_D_RD,

    output wire       IRQ,
    input  wire [3:0] BTN
);
    //Permissive wire for DC
    wire io_wr_cmd;

    //I don't know which S_CMD Sequence is permissive for DC. So for now it is 000.
    assign io_wr_cmd = S_EX_REQ & (S_CMD == 3'b001);

    wire [3:0] btn_filt;

    CW_BTN_FILTER u_btn_filter_0 (
        .BTN_IN  (BTN[0]),
        .CE      (CE),
        .CLK     (CLK),
        .RST     (RST),
        .BTN_CEO (btn_filt[0])
    );

    CW_BTN_FILTER u_btn_filter_1 (
        .BTN_IN  (BTN[1]),
        .CE      (CE),
        .CLK     (CLK),
        .RST     (RST),
        .BTN_CEO (btn_filt[1])
    );

    CW_BTN_FILTER u_btn_filter_2 (
        .BTN_IN  (BTN[2]),
        .CE      (CE),
        .CLK     (CLK),
        .RST     (RST),
        .BTN_CEO (btn_filt[2])
    );

    CW_BTN_FILTER u_btn_filter_3 (
        .BTN_IN  (BTN[3]),
        .CE      (CE),
        .CLK     (CLK),
        .RST     (RST),
        .BTN_CEO (btn_filt[3])
    );


    reg [3:0] irq_flag;
    reg [3:0] mirq;

    initial begin
        irq_flag = 4'h0;
        mirq = 4'h0;
    end

    //Registers logic
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            irq_flag <= 4'b0000;
            mirq     <= 4'b0000;
        end else begin

            if (btn_filt[0]) irq_flag[0] <= 1'b1;
            else if (io_wr_cmd && (S_ADDR[2:0] == 2'b000))
                irq_flag[0] <= 1'b0;

            if (btn_filt[1]) irq_flag[1] <= 1'b1;
            else if (io_wr_cmd && (S_ADDR[2:0] == 2'b001))
                irq_flag[1] <= 1'b0;

            if (btn_filt[2]) irq_flag[2] <= 1'b1;
            else if (io_wr_cmd && (S_ADDR[2:0] == 2'b010))
                irq_flag[2] <= 1'b0;

            if (btn_filt[3]) irq_flag[3] <= 1'b1;
            else if (io_wr_cmd && (S_ADDR[2:0] == 2'b011))
                irq_flag[3] <= 1'b0;

            if (io_wr_cmd && (S_ADDR[2] == 1'b1)) begin
                mirq <= S_D_WR[3:0];
            end
        end
    end
    
    //Small mux
    always @* begin
            if (S_ADDR[2] == 1'b0) begin
                //Big mux
                case (S_ADDR[1:0])
                    2'b00: S_D_RD = {7'h00, irq_flag[0] && mirq[0]};
                    2'b01: S_D_RD = {7'h00, irq_flag[1] && mirq[1]};
                    2'b10: S_D_RD = {7'h00, irq_flag[2] && mirq[2]};
                    2'b11: S_D_RD = {7'h00, irq_flag[3] && mirq[3]};
                endcase
            end else begin
                S_D_RD = {4'h0, mirq};
            end
    end

    assign IRQ = |(irq_flag & mirq);
    assign S_EX_ACK = 1'b1;

endmodule
