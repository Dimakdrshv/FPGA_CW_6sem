`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05.05.2026
// Design Name:
// Module Name: CW_RGB_CONTROLLER
// Project Name:
// Target Devices:
// Tool Versions:
// Description: RGB matrix controller with STI 1.0 registers
//
// Dependencies: CW_PWM_FSM
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module CW_RGB_CONTROLLER
(
    input  wire       CLK,
    input  wire       RST,
    input  wire       CE_PWM,

    input  wire       S_EX_REQ,
    input  wire [1:0] S_ADDR,
    input  wire [2:0] S_CMD,
    input  wire [7:0] S_D_WR,
    output wire       S_EX_ACK,
    output reg  [7:0] S_D_RD,

    output reg  [7:0] COL_R,
    output reg  [7:0] COL_G,
    output reg  [7:0] COL_B,
    output reg  [7:0] ROW
);

    localparam [2:0] STI_CMD_WR = 3'b001;
    localparam [2:0] STI_CMD_RD = 3'b101;

    localparam [1:0] ADDR_DATA  = 2'b00;
    localparam [1:0] ADDR_PWM_R = 2'b01;
    localparam [1:0] ADDR_PWM_B = 2'b10;
    localparam [1:0] ADDR_PWM_G = 2'b11;

    localparam [1:0] MOD3_R = 2'd0;
    localparam [1:0] MOD3_G = 2'd1;
    localparam [1:0] MOD3_B = 2'd2;

    reg [3:0] DATA_HEX;
    reg [3:0] DATA;
    reg [7:0] PWM_R;
    reg [7:0] PWM_G;
    reg [7:0] PWM_B;

    reg [7:0] CT_PWM;
    reg [1:0] CT_MOD3;
    reg [2:0] CT_MATRIX;

    wire       CE_24X;
    wire       CE_8X;
    wire [7:0] DC3_8;
    wire [7:0] ROW_DATA;

    wire PWM_R_P;
    wire PWM_R_N;
    wire PWM_G_P;
    wire PWM_G_N;
    wire PWM_B_P;
    wire PWM_B_N;

    initial begin
        DATA_HEX  = 4'h0;
        DATA      = 4'h0;
        PWM_R     = 8'h00;
        PWM_G     = 8'h00;
        PWM_B     = 8'h00;
        CT_PWM    = 8'h00;
        CT_MOD3   = MOD3_R;
        CT_MATRIX = 3'b000;
        COL_R     = 8'h00;
        COL_G     = 8'h00;
        COL_B     = 8'h00;
        ROW       = 8'h00;
        S_D_RD    = 8'h00;
    end

    assign CE_24X = CE_PWM && (CT_PWM == 8'hFF);
    assign CE_8X  = CE_24X && (CT_MOD3 == MOD3_B);
    assign DC3_8  = 8'b0000_0001 << CT_MATRIX;
    assign ROW_DATA = HEX_COLUMN(DATA, CT_MATRIX);

    assign S_EX_ACK = 1'b1;

    always @* begin
        S_D_RD = 8'h00;

        if (S_EX_REQ && (S_CMD == STI_CMD_RD)) begin
            case (S_ADDR)
                ADDR_DATA:  S_D_RD = {4'h0, DATA_HEX};
                ADDR_PWM_R: S_D_RD = PWM_R;
                ADDR_PWM_B: S_D_RD = PWM_B;
                ADDR_PWM_G: S_D_RD = PWM_G;
                default:    S_D_RD = 8'h00;
            endcase
        end
    end

    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            DATA_HEX <= 4'h0;
            DATA     <= 4'h0;
            PWM_R    <= 8'h00;
            PWM_G    <= 8'h00;
            PWM_B    <= 8'h00;
        end else begin
            if (S_EX_REQ && (S_CMD == STI_CMD_WR)) begin
                case (S_ADDR)
                    ADDR_DATA:  DATA_HEX <= S_D_WR[3:0];
                    ADDR_PWM_R: PWM_R    <= S_D_WR;
                    ADDR_PWM_B: PWM_B    <= S_D_WR;
                    ADDR_PWM_G: PWM_G    <= S_D_WR;
                    default: begin
                        DATA_HEX <= DATA_HEX;
                        PWM_R    <= PWM_R;
                        PWM_G    <= PWM_G;
                        PWM_B    <= PWM_B;
                    end
                endcase
            end

            // The visible symbol changes only after the last RGB pass of column 7.
            if (CE_8X && (CT_MATRIX == 3'd7)) begin
                DATA <= DATA_HEX;
            end
        end
    end

    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            CT_PWM    <= 8'h00;
            CT_MOD3   <= MOD3_R;
            CT_MATRIX <= 3'b000;
        end else begin
            if (CE_PWM) begin
                CT_PWM <= CT_PWM + 1'b1;
            end

            if (CE_24X) begin
                if (CT_MOD3 == MOD3_B) begin
                    CT_MOD3 <= MOD3_R;
                end else begin
                    CT_MOD3 <= CT_MOD3 + 1'b1;
                end
            end

            if (CE_8X) begin
                CT_MATRIX <= CT_MATRIX + 1'b1;
            end
        end
    end

    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            COL_R <= 8'h00;
            COL_G <= 8'h00;
            COL_B <= 8'h00;
            ROW   <= 8'h00;
        end else begin
            COL_R <= 8'h00;
            COL_G <= 8'h00;
            COL_B <= 8'h00;
            ROW   <= ROW_DATA;

            case (CT_MOD3)
                MOD3_R: COL_R <= DC3_8 & {8{PWM_R_P}};
                MOD3_G: COL_G <= DC3_8 & {8{PWM_G_P}};
                MOD3_B: COL_B <= DC3_8 & {8{PWM_B_P}};
                default: begin
                    COL_R <= 8'h00;
                    COL_G <= 8'h00;
                    COL_B <= 8'h00;
                end
            endcase
        end
    end

    CW_PWM_FSM #(
        .UDW(8)
    ) cw_pwm_fsm_r (
        .CLK(CLK),
        .RST(RST),
        .RE(1'b0),
        .CE(CE_PWM),
        .PWM_IN(PWM_R),
        .PWM_P(PWM_R_P),
        .PWM_N(PWM_R_N)
    );

    CW_PWM_FSM #(
        .UDW(8)
    ) cw_pwm_fsm_g (
        .CLK(CLK),
        .RST(RST),
        .RE(1'b0),
        .CE(CE_PWM),
        .PWM_IN(PWM_G),
        .PWM_P(PWM_G_P),
        .PWM_N(PWM_G_N)
    );

    CW_PWM_FSM #(
        .UDW(8)
    ) cw_pwm_fsm_b (
        .CLK(CLK),
        .RST(RST),
        .RE(1'b0),
        .CE(CE_PWM),
        .PWM_IN(PWM_B),
        .PWM_P(PWM_B_P),
        .PWM_N(PWM_B_N)
    );

    function [7:0] HEX_COLUMN;
        input [3:0] HEX;
        input [2:0] COL;
        begin
            HEX_COLUMN = 8'h00;

            case (HEX)
                4'h0: begin
                    case (COL)
                        3'd0: HEX_COLUMN = 8'b0000_0000;
                        3'd1: HEX_COLUMN = 8'b0111_1100;
                        3'd2: HEX_COLUMN = 8'b1111_1110;
                        3'd3: HEX_COLUMN = 8'b1001_0010;
                        3'd4: HEX_COLUMN = 8'b1010_0010;
                        3'd5: HEX_COLUMN = 8'b1111_1110;
                        3'd6: HEX_COLUMN = 8'b0111_1100;
                        3'd7: HEX_COLUMN = 8'b0000_0000;
                        default: HEX_COLUMN = 8'h00;
                    endcase
                end

                4'h1: begin
                    case (COL)
                        3'd0: HEX_COLUMN = 8'b0000_0000;
                        3'd1: HEX_COLUMN = 8'b0000_0010;
                        3'd2: HEX_COLUMN = 8'b0100_0010;
                        3'd3: HEX_COLUMN = 8'b1111_1110;
                        3'd4: HEX_COLUMN = 8'b1111_1110;
                        3'd5: HEX_COLUMN = 8'b0000_0010;
                        3'd6: HEX_COLUMN = 8'b0000_0010;
                        3'd7: HEX_COLUMN = 8'b0000_0000;
                        default: HEX_COLUMN = 8'h00;
                    endcase
                end

                4'h2: begin
                    case (COL)
                        3'd0: HEX_COLUMN = 8'b0000_0000;
                        3'd1: HEX_COLUMN = 8'b0100_0110;
                        3'd2: HEX_COLUMN = 8'b1100_1110;
                        3'd3: HEX_COLUMN = 8'b1000_1010;
                        3'd4: HEX_COLUMN = 8'b1001_0010;
                        3'd5: HEX_COLUMN = 8'b1111_0010;
                        3'd6: HEX_COLUMN = 8'b0110_0010;
                        3'd7: HEX_COLUMN = 8'b0000_0000;
                        default: HEX_COLUMN = 8'h00;
                    endcase
                end

                4'h3: begin
                    case (COL)
                        3'd0: HEX_COLUMN = 8'b0000_0000;
                        3'd1: HEX_COLUMN = 8'b0100_0100;
                        3'd2: HEX_COLUMN = 8'b1100_0110;
                        3'd3: HEX_COLUMN = 8'b1001_0010;
                        3'd4: HEX_COLUMN = 8'b1001_0010;
                        3'd5: HEX_COLUMN = 8'b1111_1110;
                        3'd6: HEX_COLUMN = 8'b0110_1100;
                        3'd7: HEX_COLUMN = 8'b0000_0000;
                        default: HEX_COLUMN = 8'h00;
                    endcase
                end

                4'h4: begin
                    case (COL)
                        3'd0: HEX_COLUMN = 8'b0000_0000;
                        3'd1: HEX_COLUMN = 8'b0001_1000;
                        3'd2: HEX_COLUMN = 8'b0010_1000;
                        3'd3: HEX_COLUMN = 8'b0100_1010;
                        3'd4: HEX_COLUMN = 8'b1111_1110;
                        3'd5: HEX_COLUMN = 8'b1111_1110;
                        3'd6: HEX_COLUMN = 8'b0000_1010;
                        3'd7: HEX_COLUMN = 8'b0000_0000;
                        default: HEX_COLUMN = 8'h00;
                    endcase
                end

                4'h5: begin
                    case (COL)
                        3'd0: HEX_COLUMN = 8'b0000_0000;
                        3'd1: HEX_COLUMN = 8'b1110_0100;
                        3'd2: HEX_COLUMN = 8'b1110_0110;
                        3'd3: HEX_COLUMN = 8'b1010_0010;
                        3'd4: HEX_COLUMN = 8'b1010_0010;
                        3'd5: HEX_COLUMN = 8'b1011_1110;
                        3'd6: HEX_COLUMN = 8'b1001_1100;
                        3'd7: HEX_COLUMN = 8'b0000_0000;
                        default: HEX_COLUMN = 8'h00;
                    endcase
                end

                4'h6: begin
                    case (COL)
                        3'd0: HEX_COLUMN = 8'b0000_0000;
                        3'd1: HEX_COLUMN = 8'b0111_1100;
                        3'd2: HEX_COLUMN = 8'b1111_1110;
                        3'd3: HEX_COLUMN = 8'b1001_0010;
                        3'd4: HEX_COLUMN = 8'b1001_0010;
                        3'd5: HEX_COLUMN = 8'b1101_1110;
                        3'd6: HEX_COLUMN = 8'b0100_1100;
                        3'd7: HEX_COLUMN = 8'b0000_0000;
                        default: HEX_COLUMN = 8'h00;
                    endcase
                end

                4'h7: begin
                    case (COL)
                        3'd0: HEX_COLUMN = 8'b0000_0000;
                        3'd1: HEX_COLUMN = 8'b1100_0000;
                        3'd2: HEX_COLUMN = 8'b1100_0000;
                        3'd3: HEX_COLUMN = 8'b1000_1110;
                        3'd4: HEX_COLUMN = 8'b1001_1110;
                        3'd5: HEX_COLUMN = 8'b1111_0000;
                        3'd6: HEX_COLUMN = 8'b1110_0000;
                        3'd7: HEX_COLUMN = 8'b0000_0000;
                        default: HEX_COLUMN = 8'h00;
                    endcase
                end

                4'h8: begin
                    case (COL)
                        3'd0: HEX_COLUMN = 8'b0000_0000;
                        3'd1: HEX_COLUMN = 8'b0110_1100;
                        3'd2: HEX_COLUMN = 8'b1111_1110;
                        3'd3: HEX_COLUMN = 8'b1001_0010;
                        3'd4: HEX_COLUMN = 8'b1001_0010;
                        3'd5: HEX_COLUMN = 8'b1111_1110;
                        3'd6: HEX_COLUMN = 8'b0110_1100;
                        3'd7: HEX_COLUMN = 8'b0000_0000;
                        default: HEX_COLUMN = 8'h00;
                    endcase
                end

                4'h9: begin
                    case (COL)
                        3'd0: HEX_COLUMN = 8'b0000_0000;
                        3'd1: HEX_COLUMN = 8'b0110_0100;
                        3'd2: HEX_COLUMN = 8'b1111_0110;
                        3'd3: HEX_COLUMN = 8'b1001_0010;
                        3'd4: HEX_COLUMN = 8'b1001_0010;
                        3'd5: HEX_COLUMN = 8'b1111_1110;
                        3'd6: HEX_COLUMN = 8'b0111_1100;
                        3'd7: HEX_COLUMN = 8'b0000_0000;
                        default: HEX_COLUMN = 8'h00;
                    endcase
                end

                4'hA: begin
                    case (COL)
                        3'd0: HEX_COLUMN = 8'b0000_0000;
                        3'd1: HEX_COLUMN = 8'b0011_1110;
                        3'd2: HEX_COLUMN = 8'b0111_1110;
                        3'd3: HEX_COLUMN = 8'b1100_1000;
                        3'd4: HEX_COLUMN = 8'b1100_1000;
                        3'd5: HEX_COLUMN = 8'b0111_1110;
                        3'd6: HEX_COLUMN = 8'b0011_1110;
                        3'd7: HEX_COLUMN = 8'b0000_0000;
                        default: HEX_COLUMN = 8'h00;
                    endcase
                end

                4'hB: begin
                    case (COL)
                        3'd0: HEX_COLUMN = 8'b0000_0000;
                        3'd1: HEX_COLUMN = 8'b1111_1110;
                        3'd2: HEX_COLUMN = 8'b1111_1110;
                        3'd3: HEX_COLUMN = 8'b1001_0010;
                        3'd4: HEX_COLUMN = 8'b1001_0010;
                        3'd5: HEX_COLUMN = 8'b1111_1110;
                        3'd6: HEX_COLUMN = 8'b0110_1100;
                        3'd7: HEX_COLUMN = 8'b0000_0000;
                        default: HEX_COLUMN = 8'h00;
                    endcase
                end

                4'hC: begin
                    case (COL)
                        3'd0: HEX_COLUMN = 8'b0000_0000;
                        3'd1: HEX_COLUMN = 8'b0111_1100;
                        3'd2: HEX_COLUMN = 8'b1111_1110;
                        3'd3: HEX_COLUMN = 8'b1000_0010;
                        3'd4: HEX_COLUMN = 8'b1000_0010;
                        3'd5: HEX_COLUMN = 8'b1100_0110;
                        3'd6: HEX_COLUMN = 8'b0100_0100;
                        3'd7: HEX_COLUMN = 8'b0000_0000;
                        default: HEX_COLUMN = 8'h00;
                    endcase
                end

                4'hD: begin
                    case (COL)
                        3'd0: HEX_COLUMN = 8'b0000_0000;
                        3'd1: HEX_COLUMN = 8'b1111_1110;
                        3'd2: HEX_COLUMN = 8'b1111_1110;
                        3'd3: HEX_COLUMN = 8'b1000_0010;
                        3'd4: HEX_COLUMN = 8'b1100_0110;
                        3'd5: HEX_COLUMN = 8'b0111_1100;
                        3'd6: HEX_COLUMN = 8'b0011_1000;
                        3'd7: HEX_COLUMN = 8'b0000_0000;
                        default: HEX_COLUMN = 8'h00;
                    endcase
                end

                4'hE: begin
                    case (COL)
                        3'd0: HEX_COLUMN = 8'b0000_0000;
                        3'd1: HEX_COLUMN = 8'b1111_1110;
                        3'd2: HEX_COLUMN = 8'b1111_1110;
                        3'd3: HEX_COLUMN = 8'b1001_0010;
                        3'd4: HEX_COLUMN = 8'b1001_0010;
                        3'd5: HEX_COLUMN = 8'b1001_0010;
                        3'd6: HEX_COLUMN = 8'b1000_0010;
                        3'd7: HEX_COLUMN = 8'b0000_0000;
                        default: HEX_COLUMN = 8'h00;
                    endcase
                end

                4'hF: begin
                    case (COL)
                        3'd0: HEX_COLUMN = 8'b0000_0000;
                        3'd1: HEX_COLUMN = 8'b1111_1110;
                        3'd2: HEX_COLUMN = 8'b1111_1110;
                        3'd3: HEX_COLUMN = 8'b1001_0000;
                        3'd4: HEX_COLUMN = 8'b1001_0000;
                        3'd5: HEX_COLUMN = 8'b1001_0000;
                        3'd6: HEX_COLUMN = 8'b1000_0000;
                        3'd7: HEX_COLUMN = 8'b0000_0000;
                        default: HEX_COLUMN = 8'h00;
                    endcase
                end
            endcase
        end
    endfunction

endmodule
