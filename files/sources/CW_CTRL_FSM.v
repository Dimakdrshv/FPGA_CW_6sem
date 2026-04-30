`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: Sorochinskii N.A.
//
// Create Date: 29.04.2026 13:28:03
// Design Name:
// Module Name: CW_CTRL_FSM
// Project Name:
// Target Devices:
// Tool Versions:
// Description: Control finite state machine
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module CW_CTRL_FSM (
    input  wire        CLK,
    input  wire        RST,

    output wire [ 3:0] STAGES,
    input  wire [17:2] PGMA,
    output reg  [31:0] CMD,
    input  wire        MEM,
    output wire        DONE,
    output wire [ 7:0] MEMRD,
    input  wire [15:0] MEMA,
    input  wire [ 2:0] MEMCMD,
    input  wire [ 7:0] MEMWR,
    output reg         IRQ_FLG,
    input  wire        EIRQ,
    input  wire        IRQ,

    output reg         PGM_S_EX_REQ,
    output reg  [17:2] PGM_S_ADDR,
    output reg  [3:0] PGM_S_NBE,
    output reg  [ 2:0] PGM_S_CMD,
    output reg  [31:0] PGM_S_D_WR,
    input  wire        PGM_S_EX_ACK,
    input  wire [31:0] PGM_S_D_RD,

    output reg         DM_S_EX_REQ,
    output reg  [15:0] DM_S_ADDR,
    output reg  [ 2:0] DM_S_CMD,
    output reg  [ 7:0] DM_S_D_WR,
    input  wire        DM_S_EX_ACK,
    input  wire [ 7:0] DM_S_D_RD
);

    initial begin
        FSM_STATE = PGMI;
        I_STAGES = 4'b0001;
    end

    localparam [1:0] PGMI = 2'b00,
                     PGMW = 2'b01,
                     WAIT = 2'b10,
                     ASP  = 2'b11;

    reg [1:0] FSM_STATE;
    reg [3:0] I_STAGES;

    assign STAGES[3:0] = ((FSM_STATE[1:0] == WAIT) | ((FSM_STATE[2:0] == ASP) 
                        & DM_S_EX_ACK)) & I_STAGES[3:0];
    assign DONE        = ((FSM_STATE[1:0] == WAIT) | ((FSM_STATE[1:0] == ASP) 
                        & DM_S_EX_ACK)) & ~MEM;
    assign MEMRD       = DM_S_D_RD;

    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            I_STAGES     <= 4'b0001;
            CMD          <= 32'h00000000;
            IRQ_FLG      <= 1'b0;

            PGM_S_EX_REQ <= 1'b0;
            PGM_S_ADDR   <= 16'h0000;
            PGM_S_NBE    <= 4'b0000;
            PGM_S_CMD    <= 3'b110;
            PGM_S_D_WR   <= 32'h00000000;

            DM_S_EX_REQ  <= 1'b0;
            DM_S_ADDR    <= 16'h0000;
            DM_S_CMD     <= 3'b000;
            DM_S_D_WR    <= 8'h00;
            FSM_STATE    <= PGMI;
        end else begin
            case (FSM_STATE)
                PGMI: begin
                    PGM_S_EX_REQ <= 1'b1;
                    PGM_S_ADDR   <= PGMA;
                    FSM_STATE <= PGMW
                end

                PGMW: begin
                    if (PGM_S_EX_ACK) begin
                        PGM_S_EX_REQ <= 1'b0;
                        CMD          <= PGM_S_D_RD;
                        FSM_STATE    <= WAIT;
                    end
                end

                WAIT: begin
                    if (MEM) begin
                        DM_S_EX_REQ <= 1'b1;
                        DM_S_ADDR   <= MEMA;
                        DM_S_CMD    <= MEMCMD;
                        DM_S_D_WR   <= MEMWR;
                        I_STAGES    <= {I_STAGES[2:0], 1'b0};
                        IRQ_FLG     <= EIRQ & IRQ;
                        FSM_STATE   <= ASP;
                    end else begin
                        FSM_STATE   <= PGMI;
                    end
                end

                ASP: begin
                    if (DM_S_EX_ACK) begin
                        DM_S_ADDR   <= MEMA;
                        DM_S_CMD    <= MEMCMD;
                        DM_S_D_WR   <= MEMWR;
                        if (MEM) begin
                            I_STAGES    <= {I_STAGES[2:0], 1'b0};
                        end else begin
                            DM_S_EX_REQ <= 1'b0;
                            I_STAGES    <= 4'b0001;
                            IRQ_FLG     <= 1'b0;
                            FSM_STATE   <= PGMI;
                        end
                    end
                end
            endcase
        end
    end

endmodule
