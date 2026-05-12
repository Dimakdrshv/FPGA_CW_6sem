`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kudryashov D.S.
// 
// Create Date: 10.05.2026 21:15:23
// Design Name: 
// Module Name: CW_TOP
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: System TOP level
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CW_TOP
(
    // System signals
    input wire CLK_48,
    input wire SYS_NRST,
    output wire N_ST,
    
    // RGB-matrix signals
    output wire [7:0] COL_R_,
    output wire [7:0] COL_G_,
    output wire [7:0] COL_B_,
    output wire [7:0] ROW,
    
    // 7-Seg signals
    output wire [7:0] AN,
    output wire [7:0] CAT,
    
    // SW signals
    input wire SW_0,
    input wire SW_1,
    input wire SW_2,
    input wire SW_3,
    input wire SW_4,
    input wire SW_5,
    input wire SW_6,
    input wire SW_7,
    input wire SW_8,
    input wire SW_9,
    input wire SW_A,
    input wire SW_B,
    input wire SW_C,
    input wire SW_D,
    input wire SW_E,
    input wire SW_F,
    
    // BTN signals
    input wire BTN_0,
    input wire BTN_1,
    input wire BTN_2,
    input wire BTN_3,
    
    // LED signals
    output wire LED_0,
    output wire LED_1,
    output wire LED_2,
    output wire LED_3,
    output wire LED_4,
    output wire LED_5,
    output wire LED_6,
    output wire LED_7,
    output wire LED_8,
    output wire LED_9,
    output wire LED_A,
    output wire LED_B,
    output wire LED_C,
    output wire LED_D,
    output wire LED_E,
    output wire LED_F
);

    //----------------> RST synchronizer
    wire RST;
    
    CW_RST_SYNC cw_rst_sync
    (
        .CLK(CLK_48),
        .SYS_NRST(SYS_NRST),
        .RST(RST)
    );
    
    //----------------> Divider cascade stage 1
    localparam CNT_WDT_DIVIDER_CASCADE_1 = 13;
    localparam     MOD_DIVIDER_CASCADE_1 = 6250;
    
    wire CE_7_68kHz;
    
    CW_DIVIDER
    #(
        .CNT_WDT(CNT_WDT_DIVIDER_CASCADE_1),
        .MOD(MOD_DIVIDER_CASCADE_1)
    )
    cw_divider
    (
        .CLK(CLK_48),
        .RST(RST),
        .CE(CE_7_68kHz)
    );
     
    //----------------> Divider cascade stage 2
    localparam CNT_WDT_DIVIDER_CASCADE_2 = 3;
    localparam     MOD_DIVIDER_CASCADE_2 = 8;
    
    wire CE_1kHz;
    
    CW_DIVIDER_CASCADE
    #(
        .CNT_WDT(CNT_WDT_DIVIDER_CASCADE_2),
        .MOD(MOD_DIVIDER_CASCADE_2)
    )
    cw_divider_cascade
    (
        .CLK(CLK_48),
        .RST(RST),
        .CE(CE_7_68kHz),
        .CEO(CE_1kHz)
    );
    
    //----------------> WatchDog RST
    CW_WATCHDOG_RST cw_watchdog_rst
    (
        .CLK(CLK_48),
        .RST(RST),
        .CE(CE_1kHz),
        .N_ST(N_ST)
    );
    
    //----------------> CPU CORE
    // STI 1.0 program memory port, 32-bit data bus
    wire        PGM_S_EX_REQ;
    wire [17:2] PGM_S_ADDR;
    wire [ 3:0] PGM_S_NBE;
    wire [ 2:0] PGM_S_CMD;
    wire [31:0] PGM_S_D_WR;
    wire        PGM_S_EX_ACK;
    wire [31:0] PGM_S_D_RD;
    
    // STI 1.0 data memory port, 8-bit data bus
    wire        DM_S_EX_REQ;
    wire [15:0] DM_S_ADDR;
    wire [ 2:0] DM_S_CMD;
    wire [ 7:0] DM_S_D_WR;
    wire        DM_S_EX_ACK;
    wire [ 7:0] DM_S_D_RD;

    // STI 1.0 processor debug/control port, 8-bit data bus
    wire        PROC_S_EX_REQ;
    wire [ 5:0] PROC_S_ADDR;
    wire [ 2:0] PROC_S_CMD;
    wire [ 7:0] PROC_S_D_WR;
    wire        PROC_S_EX_ACK;
    wire [ 7:0] PROC_S_D_RD;

    // Interrupt interface
    wire [15:0] IADDR = 16'h0000;
    wire        IRQ;
    
    CW_CPU_CORE cw_cpu_core
    (
        .CLK(CLK_48),
        .RST(RST),

        .PGM_S_EX_REQ(PGM_S_EX_REQ),
        .PGM_S_ADDR(PGM_S_ADDR),
        .PGM_S_NBE(PGM_S_NBE),
        .PGM_S_CMD(PGM_S_CMD),
        .PGM_S_D_WR(PGM_S_D_WR),
        .PGM_S_EX_ACK(PGM_S_EX_ACK),
        .PGM_S_D_RD(PGM_S_D_RD),

        .DM_S_EX_REQ(DM_S_EX_REQ),
        .DM_S_ADDR(DM_S_ADDR),
        .DM_S_CMD(DM_S_CMD),
        .DM_S_D_WR(DM_S_D_WR),
        .DM_S_EX_ACK(DM_S_EX_ACK),
        .DM_S_D_RD(DM_S_D_RD),

        .PROC_S_EX_REQ(PROC_S_EX_REQ),
        .PROC_S_ADDR(PROC_S_ADDR),
        .PROC_S_CMD(PROC_S_CMD),
        .PROC_S_D_WR(PROC_S_D_WR),
        .PROC_S_EX_ACK(PROC_S_EX_ACK),
        .PROC_S_D_RD(PROC_S_D_RD),

        .IADDR(IADDR),
        .IRQ(IRQ)
    );
    
    //----------------> Program ROM
    CW_PRG_ROM_32B cw_prg_rom_32b
    (
        .S_EX_REQ(PGM_S_EX_REQ),
        .S_ADDR(PGM_S_ADDR[11:2]),
        .S_CMD(PGM_S_CMD),
        .S_EX_ACK(PGM_S_EX_ACK),
        .S_D_RD(PGM_S_D_RD)
    );
    
    //----------------> System bus STI 1.0
    // Reg operator A
    wire [7:0] RG_A_S_D_WR;     
    wire [2:0] RG_A_S_CMD;    
    wire       RG_A_S_EX_REQ;
    wire       RG_A_S_ADDR; 
    wire [7:0] RG_A_S_D_RD;
    wire       RG_A_S_EX_ACK;
    
    // Reg operator B
    wire [7:0] RG_B_S_D_WR;     
    wire [2:0] RG_B_S_CMD;    
    wire       RG_B_S_EX_REQ;
    wire       RG_B_S_ADDR; 
    wire [7:0] RG_B_S_D_RD;
    wire       RG_B_S_EX_ACK;
    
    // RGB matrix controller
    wire       RGB_MC_S_EX_REQ;
    wire [1:0] RGB_MC_S_ADDR;
    wire [2:0] RGB_MC_S_CMD;
    wire [7:0] RGB_MC_S_D_WR;
    wire       RGB_MC_S_EX_ACK;
    wire [7:0] RGB_MC_S_D_RD;
    
    //7-SEG controller
    wire       SEG_C_S_EX_REQ;
    wire [2:0] SEG_C_S_ADDR;
    wire [2:0] SEG_C_S_CMD;
    wire [7:0] SEG_C_S_D_WR;
    wire       SEG_C_S_EX_ACK;
    wire [7:0] SEG_C_S_D_RD;
    
    // LED controller
    wire       LED_C_S_EX_REQ;
    wire       LED_C_S_ADDR;
    wire [2:0] LED_C_S_CMD;
    wire [7:0] LED_C_S_D_WR;
    wire       LED_C_S_EX_ACK;
    wire [7:0] LED_C_S_D_RD;
    
    // IRQ monitor
    wire       IRQ_M_S_EX_REQ;
    wire [2:0] IRQ_M_S_ADDR;
    wire [2:0] IRQ_M_S_CMD;
    wire [7:0] IRQ_M_S_D_WR;
    wire       IRQ_M_S_EX_ACK;
    wire [7:0] IRQ_M_S_D_RD;
    
    // RAM
    wire       RAM_S_EX_REQ;
    wire [9:0] RAM_S_ADDR;
    wire [2:0] RAM_S_CMD;
    wire [7:0] RAM_S_D_WR;
    wire       RAM_S_EX_ACK;
    wire [7:0] RAM_S_D_RD;
    
    CW_SYS_INFS8B cw_sys_infs8b
    (
        .T_S_EX_REQ(DM_S_EX_REQ),
        .T_S_ADDR(DM_S_ADDR),
        .T_S_CMD(DM_S_CMD),
        .T_S_D_WR(DM_S_D_WR),
        .T_S_EX_ACK(DM_S_EX_ACK),
        .T_S_D_RD(DM_S_D_RD),
        
        .I0_S_EX_ACK(PROC_S_EX_ACK),
        .I0_S_D_RD(PROC_S_D_RD),
        .I0_S_EX_REQ(PROC_S_EX_REQ),
        .I0_S_ADDR(PROC_S_ADDR),
        .I0_S_CMD(PROC_S_CMD),
        .I0_S_D_WR(PROC_S_D_WR),
        
        .I1_S_EX_ACK(RG_A_S_EX_ACK),
        .I1_S_D_RD(RG_A_S_D_RD),
        .I1_S_EX_REQ(RG_A_S_EX_REQ),
        .I1_S_ADDR(RG_A_S_ADDR), 
        .I1_S_CMD(RG_A_S_CMD),
        .I1_S_D_WR(RG_A_S_D_WR),
        
        .I2_S_EX_ACK(RG_B_S_EX_ACK),
        .I2_S_D_RD(RG_B_S_D_RD),
        .I2_S_EX_REQ(RG_B_S_EX_REQ),
        .I2_S_ADDR(RG_B_S_ADDR), 
        .I2_S_CMD(RG_B_S_CMD),
        .I2_S_D_WR(RG_B_S_D_WR),

        .I3_S_EX_ACK(RGB_MC_S_EX_ACK),
        .I3_S_D_RD(RGB_MC_S_D_RD),
        .I3_S_EX_REQ(RGB_MC_S_EX_REQ),
        .I3_S_ADDR(RGB_MC_S_ADDR),
        .I3_S_CMD(RGB_MC_S_CMD),
        .I3_S_D_WR(RGB_MC_S_D_WR),

        .I4_S_EX_ACK(SEG_C_S_EX_ACK),
        .I4_S_D_RD(SEG_C_S_D_RD),
        .I4_S_EX_REQ(SEG_C_S_EX_REQ),
        .I4_S_ADDR(SEG_C_S_ADDR),
        .I4_S_CMD(SEG_C_S_CMD),
        .I4_S_D_WR(SEG_C_S_D_WR),

        .I5_S_EX_ACK(LED_C_S_EX_ACK),
        .I5_S_D_RD(LED_C_S_D_RD),
        .I5_S_EX_REQ(LED_C_S_EX_REQ),
        .I5_S_ADDR(LED_C_S_ADDR),
        .I5_S_CMD(LED_C_S_CMD),
        .I5_S_D_WR(LED_C_S_D_WR),
        
        .I6_S_EX_ACK(IRQ_M_S_EX_ACK),
        .I6_S_D_RD(IRQ_M_S_D_RD),
        .I6_S_EX_REQ(IRQ_M_S_EX_REQ),
        .I6_S_ADDR(IRQ_M_S_ADDR),
        .I6_S_CMD(IRQ_M_S_CMD),
        .I6_S_D_WR(IRQ_M_S_D_WR),
        
        .I7_S_EX_ACK(RAM_S_EX_ACK),
        .I7_S_D_RD(RAM_S_D_RD),
        .I7_S_EX_REQ(RAM_S_EX_REQ),
        .I7_S_ADDR(RAM_S_ADDR),
        .I7_S_CMD(RAM_S_CMD),
        .I7_S_D_WR(RAM_S_D_WR)
    );
    
    //----------------> Reg operator A
    wire [7:0] IN_A = {SW_F, SW_E, SW_D, SW_C, SW_B, SW_A, SW_9, SW_8};
    
    CW_IN_REG_STI cw_in_reg_sti_a
    (
        .CLK(CLK_48),
        .RST(RST),
        
        .IN(IN_A),
        
        .S_D_WR(RG_A_S_D_WR),     
        .S_CMD(RG_A_S_CMD),     
        .S_EX_REQ(RG_A_S_EX_REQ),
        .S_ADDR(RG_A_S_ADDR),   
        .S_D_RD(RG_A_S_D_RD),
        .S_EX_ACK(RG_A_S_EX_ACK)
    );
    
    //----------------> Reg operator B
    wire [7:0] IN_B = {SW_7, SW_6, SW_5, SW_4, SW_3, SW_2, SW_1, SW_0}; 
    
    CW_IN_REG_STI cw_in_reg_sti_b
    (
        .CLK(CLK_48),
        .RST(RST),
        
        .IN(IN_B),
        
        .S_D_WR(RG_B_S_D_WR),     
        .S_CMD(RG_B_S_CMD),     
        .S_EX_REQ(RG_B_S_EX_REQ),
        .S_ADDR(RG_B_S_ADDR),   
        .S_D_RD(RG_B_S_D_RD),
        .S_EX_ACK(RG_B_S_EX_ACK)
    );
    
    //----------------> RAM
    localparam MUAW = 7;
    localparam  UAW = MUAW + 3;
    
    CW_RAM_8B 
    #(
        .MUAW(MUAW),     
        .UAW(UAW)
    )
    cw_ram_8b
    (
        .CLK(CLK_48),
        
        .S_EX_REQ(RAM_S_EX_REQ),
        .S_ADDR(RAM_S_ADDR),
        .S_CMD(RAM_S_CMD),
        .S_D_WR(RAM_S_D_WR),
        .S_EX_ACK(RAM_S_EX_ACK),
        .S_D_RD(RAM_S_D_RD)
    );
    
    //----------------> RGB matrix controller    
    CW_RGB_MATRIX_CNTRL cw_rgb_matrix_cntrl
    (
        .CLK(CLK_48),
        .RST(RST),
        .CE_PWM(CE_7_68kHz),
        
        .S_EX_REQ(RGB_MC_S_EX_REQ),
        .S_ADDR(RGB_MC_S_ADDR),
        .S_CMD(RGB_MC_S_CMD),
        .S_D_WR(RGB_MC_S_D_WR),
        .S_EX_ACK(RGB_MC_S_EX_ACK),
        .S_D_RD(RGB_MC_S_D_RD),
        
        .COL_R(COL_R_),
        .COL_G(COL_G_),
        .COL_B(COL_B_),
        .ROW(ROW)
    );
    
    //----------------> 7-SEG controller  
    CW_7SEG_CNTRL cw_7seg_cntrl
    (
        .CLK(CLK_48),
        .RST(RST),
        .CE(CE_1kHz),

        .S_EX_REQ(SEG_C_S_EX_REQ),
        .S_ADDR(SEG_C_S_ADDR),
        .S_CMD(SEG_C_S_CMD),
        .S_D_WR(SEG_C_S_D_WR),
        .S_EX_ACK(SEG_C_S_EX_ACK),
        .S_D_RD(SEG_C_S_D_RD),

        .AN(AN),
        .CAT(CAT)
    );
    
    //----------------> LED controller
    wire [15:0] OUT;
    
    CW_REG_STI cw_reg_sti
    (
        .CLK(CLK_48),
        .RST(RST),

        .S_EX_REQ(LED_C_S_EX_REQ),
        .S_ADDR(LED_C_S_ADDR),
        .S_CMD(LED_C_S_CMD),
        .S_D_WR(LED_C_S_D_WR),
        .S_EX_ACK(LED_C_S_EX_ACK),
        .S_D_RD(LED_C_S_D_RD),

        .OUT(OUT)
    );
    
    assign LED_0 = ~OUT[0];
    assign LED_1 = ~OUT[1];
    assign LED_2 = ~OUT[2];
    assign LED_3 = ~OUT[3];
    assign LED_4 = ~OUT[4];
    assign LED_5 = ~OUT[5];
    assign LED_6 = ~OUT[6];
    assign LED_7 = ~OUT[7];
    assign LED_8 = ~OUT[8];
    assign LED_9 = ~OUT[9];
    assign LED_A = ~OUT[10];
    assign LED_B = ~OUT[11];
    assign LED_C = ~OUT[12];
    assign LED_D = ~OUT[13];
    assign LED_E = ~OUT[14];
    assign LED_F = ~OUT[15];
    
    //----------------> IRQ monitor
    wire [3:0] BTN = {BTN_3, BTN_2, BTN_1, BTN_0};
    
    CW_IRQ_MONITOR cw_irq_monitor
    (
        .CLK(CLK_48),
        .RST(RST),
        .CE(CE_1kHz),

        .S_EX_REQ(IRQ_M_S_EX_REQ),
        .S_ADDR(IRQ_M_S_ADDR),
        .S_CMD(IRQ_M_S_CMD),
        .S_D_WR(IRQ_M_S_D_WR),
        .S_EX_ACK(IRQ_M_S_EX_ACK),
        .S_D_RD(IRQ_M_S_D_RD),

        .IRQ(IRQ),
        .BTN(BTN)
    );
    
endmodule
