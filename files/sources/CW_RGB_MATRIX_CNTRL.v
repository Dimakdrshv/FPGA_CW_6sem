`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Kudryashov D.S.
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


module CW_RGB_MATRIX_CNTRL
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

    // --------------------> initial
    wire CE_DATA_HEX;
    wire CE_PWM_R;
    wire CE_PWM_G;
    wire CE_PWM_B;
    
    reg [3:0] DATA_HEX;
    reg [7:0] PWM_R;
    reg [7:0] PWM_G;
    reg [7:0] PWM_B;
    
    reg [7:0] CNT_24X;
    wire CE_24X;
    reg [1:0] CT_MOD3;
    wire CE_8X;
    reg [2:0] CT_MATRIX;
    
    reg [3:0] DATA;
    
    wire PWM_P_R;
    wire PWM_P_G;
    wire PWM_P_B;
    
    reg [7:0] DC;
    
    wire [7:0] CL_R;
    wire [7:0] CL_G;
    wire [7:0] CL_B;
    
    wire [7:0] ROW_DATA;
    
    initial begin
        COL_R = 8'h00;
        COL_G = 8'h00;
        COL_B = 8'h00;
        ROW   = 8'h00;
        
        DATA_HEX = 4'h0;
        PWM_R    = 8'h00;
        PWM_G    = 8'h00;
        PWM_B    = 8'h00;
        
        CNT_24X   = 8'h00;
        CT_MOD3   = 2'b00;
        CT_MATRIX = 3'b000;
        
        DATA = 4'h0;
    end
    
    // --------------------> combinational logic
    // DC_CE
    assign CE_DATA_HEX = (S_EX_REQ && (S_CMD == 3'b001) && (S_ADDR == 2'b00)) ? 1'b1 : 1'b0;
    assign CE_PWM_R    = (S_EX_REQ && (S_CMD == 3'b001) && (S_ADDR == 2'b01)) ? 1'b1 : 1'b0;
    assign CE_PWM_G    = (S_EX_REQ && (S_CMD == 3'b001) && (S_ADDR == 2'b10)) ? 1'b1 : 1'b0;
    assign CE_PWM_B    = (S_EX_REQ && (S_CMD == 3'b001) && (S_ADDR == 2'b11)) ? 1'b1 : 1'b0;
    
    // STI 1.0
    assign S_EX_ACK = 1'b1;
    
    always @* begin
        if (S_EX_REQ && S_CMD == 3'b101) begin
            case (S_ADDR)
                2'b00:   S_D_RD = {4'b0000, DATA_HEX};
                2'b01:   S_D_RD = PWM_R;
                2'b10:   S_D_RD = PWM_G;
                2'b11:   S_D_RD = PWM_B;
                default: S_D_RD = 8'h00;
            endcase
        end else begin
            S_D_RD = 8'h00;
        end
    end
    
    // CE_*X
    assign CE_24X = CNT_24X[7:1] & (~{(7){CNT_24X[0]}}) & {(7){CE_PWM}}; 
    assign CE_8X  = ~CT_MOD3[0] & CT_MOD3[1] & CE_24X;
    
    // DC 3:8
    always @* begin
        case (CT_MATRIX)
            3'b000:  DC = 8'b0000_0001;
            3'b001:  DC = 8'b0000_0010;
            3'b010:  DC = 8'b0000_0100;
            3'b011:  DC = 8'b0000_1000;
            3'b100:  DC = 8'b0001_0000;
            3'b101:  DC = 8'b0010_0000;
            3'b110:  DC = 8'b0100_0000;
            3'b111:  DC = 8'b1000_0000;
            default: DC = 8'h00;
        endcase
    end
    
    // CL
    assign CL_R = ~{(8){CT_MOD3[0]}} & ~{(8){CT_MOD3[1]}} & {(8){PWM_P_R}} & DC;
    assign CL_G = {(8){CT_MOD3[0]}} & ~{(8){CT_MOD3[1]}} & {(8){PWM_P_G}} & DC;
    assign CL_B = ~{(8){CT_MOD3[0]}} & {(8){CT_MOD3[1]}} & {(8){PWM_P_B}} & DC;
    
    // --------------------> sequantial logic
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            DATA_HEX <= 4'h0;
            PWM_R    <= 8'h00;
            PWM_G    <= 8'h00;
            PWM_B    <= 8'h00;
        end else begin
            DATA_HEX <= CE_DATA_HEX ? S_D_WR[3:0] : DATA_HEX;
            PWM_R    <= CE_PWM_R    ? S_D_WR      : PWM_R;
            PWM_G    <= CE_PWM_G    ? S_D_WR      : PWM_G;
            PWM_B    <= CE_PWM_B    ? S_D_WR      : PWM_B;
        end
    end
    
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            CNT_24X <= 8'h00;
        end else begin
            if (CE_24X) begin
                CNT_24X <= 8'h00;
            end else if (CE_PWM) begin
                CNT_24X <= CNT_24X + 1'b1;
            end
        end
    end
    
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            CT_MOD3 <= 2'b00;
        end else begin
            if (CE_24X & (CT_MOD3 == 2'b10)) begin
                CT_MOD3 <= 2'b00;
            end else if (CE_24X) begin
                CT_MOD3 <= CT_MOD3 + 1'b1;
            end
        end
    end
    
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            CT_MATRIX <= 3'b000;
        end else begin
            if (CE_8X) begin
                CT_MATRIX <= CT_MATRIX + 1'b1;
            end
        end
    end
    
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            DATA <= 4'h0;
        end else begin
            if (CE_8X & (&CT_MATRIX)) begin
                DATA <= DATA_HEX;
            end
        end
    end
    
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            COL_R <= 8'h00;
        end else begin
            COL_R <= CL_R;
        end
    end
    
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            COL_G <= 8'h00;
        end else begin
            COL_G <= CL_G;
        end
    end
    
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            COL_B <= 8'h00;
        end else begin
            COL_B <= CL_B;
        end
    end
    
    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            ROW <= 8'h00;
        end else begin
            ROW <= ROW_DATA;
        end
    end
    
    // --------------------> other units
    CW_PWM_FSM 
    #(
        .UDW(8)
    )
    pwm_r
    (
        .CLK(CLK),
        .RST(RST),
        .RE(CE_24X),
        .CE(CE_PWM),
        .PWM_IN(PWM_R),
        .PWM_P(PWM_P_R)
        //.PWM_N() unused
    );
    
    CW_PWM_FSM 
    #(
        .UDW(8)
    )
    pwm_g
    (
        .CLK(CLK),
        .RST(RST),
        .RE(CE_24X),
        .CE(CE_PWM),
        .PWM_IN(PWM_G),
        .PWM_P(PWM_P_G)
        //.PWM_N() unused
    );
    
    CW_PWM_FSM 
    #(
        .UDW(8)
    )
    pwm_b
    (
        .CLK(CLK),
        .RST(RST),
        .RE(CE_24X),
        .CE(CE_PWM),
        .PWM_IN(PWM_B),
        .PWM_P(PWM_P_B)
        //.PWM_N() unused
    );
    
    CW_SYM_CODES cw_sym_codes
    (
        .ADDR({DATA, CT_MATRIX}),
        .ROW_DATA(ROW_DATA)
    );
    
endmodule
