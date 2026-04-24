`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ilyasov A.E.
// 
// Create Date: 19.04.2026 13:21:04
// Design Name: 
// Module Name: CW_DC_CMD
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Deshifrator komand
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module CW_DC_CMD
(
    output wire [ 4: 0] ADDR0,
    output wire [ 4: 0] ADDR1,
    output wire [ 4: 0] ADDR2,
    
    input  wire [ 7: 0] DATA0,
    input  wire [ 7: 0] DATA1,
    
    output wire [ 7: 0] DATA2,
    output reg          RG_WE,
    
    input  wire [15: 0] X,   
    output wire [15: 0] X_D,
    output reg          X_WE,
    
    input  wire [15: 0] Y,
    output wire [15: 0] Y_D,
    output reg          Y_WE,
   
    input  wire [15: 0] SP,
    output reg  [15: 0] SP_D,
    output reg          SP_WE,
    
    output reg  [ 3: 0] ALU_INST,
    
    output reg  [ 7: 0] OPR0,
    output reg  [ 7: 0] OPR1,
    
    output wire [ 2: 0] BT_NUM,
    
    input  wire [ 7: 0] ALU_RES,
    input  wire [ 1: 0] ALU_SREG,
    input  wire         JMP,
    
    input  wire [ 2: 0] SREG,
    output reg  [ 1: 0] SREG_D,
    output reg          SREG_WE,
    
    output reg          EIRQ_SET,
    output reg          EIRQ_RESET,
    
    input  wire [15: 0] PC, 
    output reg  [15: 0] PCD, 
    output reg          PC_LD, 
    output wire         PC_INC, 
    
    output wire [17: 2] PGMA,
    
    input  wire [31: 0] CMD,
    input  wire [ 3: 0] STAGES,
    
    output reg          MEM,
    input  wire         DONE,    
    
    input  wire [ 7: 0] MEMRD,
    output reg  [15: 0] MEMA,
    
    output reg  [ 2: 0] MEMCMD,                         
    output reg  [ 7: 0] MEMWR,
    
    input  wire         IRQ_FLG,
    output wire         EIRQ,
    
    input  wire [15: 0] IADDR,
    input  wire         IRQ
);

    // ¬ариант  удр€шова
    localparam [3:0] OP_ADD  = 4'b0001;
    localparam [3:0] OP_SUB  = 4'b1110;
    localparam [3:0] OP_OR   = 4'b1100;
    localparam [3:0] OP_AND  = 4'b0100;
    localparam [3:0] OP_INC  = 4'b0111;
    localparam [3:0] OP_DEC  = 4'b1111;
    localparam [3:0] OP_LSR  = 4'b0101;
    localparam [3:0] OP_RSR  = 4'b0010;
    localparam [3:0] OP_JMP  = 4'b1011;
    localparam [3:0] OP_JMPS = 4'b1010;
    localparam [3:0] OP_MOV  = 4'b1001; // LDL / MOV
    localparam [3:0] OP_LD   = 4'b1000;
    localparam [3:0] OP_STL  = 4'b0011;
    localparam [3:0] OP_ST   = 4'b1101;
    localparam [3:0] OP_NOP  = 4'b0000;
    localparam [3:0] OP_RETI = 4'b0110;

    assign ADDR0 = CMD[23:19];
    assign ADDR1 = CMD[15:11];
    assign ADDR2 = CMD[23:19];

    assign DATA2 = ALU_RES;

    assign X_D = X + 1'b1;
    assign Y_D = Y + 1'b1;

    wire [3:0] command = CMD[31:28];
    wire [3:0] mode    = CMD[27:24];
    
    // ---------------- RG_WE ----------------
    always @(*) begin
        RG_WE = 1'b0;

        case (command)
            OP_ADD,
            OP_SUB,
            OP_OR,
            OP_AND,
            OP_INC,
            OP_DEC,
            OP_LSR,
            OP_RSR,
            OP_MOV:
                RG_WE = (STAGES == 4'b0001);
            OP_LD:
                RG_WE = (STAGES == 4'b0010);
            default:
                RG_WE = 1'b0;
        endcase
    end

     // --------------- SP_D ----------------
    always @(*) 
    begin
        if ((STAGES == 4'b0001 && IRQ && EIRQ) ||
            (STAGES == 4'b0010 && IRQ_FLG) ||
            (STAGES == 4'b0100 && IRQ_FLG))
            SP_D = SP + 1'b1;
        else
            SP_D = SP - 1'b1;
    end
    
    // ---------------- X_WE ----------------
    always @(*) begin
        X_WE = 1'b0;

        case (command)
            OP_LD, OP_STL, OP_ST:
                if ((mode[3:2] == 2'b01) && (STAGES == 4'b0001)) 
                    X_WE = 1'b1;
                else                                              
                    X_WE = 1'b0;
            default:
                X_WE = 1'b0;
        endcase
    end
    
    // ---------------- Y_WE ----------------
    always @(*) begin
        Y_WE = 1'b0;

        case (command)
            OP_LD, OP_STL, OP_ST:
                if ((mode[3:2] == 2'b11) && (STAGES == 4'b0001)) Y_WE = 1'b1;
                else                                              Y_WE = 1'b0;
            default:
                Y_WE = 1'b0;
        endcase
    end
    
    // ---------------- SP_WE ----------------
    always @(*) 
    begin
        SP_WE =
            // IRQ & EIRQ
            ((STAGES == 4'b0001) && (IRQ && EIRQ)) ||
    
            // IRQ_FLG = 1
            ((STAGES == 4'b0010) && IRQ_FLG) ||
            ((STAGES == 4'b0100) && IRQ_FLG) ||
    
            // RETI
            ((STAGES == 4'b0001) && !(IRQ && EIRQ) && (command == OP_RETI)) ||
            ((STAGES == 4'b0010) && !IRQ_FLG && (command == OP_RETI));
    end

    // ---------------- ALU_INST ----------------
    always @(*) begin
        case (command)
        
            OP_INC,
            OP_ADD : ALU_INST = 4'b0001;
            OP_SUB,
            OP_DEC : ALU_INST = 4'b0010;
            OP_AND : ALU_INST = 4'b0011;
            OP_OR  : ALU_INST = 4'b0100;
            OP_LSR : ALU_INST = 4'b0101;
            OP_RSR : ALU_INST = 4'b0110;
            
            OP_JMPS: ALU_INST = (mode[0]) ?  4'b0111 : 4'b1000;
            
            default: ALU_INST = 4'b0000;
        endcase
    end

    // ---------------- OPR0 ----------------
    always @(*) 
    begin
        case (command)
            OP_MOV: begin
                if (mode[3] == 1'b0)
                    OPR0 = CMD[7:0];   // LDL Rd, lit
                else
                    OPR0 = DATA1;      // MOV Rd, Rr
            end
    
            OP_LD:
                OPR0 = MEMRD;          // LD Rd, X / X+ / Y / Y+
    
            default:
                OPR0 = DATA0;
        endcase
    end
    
    // ---------------- OPR1 ----------------
    always @(*) 
    begin
        case (command)
            OP_ADD,
            OP_SUB,
            OP_OR,
            OP_AND: begin
                if (mode[3] == 1'b1)
                    OPR1 = CMD[7:0];   // Rd, lit
                else
                    OPR1 = DATA1;      // Rd, Rr
            end
    
            OP_INC,
            OP_DEC:
                OPR1 = 8'h01;
    
            default:
                OPR1 = DATA1;
        endcase
    end

    // ---------------- BT_NUM ----------------
    assign BT_NUM = CMD[27:25];

    // ---------------- SREG_WE ----------------
    always @(*) begin
        SREG_WE = 1'b0;
    
        case (command)
            OP_ADD,
            OP_SUB,
            OP_OR,
            OP_AND,
            OP_INC,
            OP_DEC,
            OP_LSR,
            OP_RSR:
                SREG_WE = (STAGES == 4'b0001);
            OP_RETI:
                SREG_WE = (STAGES == 4'b0010) && !IRQ_FLG;
    
            default:
                SREG_WE = 1'b0;
        endcase
    end
    // ---------------- SREG_D ----------------
    always @(*) begin
        if ((STAGES == 4'b0010) && !IRQ_FLG && (command == OP_RETI))
            SREG_D = MEMRD[1:0];
        else
            SREG_D = ALU_SREG;
    end

    // ---------------- EIRQ_SET ----------------
    always @(*) 
    begin
        EIRQ_SET = 
            (STAGES == 4'b1000) && 
            !IRQ_FLG            && 
            (command == OP_RETI);
    end
    
    // ---------------- EIRQ_RESET ----------------
    always @(*) 
    begin
        EIRQ_RESET = (STAGES == 4'b1000) && IRQ_FLG;
    end
    
    // ---------------- PCD ----------------
    always @(*) 
    begin
        if ((STAGES == 4'b0100) &&
            !IRQ_FLG &&
            (command == OP_RETI))
            PCD = {MEMRD[7:0], PC[7:0]};
    
        else if ((STAGES == 4'b1000) &&
                 !IRQ_FLG &&
                 (command == OP_RETI))
            PCD = {PC[15:8], MEMRD[7:0]};
    
        else if ((STAGES == 4'b1000) && IRQ_FLG)
            PCD = IADDR[15:0];
    
        else if ((STAGES == 4'b0001) &&
                 !IRQ_FLG &&
                 (command == OP_JMP))
            PCD = CMD[15:0];
            
        else if (
                (STAGES == 4'b0001) && !IRQ_FLG &&
                (command == OP_JMPS) && JMP
            )
            PCD = PC + CMD[15:0] + 1'b1;
    
        else
            PCD = 16'h0000;
    end

    // ---------------- PC_LD ----------------
    always @(*) 
    begin
        PC_LD = 
            ((command == OP_RETI) && !IRQ_FLG && 
                ((STAGES == 4'b0100) || (STAGES == 4'b1000))) ||
    
            ((STAGES == 4'b1000) && IRQ_FLG) ||
    
            ((STAGES == 4'b0001) && !IRQ_FLG && 
                ((command == OP_JMP) || ((command == OP_JMPS) && JMP)));
    end

    // ---------------- PC_INC ----------------
    assign PC_INC = DONE && !(command == 4'b0000); // OP_NOP

    // ---------------- MEMA ----------------
    always @(*) 
    begin
        if ((STAGES == 4'b0001) && !(IRQ && EIRQ) &&
            ((command == OP_LD) || (command == OP_STL) || (command == OP_ST)))
            MEMA = mode[3] ? Y : X;
    
        else if (
            (command == OP_RETI) &&
            ((STAGES == 4'b0010) || (STAGES == 4'b0100) ||
            ((STAGES == 4'b0001) && !(IRQ && EIRQ)))
        )
            MEMA = SP - 1'b1;
    
        else
            MEMA = SP;
    end
    
    // ---------------- MEMCMD ----------------
    always @(*) 
    begin
        if (
            ((STAGES == 4'b0001) && !(IRQ && EIRQ) &&
                ((command == OP_RETI) || (command == OP_LD))) ||
    
            (((STAGES == 4'b0010) || (STAGES == 4'b0100)) &&
                !IRQ_FLG && (command == OP_RETI))
        )
            MEMCMD = 3'b101;
        else
            MEMCMD = 3'b001;
    end

    // ---------------- MEMWR ----------------
    always @(*) 
    begin
        if ((STAGES == 4'b0001) && (IRQ && EIRQ))
            MEMWR = PC[7:0];
    
        else if ((STAGES == 4'b0010) && (IRQ_FLG))
            MEMWR = PC[15:8];
    
        else if ((STAGES == 4'b0100) && (IRQ_FLG))
            MEMWR = {6'h00, SREG[1:0]};
    
        else if ((STAGES == 4'b0001) && !(IRQ && EIRQ) &&
            (command == OP_STL))
            MEMWR = CMD[7:0];
    
        else
            MEMWR = DATA1;
    end

    // ---------------- MEM ----------------
    always @(*) 
    begin
        MEM =
            ((STAGES == 4'b0001) && (IRQ && EIRQ)) ||
    
            ((STAGES == 4'b0010) && IRQ_FLG) ||
            ((STAGES == 4'b0100) && IRQ_FLG) ||
    
            ((command == OP_RETI) &&
                (((STAGES == 4'b0001) && !(IRQ && EIRQ)) ||
                 ((STAGES == 4'b0010) && !IRQ_FLG) ||
                 ((STAGES == 4'b0100) && !IRQ_FLG))) ||
    
            ((STAGES == 4'b0001) && !(IRQ && EIRQ) &&
                ((command == OP_LD) || (command == OP_STL) || (command == OP_ST)));
    end

    // ---------------- PGMA ----------------
    assign PGMA = PC;
    
    // ---------------- EIRQ ----------------
    assign EIRQ = SREG[2];

endmodule