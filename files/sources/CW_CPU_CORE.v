`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ilyasov A.E.
// 
// Create Date: 01.05.2026 21:50:34
// Design Name: 
// Module Name: CW_CPU_CORE
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: CPU
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CW_CPU_CORE_V10 
(
    // System signals
    input  wire        CLK,
    input  wire        RST,

    // STI 1.0 program memory port, 32-bit data bus
    output wire        PGM_S_EX_REQ,
    output wire [17:2] PGM_S_ADDR,
    output wire [ 3:0] PGM_S_NBE,
    output wire [ 2:0] PGM_S_CMD,
    output wire [31:0] PGM_S_D_WR,
    input  wire        PGM_S_EX_ACK,
    input  wire [31:0] PGM_S_D_RD,

    // STI 1.0 data memory port, 8-bit data bus
    output wire        DM_S_EX_REQ,
    output wire [15:0] DM_S_ADDR,
    output wire [ 2:0] DM_S_CMD,
    output wire [ 7:0] DM_S_D_WR,
    input  wire        DM_S_EX_ACK,
    input  wire [ 7:0] DM_S_D_RD,

    // STI 1.0 processor debug/control port, 8-bit data bus
    input  wire        PROC_S_EX_REQ,
    input  wire [ 5:0] PROC_S_ADDR,
    input  wire [ 2:0] PROC_S_CMD,
    input  wire [ 7:0] PROC_S_D_WR,
    output wire        PROC_S_EX_ACK,
    output wire [ 7:0] PROC_S_D_RD,

    // Interrupt interface
    input  wire [15:0] IADDR,
    input  wire        IRQ
);

    //--------------------------------------------------------------------------
    // Internal STI 1.0 processor bus routing
    //--------------------------------------------------------------------------
    wire        rf_s_ex_req;
    wire [4:0]  rf_s_addr;
    wire [2:0]  rf_s_cmd;
    wire [7:0]  rf_s_d_wr;
    wire        rf_s_ex_ack;
    wire [7:0]  rf_s_d_rd;

    wire        sreg_s_ex_req;
    wire        sreg_s_addr;
    wire [2:0]  sreg_s_cmd;
    wire [7:0]  sreg_s_d_wr;
    wire        sreg_s_ex_ack;
    wire [7:0]  sreg_s_d_rd;

    wire        pc_s_ex_req;
    wire        pc_s_addr;
    wire [2:0]  pc_s_cmd;
    wire [7:0]  pc_s_d_wr;
    wire        pc_s_ex_ack;
    wire [7:0]  pc_s_d_rd;

    CW_CPU_INFS8B u_cpu_infs8b (
        .T_S_EX_REQ   (PROC_S_EX_REQ),
        .T_S_ADDR     (PROC_S_ADDR),
        .T_S_CMD      (PROC_S_CMD),
        .T_S_D_WR     (PROC_S_D_WR),

        .I1_S_EX_ACK  (rf_s_ex_ack),
        .I1_S_D_RD    (rf_s_d_rd),
        .I2_S_EX_ACK  (sreg_s_ex_ack),
        .I2_S_D_RD    (sreg_s_d_rd),
        .I3_S_EX_ACK  (pc_s_ex_ack),
        .I3_S_D_RD    (pc_s_d_rd),

        .T_S_EX_ACK   (PROC_S_EX_ACK),
        .T_S_D_RD     (PROC_S_D_RD),

        .I1_S_EX_REQ  (rf_s_ex_req),
        .I1_S_ADDR    (rf_s_addr),
        .I1_S_CMD     (rf_s_cmd),
        .I1_S_D_WR    (rf_s_d_wr),

        .I2_S_EX_REQ  (sreg_s_ex_req),
        .I2_S_ADDR    (sreg_s_addr),
        .I2_S_CMD     (sreg_s_cmd),
        .I2_S_D_WR    (sreg_s_d_wr),

        .I3_S_EX_REQ  (pc_s_ex_req),
        .I3_S_ADDR    (pc_s_addr),
        .I3_S_CMD     (pc_s_cmd),
        .I3_S_D_WR    (pc_s_d_wr)
    );

    //--------------------------------------------------------------------------
    // Datapath wires
    //--------------------------------------------------------------------------
    wire [4:0]  addr0;
    wire [4:0]  addr1;
    wire [4:0]  addr2;
    wire [7:0]  data0;
    wire [7:0]  data1;
    wire [7:0]  data2;
    wire        rg_we;

    wire [15:0] x;
    wire [15:0] x_d;
    wire        x_we;
    wire [15:0] y;
    wire [15:0] y_d;
    wire        y_we;
    wire [15:0] sp;
    wire [15:0] sp_d;
    wire        sp_we;

    wire [3:0]  alu_inst;
    wire [7:0]  opr0;
    wire [7:0]  opr1;
    wire [2:0]  bt_num;
    wire [7:0]  alu_res;
    wire        jmp;
    wire [1:0]  alu_sreg;

    wire [2:0]  sreg;
    wire [1:0]  sreg_d;
    wire        sreg_we;
    wire        eirq_set;
    wire        eirq_reset;

    wire [15:0] pc;
    wire [15:0] pcd;
    wire        pc_ld;
    wire        pc_inc;

    wire [3:0]  stages;
    wire [17:2] pgma;
    wire [31:0] cmd;
    wire        mem;
    wire        done;
    wire [7:0]  memrd;
    wire [15:0] mema;
    wire [2:0]  memcmd;
    wire [7:0]  memwr;
    wire        irq_flg;
    wire        eirq;

    //--------------------------------------------------------------------------
    // Register file
    //--------------------------------------------------------------------------
    CW_REGFILE u_regfile (
        .CLK        (CLK),
        .RST        (RST),
        .S_EX_REQ   (rf_s_ex_req),
        .S_ADDR     (rf_s_addr),
        .S_CMD      (rf_s_cmd),
        .S_D_WR     (rf_s_d_wr),
        .S_EX_ACK   (rf_s_ex_ack),
        .S_D_RD     (rf_s_d_rd),

        .ADDR0      (addr0),
        .ADDR1      (addr1),
        .ADDR2      (addr2),
        .DATA0      (data0),
        .DATA1      (data1),
        .DATA2      (data2),
        .RG_WE      (rg_we),

        .X          (x),
        .X_D        (x_d),
        .X_WE       (x_we),
        .Y          (y),
        .Y_D        (y_d),
        .Y_WE       (y_we),
        .SP         (sp),
        .SP_D       (sp_d),
        .SP_WE      (sp_we)
    );

    //--------------------------------------------------------------------------
    // ALU
    //--------------------------------------------------------------------------
    CW_ALU u_alu (
        .ALU_INST   (alu_inst),
        .OPR0       (opr0),
        .OPR1       (opr1),
        .BT_NUM     (bt_num),
        .SREG       (sreg[1:0]),
        .ALU_RES    (alu_res),
        .JMP        (jmp),
        .ALU_SREG   (alu_sreg)
    );

    //--------------------------------------------------------------------------
    // Status register
    //--------------------------------------------------------------------------
    CW_SREG u_sreg (
        .CLK        (CLK),
        .RST        (RST),
        .S_EX_REQ   (sreg_s_ex_req),
        .S_CMD      (sreg_s_cmd),
        .S_D_WR     (sreg_s_d_wr),
        .SREG_WE    (sreg_we),
        .EIRQ_SET   (eirq_set),
        .EIRQ_RESET (eirq_reset),
        .SREG_D     (sreg_d),
        .S_ADDR     (sreg_s_addr),
        .S_EX_ACK   (sreg_s_ex_ack),
        .S_D_RD     (sreg_s_d_rd),
        .SREG       (sreg)
    );

    //--------------------------------------------------------------------------
    // Program counter
    //--------------------------------------------------------------------------
    CW_PC u_pc (
        .CLK        (CLK),
        .RST        (RST),
        .S_EX_REQ   (pc_s_ex_req),
        .S_ADDR     (pc_s_addr),
        .S_CMD      (pc_s_cmd),
        .S_D_WR     (pc_s_d_wr),
        .S_EX_ACK   (pc_s_ex_ack),
        .S_D_RD     (pc_s_d_rd),
        .PC         (pc),
        .PCD        (pcd),
        .PC_LD      (pc_ld),
        .PC_INC     (pc_inc)
    );

    //--------------------------------------------------------------------------
    // Instruction decoder / control datapath
    //--------------------------------------------------------------------------
    CW_DC_CMD u_dc_cmd (
        .ADDR0      (addr0),
        .ADDR1      (addr1),
        .ADDR2      (addr2),
        .DATA0      (data0),
        .DATA1      (data1),
        .DATA2      (data2),
        .RG_WE      (rg_we),

        .X          (x),
        .X_D        (x_d),
        .X_WE       (x_we),
        .Y          (y),
        .Y_D        (y_d),
        .Y_WE       (y_we),
        .SP         (sp),
        .SP_D       (sp_d),
        .SP_WE      (sp_we),

        .ALU_INST   (alu_inst),
        .OPR0       (opr0),
        .OPR1       (opr1),
        .BT_NUM     (bt_num),
        .ALU_RES    (alu_res),
        .ALU_SREG   (alu_sreg),
        .JMP        (jmp),

        .SREG       (sreg),
        .SREG_D     (sreg_d),
        .SREG_WE    (sreg_we),
        .EIRQ_SET   (eirq_set),
        .EIRQ_RESET (eirq_reset),

        .PC         (pc),
        .PCD        (pcd),
        .PC_LD      (pc_ld),
        .PC_INC     (pc_inc),
        .PGMA       (pgma),

        .CMD        (cmd),
        .STAGES     (stages),
        .MEM        (mem),
        .DONE       (done),
        .MEMRD      (memrd),
        .MEMA       (mema),
        .MEMCMD     (memcmd),
        .MEMWR      (memwr),

        .IRQ_FLG    (irq_flg),
        .EIRQ       (eirq),
        .IADDR      (IADDR),
        .IRQ        (IRQ)
    );

    //--------------------------------------------------------------------------
    // Control FSM: instruction fetch and data-memory transactions
    //--------------------------------------------------------------------------
    CW_CTRL_FSM u_ctrl_fsm (
        .CLK          (CLK),
        .RST          (RST),
        .STAGES       (stages),
        .PGMA         (pgma),
        .CMD          (cmd),
        .MEM          (mem),
        .DONE         (done),
        .MEMRD        (memrd),
        .MEMA         (mema),
        .MEMCMD       (memcmd),
        .MEMWR        (memwr),
        .IRQ_FLG      (irq_flg),
        .EIRQ         (eirq),
        .IRQ          (IRQ),

        .PGM_S_EX_REQ (PGM_S_EX_REQ),
        .PGM_S_ADDR   (PGM_S_ADDR),
        .PGM_S_NBE    (PGM_S_NBE),
        .PGM_S_CMD    (PGM_S_CMD),
        .PGM_S_D_WR   (PGM_S_D_WR),
        .PGM_S_EX_ACK (PGM_S_EX_ACK),
        .PGM_S_D_RD   (PGM_S_D_RD),

        .DM_S_EX_REQ  (DM_S_EX_REQ),
        .DM_S_ADDR    (DM_S_ADDR),
        .DM_S_CMD     (DM_S_CMD),
        .DM_S_D_WR    (DM_S_D_WR),
        .DM_S_EX_ACK  (DM_S_EX_ACK),
        .DM_S_D_RD    (DM_S_D_RD)
    );

endmodule

