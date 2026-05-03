`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Ilyasov A.E.
// 
// Create Date: 01.05.2026 22:08:49
// Design Name: 
// Module Name: CW_CPU_CORE_TB
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

module CW_CPU_CORE_TB;

    // ------------------------------------------------------------
    // System signals
    // ------------------------------------------------------------
    reg CLK;
    reg RST;

    // ------------------------------------------------------------
    // Program memory STI 1.0 port
    // ------------------------------------------------------------
    wire        PGM_S_EX_REQ;
    wire [17:2] PGM_S_ADDR;
    wire [ 3:0] PGM_S_NBE;
    wire [ 2:0] PGM_S_CMD;
    wire [31:0] PGM_S_D_WR;
    wire        PGM_S_EX_ACK;
    wire [31:0] PGM_S_D_RD;

    // ------------------------------------------------------------
    // Data memory STI 1.0 port
    // ------------------------------------------------------------
    wire        DM_S_EX_REQ;
    wire [15:0] DM_S_ADDR;
    wire [ 2:0] DM_S_CMD;
    wire [ 7:0] DM_S_D_WR;
    wire        DM_S_EX_ACK;
    wire [ 7:0] DM_S_D_RD;

    // ------------------------------------------------------------
    // Processor debug/control STI 1.0 port
    // Not used in this methodical TB: checks are hierarchical.
    // ------------------------------------------------------------
    reg         PROC_S_EX_REQ;
    reg  [ 5:0] PROC_S_ADDR;
    reg  [ 2:0] PROC_S_CMD;
    reg  [ 7:0] PROC_S_D_WR;
    wire        PROC_S_EX_ACK;
    wire [ 7:0] PROC_S_D_RD;

    // ------------------------------------------------------------
    // Interrupt interface
    // ------------------------------------------------------------
    reg  [15:0] IADDR;
    reg         IRQ;
    reg         SET_IRQ;

    // ------------------------------------------------------------
    // STI commands
    // ------------------------------------------------------------
    localparam [2:0] STI_WR = 3'b001;
    localparam [2:0] STI_RD = 3'b101;

    // ------------------------------------------------------------
    // Memories
    // PGM_MEM depth 256 matches the assembler output: one 32-bit word per line, padded to 256 words.
    // DM_MEM is full 64K because the IRQ-clear address is 16'hFFFF.
    // ------------------------------------------------------------
    localparam integer PGM_DEPTH = 256;
    localparam integer DM_DEPTH  = 65536;

    reg [31:0] PGM_MEM [0:PGM_DEPTH-1];
    reg [ 7:0] DM_MEM  [0:DM_DEPTH-1];

    integer pgm_i;
    integer dm_i;

    // Program memory model: immediate ACK, asynchronous read.
    assign PGM_S_EX_ACK = PGM_S_EX_REQ;
    assign PGM_S_D_RD   = (PGM_S_EX_REQ && (PGM_S_ADDR < PGM_DEPTH)) ?
                          PGM_MEM[PGM_S_ADDR] : 32'h00000000;

    // Data memory model: immediate ACK, asynchronous read, synchronous write.
    // Read is intentionally not gated by DM_S_CMD so MEMRD stays visible
    // during the second stage of LD/RETI instructions.
    assign DM_S_EX_ACK = DM_S_EX_REQ;
    assign DM_S_D_RD   = DM_MEM[DM_S_ADDR];

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            for (dm_i = 0; dm_i < DM_DEPTH; dm_i = dm_i + 1) begin
                DM_MEM[dm_i] <= 8'h00;
            end
        end else begin
            if (DM_S_EX_REQ && DM_S_EX_ACK && (DM_S_CMD == STI_WR)) begin
                DM_MEM[DM_S_ADDR] <= DM_S_D_WR;
            end
        end
    end

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    CW_CPU_CORE uut (
        .CLK           (CLK),
        .RST           (RST),

        .PGM_S_EX_REQ  (PGM_S_EX_REQ),
        .PGM_S_ADDR    (PGM_S_ADDR),
        .PGM_S_NBE     (PGM_S_NBE),
        .PGM_S_CMD     (PGM_S_CMD),
        .PGM_S_D_WR    (PGM_S_D_WR),
        .PGM_S_EX_ACK  (PGM_S_EX_ACK),
        .PGM_S_D_RD    (PGM_S_D_RD),

        .DM_S_EX_REQ   (DM_S_EX_REQ),
        .DM_S_ADDR     (DM_S_ADDR),
        .DM_S_CMD      (DM_S_CMD),
        .DM_S_D_WR     (DM_S_D_WR),
        .DM_S_EX_ACK   (DM_S_EX_ACK),
        .DM_S_D_RD     (DM_S_D_RD),

        .PROC_S_EX_REQ (PROC_S_EX_REQ),
        .PROC_S_ADDR   (PROC_S_ADDR),
        .PROC_S_CMD    (PROC_S_CMD),
        .PROC_S_D_WR   (PROC_S_D_WR),
        .PROC_S_EX_ACK (PROC_S_EX_ACK),
        .PROC_S_D_RD   (PROC_S_D_RD),

        .IADDR         (IADDR),
        .IRQ           (IRQ)
    );

    // ------------------------------------------------------------
    // Clock Generator
    // ------------------------------------------------------------
    parameter PERIOD_CLK     = 20.8;
    parameter DUTY_CYCLE_CLK = 0.4;

    always begin
        CLK = 1'b0;
        #(PERIOD_CLK * (1 - DUTY_CYCLE_CLK));
        CLK = 1'b1;
        #(PERIOD_CLK * DUTY_CYCLE_CLK);
    end

    // ------------------------------------------------------------
    // Test counters
    // ------------------------------------------------------------
    integer SUCCESS_TEST_COUNT = 0;
    integer TOTAL_SUCCESS_COUNT = 0;
    integer ERROR_TEST_COUNT = 0;
    integer TOTAL_TEST_COUNT = 0;
    integer SUCCESS = 0;

    integer TEST_LDL_COUNT   = 32;
    integer TEST_ADD_COUNT   = 7;
    integer TEST_ADDL_COUNT  = 7;
    integer TEST_SUB_COUNT   = 5;
    integer TEST_SUBL_COUNT  = 5;
    integer TEST_OR_COUNT    = 4;
    integer TEST_ORL_COUNT   = 4;
    integer TEST_AND_COUNT   = 4;
    integer TEST_ANDL_COUNT  = 4;
    integer TEST_INC_COUNT   = 4;
    integer TEST_DEC_COUNT   = 4;
    integer TEST_LSR_COUNT   = 8;
    integer TEST_RSR_COUNT   = 8;
    integer TEST_STLX_COUNT  = 8;
    integer TEST_STLY_COUNT  = 8;
    integer TEST_STLPX_COUNT = 8;
    integer TEST_STLPY_COUNT = 8;
    integer TEST_STX_COUNT   = 8;
    integer TEST_STY_COUNT   = 8;
    integer TEST_STPX_COUNT  = 8;
    integer TEST_STPY_COUNT  = 8;
    integer TEST_LDX_COUNT   = 8;
    integer TEST_LDY_COUNT   = 8;
    integer TEST_LDPX_COUNT  = 8;
    integer TEST_LDPY_COUNT  = 8;
    integer TEST_JMP_COUNT   = 1;
    integer TEST_JMPC_COUNT  = 4;
    integer TEST_JMPS_COUNT  = 4;

    // ------------------------------------------------------------
    // IRQ generator. IRQ is cleared by a write transaction to FFFF.
    // ------------------------------------------------------------
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            IRQ <= 1'b0;
        end else begin
            if (SET_IRQ) begin
                IRQ <= 1'b1;
            end else if ((DM_S_ADDR == 16'hFFFF) && DM_S_EX_REQ && DM_S_EX_ACK && (DM_S_CMD == STI_WR)) begin
                IRQ <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------
    // Service tasks
    // ------------------------------------------------------------
    task CLEAR_PGM;
        begin
            for (pgm_i = 0; pgm_i < PGM_DEPTH; pgm_i = pgm_i + 1) begin
                PGM_MEM[pgm_i] = 32'h00000000;
            end
        end
    endtask

    task LOAD_PROGRAM;
        input [8*256-1:0] FILE_NAME;
        begin
            CLEAR_PGM();
            $display("------------------------------------------------------------");
            $display("Loading program file: %0s", FILE_NAME);
            $readmemh(FILE_NAME, PGM_MEM);
            GEN_RST();
        end
    endtask

    task GEN_RST;
        begin
            // Force a real rising edge on RST on every test run.
            RST = 1'b0;
            #1;
            RST = 1'b1;

            PROC_S_EX_REQ = 1'b0;
            PROC_S_ADDR   = 6'h00;
            PROC_S_CMD    = STI_RD;
            PROC_S_D_WR   = 8'h00;
            IADDR         = 16'h0000;
            SET_IRQ       = 1'b0;
            SUCCESS_TEST_COUNT = 0;
            #100;
            @(posedge CLK);
            #(PERIOD_CLK * 0.2);
            RST = 1'b0;
        end
    endtask

    task INST_DONE;
        input [15:0] PC_VALUE;
        integer wait_pc_counter;
        integer wait_done_counter;
        begin
            wait_pc_counter = 0;
            while ((uut.u_pc.PC !== PC_VALUE) && (wait_pc_counter < 5000)) begin
                @(posedge CLK);
                wait_pc_counter = wait_pc_counter + 1;
            end

            if (wait_pc_counter >= 5000) begin
                $display("FAIL: timeout while waiting PC=%04h, current PC=%04h", PC_VALUE, uut.u_pc.PC);
                ERROR_TEST_COUNT = ERROR_TEST_COUNT + 1;
            end

            wait_done_counter = 0;
            while ((uut.done !== 1'b1) && (wait_done_counter < 5000)) begin
                @(posedge CLK);
                wait_done_counter = wait_done_counter + 1;
            end

            if (wait_done_counter >= 5000) begin
                $display("FAIL: timeout while waiting DONE at PC=%04h, current PC=%04h", PC_VALUE, uut.u_pc.PC);
                ERROR_TEST_COUNT = ERROR_TEST_COUNT + 1;
            end

            @(posedge CLK);
            #(PERIOD_CLK * 0.2);
        end
    endtask

    task PRINT_RESULT;
        input [8*32-1:0] TEST_NAME;
        input integer EXPECTED_COUNT;
        begin
            $display("Success %0s: %0d/%0d", TEST_NAME, SUCCESS_TEST_COUNT, EXPECTED_COUNT);
            if (SUCCESS_TEST_COUNT != EXPECTED_COUNT) begin
                $display("WARNING: %0s has failed checks.", TEST_NAME);
            end
        end
    endtask

    task PRINT_TOTAL_RESULT;
        begin
            $display("------------------------------------------------------------");
            $display("TOTAL SUCCESS CHECKS = %0d", TOTAL_SUCCESS_COUNT);
            $display("TOTAL CHECKS         = %0d", TOTAL_TEST_COUNT);
            $display("TOTAL ERRORS         = %0d", ERROR_TEST_COUNT);
            $display("------------------------------------------------------------");
            if (ERROR_TEST_COUNT == 0) begin
                $display("CW_CPU_CORE_TB PASSED");
            end else begin
                $display("CW_CPU_CORE_TB FAILED");
            end
        end
    endtask

    // ------------------------------------------------------------
    // Check functions
    // ------------------------------------------------------------
    function CHECK_REGFILE;
        input [4:0] ADDR;
        input [7:0] DATA;
        begin
            if (uut.u_regfile.REGFILE[ADDR] == DATA)
                CHECK_REGFILE = 1'b1;
            else
                CHECK_REGFILE = 1'b0;
        end
    endfunction

    function CHECK_MEM;
        input [15:0] ADDR;
        input [7:0] DATA;
        begin
            if (DM_MEM[ADDR] == DATA)
                CHECK_MEM = 1'b1;
            else
                CHECK_MEM = 1'b0;
        end
    endfunction

    function CHECK_SREG;
        input [7:0] DATA;
        begin
            if ({5'h00, uut.u_sreg.SREG} == DATA)
                CHECK_SREG = 1'b1;
            else
                CHECK_SREG = 1'b0;
        end
    endfunction

    // ------------------------------------------------------------
    // Verification tasks
    // ------------------------------------------------------------
    task VER_REGFILE;
        input [4:0] ADDR;
        input [7:0] DATA;
        input [15:0] PC_VALUE;
        begin
            INST_DONE(PC_VALUE);
            TOTAL_TEST_COUNT = TOTAL_TEST_COUNT + 1;
            if (CHECK_REGFILE(ADDR, DATA)) begin
                SUCCESS_TEST_COUNT = SUCCESS_TEST_COUNT + 1;
                TOTAL_SUCCESS_COUNT = TOTAL_SUCCESS_COUNT + 1;
                $display("PASS: PC=%04h REG[%02d]=%02h", PC_VALUE, ADDR, DATA);
            end else begin
                ERROR_TEST_COUNT = ERROR_TEST_COUNT + 1;
                $display("FAIL: PC=%04h REG[%02d] expected=%02h actual=%02h",
                         PC_VALUE, ADDR, DATA, uut.u_regfile.REGFILE[ADDR]);
            end
        end
    endtask

    task VER_ALU;
        input [4:0] ADDR;
        input [7:0] DATA;
        input [7:0] SREG_DATA;
        input [15:0] PC_VALUE;
        begin
            INST_DONE(PC_VALUE);
            TOTAL_TEST_COUNT = TOTAL_TEST_COUNT + 1;
            SUCCESS = 0;
            SUCCESS = SUCCESS + CHECK_REGFILE(ADDR, DATA);
            SUCCESS = SUCCESS + CHECK_SREG(SREG_DATA);
            if (SUCCESS == 2) begin
                SUCCESS_TEST_COUNT = SUCCESS_TEST_COUNT + 1;
                TOTAL_SUCCESS_COUNT = TOTAL_SUCCESS_COUNT + 1;
                $display("PASS: PC=%04h REG[%02d]=%02h SREG=%02h", PC_VALUE, ADDR, DATA, SREG_DATA);
            end else begin
                ERROR_TEST_COUNT = ERROR_TEST_COUNT + 1;
                $display("FAIL: PC=%04h REG[%02d] expected=%02h actual=%02h, SREG expected=%02h actual=%02h",
                         PC_VALUE, ADDR, DATA, uut.u_regfile.REGFILE[ADDR],
                         SREG_DATA, {5'h00, uut.u_sreg.SREG});
            end
        end
    endtask

    task VER_SREG;
        input [7:0] SREG_DATA;
        input [15:0] PC_VALUE;
        begin
            INST_DONE(PC_VALUE);
            TOTAL_TEST_COUNT = TOTAL_TEST_COUNT + 1;
            if (CHECK_SREG(SREG_DATA)) begin
                SUCCESS_TEST_COUNT = SUCCESS_TEST_COUNT + 1;
                TOTAL_SUCCESS_COUNT = TOTAL_SUCCESS_COUNT + 1;
                $display("PASS: PC=%04h SREG=%02h", PC_VALUE, SREG_DATA);
            end else begin
                ERROR_TEST_COUNT = ERROR_TEST_COUNT + 1;
                $display("FAIL: PC=%04h SREG expected=%02h actual=%02h",
                         PC_VALUE, SREG_DATA, {5'h00, uut.u_sreg.SREG});
            end
        end
    endtask

    task VER_MEM;
        input [15:0] ADDR;
        input [7:0] DATA;
        input [15:0] PC_VALUE;
        begin
            INST_DONE(PC_VALUE);
            TOTAL_TEST_COUNT = TOTAL_TEST_COUNT + 1;
            if (CHECK_MEM(ADDR, DATA)) begin
                SUCCESS_TEST_COUNT = SUCCESS_TEST_COUNT + 1;
                TOTAL_SUCCESS_COUNT = TOTAL_SUCCESS_COUNT + 1;
                $display("PASS: PC=%04h MEM[%04h]=%02h", PC_VALUE, ADDR, DATA);
            end else begin
                ERROR_TEST_COUNT = ERROR_TEST_COUNT + 1;
                $display("FAIL: PC=%04h MEM[%04h] expected=%02h actual=%02h",
                         PC_VALUE, ADDR, DATA, DM_MEM[ADDR]);
            end
        end
    endtask

    // ------------------------------------------------------------
    // Main test sequence: full methodical list
    // ------------------------------------------------------------
    initial begin
        $dumpfile("CW_CPU_CORE_TB.vcd");
        $dumpvars(0, CW_CPU_CORE_TB);

        RST           = 1'b1;
        PROC_S_EX_REQ = 1'b0;
        PROC_S_ADDR   = 6'h00;
        PROC_S_CMD    = STI_RD;
        PROC_S_D_WR   = 8'h00;
        IADDR         = 16'h0000;
        IRQ           = 1'b0;
        SET_IRQ       = 1'b0;
        CLEAR_PGM();

        // LDL
        LOAD_PROGRAM("ldl.mem");
        VER_REGFILE(5'b00000, 8'h01, 1);
        VER_REGFILE(5'b00001, 8'h02, 2);
        VER_REGFILE(5'b00010, 8'h04, 3);
        VER_REGFILE(5'b00011, 8'h08, 4);
        VER_REGFILE(5'b00100, 8'h10, 5);
        VER_REGFILE(5'b00101, 8'h20, 6);
        VER_REGFILE(5'b00110, 8'h40, 7);
        VER_REGFILE(5'b00111, 8'h80, 8);
        VER_REGFILE(5'b01000, 8'h80, 9);
        VER_REGFILE(5'b01001, 8'h40, 10);
        VER_REGFILE(5'b01010, 8'h20, 11);
        VER_REGFILE(5'b01011, 8'h10, 12);
        VER_REGFILE(5'b01100, 8'h08, 13);
        VER_REGFILE(5'b01101, 8'h04, 14);
        VER_REGFILE(5'b01110, 8'h02, 15);
        VER_REGFILE(5'b01111, 8'h01, 16);
        VER_REGFILE(5'b10000, 8'h01, 17);
        VER_REGFILE(5'b10001, 8'h02, 18);
        VER_REGFILE(5'b10010, 8'h04, 19);
        VER_REGFILE(5'b10011, 8'h08, 20);
        VER_REGFILE(5'b10100, 8'h10, 21);
        VER_REGFILE(5'b10101, 8'h20, 22);
        VER_REGFILE(5'b10110, 8'h40, 23);
        VER_REGFILE(5'b10111, 8'h80, 24);
        VER_REGFILE(5'b11000, 8'h80, 25);
        VER_REGFILE(5'b11001, 8'h40, 26);
        VER_REGFILE(5'b11010, 8'h20, 27);
        VER_REGFILE(5'b11011, 8'h10, 28);
        VER_REGFILE(5'b11100, 8'h08, 29);
        VER_REGFILE(5'b11101, 8'h04, 30);
        VER_REGFILE(5'b11110, 8'h02, 31);
        VER_REGFILE(5'b11111, 8'h01, 32);
        PRINT_RESULT("LDL", TEST_LDL_COUNT);

        // ADD
        LOAD_PROGRAM("add.mem");
        VER_ALU(5'b00000, 8'h00, 8'h07, 5);
        VER_ALU(5'b00000, 8'h00, 8'h07, 10);
        VER_ALU(5'b00000, 8'h00, 8'h07, 15);
        VER_ALU(5'b00000, 8'h71, 8'h04, 20);
        VER_ALU(5'b00000, 8'h10, 8'h04, 25);
        VER_ALU(5'b00000, 8'h10, 8'h04, 30);
        VER_ALU(5'b00000, 8'h10, 8'h04, 35);
        PRINT_RESULT("ADD", TEST_ADD_COUNT);

        // ADDL
        LOAD_PROGRAM("addl.mem");
        VER_ALU(5'b00000, 8'h00, 8'h07, 3);
        VER_ALU(5'b00000, 8'h00, 8'h07, 6);
        VER_ALU(5'b00000, 8'h00, 8'h07, 9);
        VER_ALU(5'b00000, 8'h71, 8'h04, 12);
        VER_ALU(5'b00000, 8'h10, 8'h04, 15);
        VER_ALU(5'b00000, 8'h10, 8'h04, 18);
        VER_ALU(5'b00000, 8'h10, 8'h04, 21);
        PRINT_RESULT("ADDL", TEST_ADDL_COUNT);

        // SUB
        LOAD_PROGRAM("sub.mem");
        VER_ALU(5'b10000, 8'hFE, 8'h05, 3);
        VER_ALU(5'b10000, 8'h0C, 8'h05, 6);
        VER_ALU(5'b10000, 8'hF4, 8'h04, 9);
        VER_ALU(5'b10000, 8'h02, 8'h04, 12);
        VER_ALU(5'b10000, 8'h00, 8'h06, 15);
        PRINT_RESULT("SUB", TEST_SUB_COUNT);

        // SUBL
        LOAD_PROGRAM("subl.mem");
        VER_ALU(5'b10000, 8'hFE, 8'h05, 2);
        VER_ALU(5'b10000, 8'h0C, 8'h05, 4);
        VER_ALU(5'b10000, 8'hF4, 8'h04, 6);
        VER_ALU(5'b10000, 8'h02, 8'h04, 8);
        VER_ALU(5'b10000, 8'h00, 8'h06, 10);
        PRINT_RESULT("SUBL", TEST_SUBL_COUNT);

        // OR
        LOAD_PROGRAM("or.mem");
        VER_ALU(5'b10000, 8'h00, 8'h06, 3);
        VER_ALU(5'b10000, 8'h0F, 8'h04, 6);
        VER_ALU(5'b10000, 8'hF0, 8'h04, 9);
        VER_ALU(5'b10000, 8'hFF, 8'h04, 12);
        PRINT_RESULT("OR", TEST_OR_COUNT);

        // ORL
        LOAD_PROGRAM("orl.mem");
        VER_ALU(5'b10000, 8'h00, 8'h06, 2);
        VER_ALU(5'b10000, 8'h0F, 8'h04, 4);
        VER_ALU(5'b10000, 8'hF0, 8'h04, 6);
        VER_ALU(5'b10000, 8'hFF, 8'h04, 8);
        PRINT_RESULT("ORL", TEST_ORL_COUNT);

        // AND
        LOAD_PROGRAM("and.mem");
        VER_ALU(5'b10000, 8'h00, 8'h06, 3);
        VER_ALU(5'b10000, 8'h0F, 8'h04, 6);
        VER_ALU(5'b10000, 8'hF0, 8'h04, 9);
        VER_ALU(5'b10000, 8'hFF, 8'h04, 12);
        PRINT_RESULT("AND", TEST_AND_COUNT);

        // ANDL
        LOAD_PROGRAM("andl.mem");
        VER_ALU(5'b10000, 8'h00, 8'h06, 2);
        VER_ALU(5'b10000, 8'h0F, 8'h04, 4);
        VER_ALU(5'b10000, 8'hF0, 8'h04, 6);
        VER_ALU(5'b10000, 8'hFF, 8'h04, 8);
        PRINT_RESULT("ANDL", TEST_ANDL_COUNT);

        // INC
        LOAD_PROGRAM("inc.mem");
        VER_ALU(5'b10000, 8'h01, 8'h04, 2);
        VER_ALU(5'b10000, 8'h80, 8'h04, 4);
        VER_ALU(5'b10000, 8'h81, 8'h04, 5);
        VER_ALU(5'b10000, 8'h00, 8'h07, 7);
        PRINT_RESULT("INC", TEST_INC_COUNT);

        // DEC
        LOAD_PROGRAM("dec.mem");
        VER_ALU(5'b10000, 8'h00, 8'h06, 2);
        VER_ALU(5'b10000, 8'hFF, 8'h05, 3);
        VER_ALU(5'b10000, 8'h80, 8'h04, 5);
        VER_ALU(5'b10000, 8'h7F, 8'h04, 6);
        PRINT_RESULT("DEC", TEST_DEC_COUNT);

        // LSR
        LOAD_PROGRAM("lsr.mem");
        VER_ALU(5'b00000, 8'hFF, 8'h04, 2);
        VER_ALU(5'b00000, 8'hFE, 8'h04, 4);
        VER_ALU(5'b00000, 8'hFC, 8'h04, 6);
        VER_ALU(5'b00000, 8'hF8, 8'h04, 8);
        VER_ALU(5'b00000, 8'hF0, 8'h04, 10);
        VER_ALU(5'b00000, 8'hE0, 8'h04, 12);
        VER_ALU(5'b00000, 8'hC0, 8'h04, 14);
        VER_ALU(5'b00000, 8'h00, 8'h06, 16);
        PRINT_RESULT("LSR", TEST_LSR_COUNT);

        // RSR
        LOAD_PROGRAM("rsr.mem");
        VER_ALU(5'b00000, 8'hFF, 8'h04, 2);
        VER_ALU(5'b00000, 8'h7F, 8'h04, 4);
        VER_ALU(5'b00000, 8'h3F, 8'h04, 6);
        VER_ALU(5'b00000, 8'h1F, 8'h04, 8);
        VER_ALU(5'b00000, 8'h0F, 8'h04, 10);
        VER_ALU(5'b00000, 8'h07, 8'h04, 12);
        VER_ALU(5'b00000, 8'h03, 8'h04, 14);
        VER_ALU(5'b00000, 8'h00, 8'h06, 16);
        PRINT_RESULT("RSR", TEST_RSR_COUNT);

        // STL X
        LOAD_PROGRAM("stl_x.mem");
        VER_MEM(16'h0000, 8'h01, 4);
        VER_MEM(16'h0001, 8'h02, 6);
        VER_MEM(16'h0002, 8'h04, 8);
        VER_MEM(16'h0003, 8'h08, 10);
        VER_MEM(16'h0004, 8'h10, 12);
        VER_MEM(16'h0005, 8'h20, 14);
        VER_MEM(16'h0006, 8'h40, 16);
        VER_MEM(16'h0007, 8'h80, 18);
        PRINT_RESULT("STL X", TEST_STLX_COUNT);

        // STL Y
        LOAD_PROGRAM("stl_y.mem");
        VER_MEM(16'h0000, 8'h01, 4);
        VER_MEM(16'h0001, 8'h02, 6);
        VER_MEM(16'h0002, 8'h04, 8);
        VER_MEM(16'h0003, 8'h08, 10);
        VER_MEM(16'h0004, 8'h10, 12);
        VER_MEM(16'h0005, 8'h20, 14);
        VER_MEM(16'h0006, 8'h40, 16);
        VER_MEM(16'h0007, 8'h80, 18);
        PRINT_RESULT("STL Y", TEST_STLY_COUNT);

        // STL X+
        LOAD_PROGRAM("stl_px.mem");
        VER_MEM(16'h0000, 8'h01, 4);
        VER_MEM(16'h0001, 8'h02, 5);
        VER_MEM(16'h0002, 8'h04, 6);
        VER_MEM(16'h0003, 8'h08, 7);
        VER_MEM(16'h0004, 8'h10, 8);
        VER_MEM(16'h0005, 8'h20, 9);
        VER_MEM(16'h0006, 8'h40, 10);
        VER_MEM(16'h0007, 8'h80, 11);
        PRINT_RESULT("STL X+", TEST_STLPX_COUNT);

        // STL Y+
        LOAD_PROGRAM("stl_py.mem");
        VER_MEM(16'h0000, 8'h01, 4);
        VER_MEM(16'h0001, 8'h02, 5);
        VER_MEM(16'h0002, 8'h04, 6);
        VER_MEM(16'h0003, 8'h08, 7);
        VER_MEM(16'h0004, 8'h10, 8);
        VER_MEM(16'h0005, 8'h20, 9);
        VER_MEM(16'h0006, 8'h40, 10);
        VER_MEM(16'h0007, 8'h80, 11);
        PRINT_RESULT("STL Y+", TEST_STLPY_COUNT);

        // ST X
        LOAD_PROGRAM("st_x.mem");
        VER_MEM(16'h0000, 8'h01, 12);
        VER_MEM(16'h0001, 8'h02, 14);
        VER_MEM(16'h0002, 8'h04, 16);
        VER_MEM(16'h0003, 8'h08, 18);
        VER_MEM(16'h0004, 8'h10, 20);
        VER_MEM(16'h0005, 8'h20, 22);
        VER_MEM(16'h0006, 8'h40, 24);
        VER_MEM(16'h0007, 8'h80, 26);
        PRINT_RESULT("ST X", TEST_STX_COUNT);

        // ST Y
        LOAD_PROGRAM("st_y.mem");
        VER_MEM(16'h0000, 8'h01, 12);
        VER_MEM(16'h0001, 8'h02, 14);
        VER_MEM(16'h0002, 8'h04, 16);
        VER_MEM(16'h0003, 8'h08, 18);
        VER_MEM(16'h0004, 8'h10, 20);
        VER_MEM(16'h0005, 8'h20, 22);
        VER_MEM(16'h0006, 8'h40, 24);
        VER_MEM(16'h0007, 8'h80, 26);
        PRINT_RESULT("ST Y", TEST_STY_COUNT);

        // ST X+
        LOAD_PROGRAM("st_px.mem");
        VER_MEM(16'h0000, 8'h01, 12);
        VER_MEM(16'h0001, 8'h02, 13);
        VER_MEM(16'h0002, 8'h04, 14);
        VER_MEM(16'h0003, 8'h08, 15);
        VER_MEM(16'h0004, 8'h10, 16);
        VER_MEM(16'h0005, 8'h20, 17);
        VER_MEM(16'h0006, 8'h40, 18);
        VER_MEM(16'h0007, 8'h80, 19);
        PRINT_RESULT("ST X+", TEST_STPX_COUNT);

        // ST Y+
        LOAD_PROGRAM("st_py.mem");
        VER_MEM(16'h0000, 8'h01, 12);
        VER_MEM(16'h0001, 8'h02, 13);
        VER_MEM(16'h0002, 8'h04, 14);
        VER_MEM(16'h0003, 8'h08, 15);
        VER_MEM(16'h0004, 8'h10, 16);
        VER_MEM(16'h0005, 8'h20, 17);
        VER_MEM(16'h0006, 8'h40, 18);
        VER_MEM(16'h0007, 8'h80, 19);
        PRINT_RESULT("ST Y+", TEST_STPY_COUNT);

        // LD X
        LOAD_PROGRAM("ld_x.mem");
        VER_REGFILE(5'b00000, 8'h01, 14);
        VER_REGFILE(5'b00001, 8'h02, 16);
        VER_REGFILE(5'b00010, 8'h04, 18);
        VER_REGFILE(5'b00011, 8'h08, 20);
        VER_REGFILE(5'b00100, 8'h10, 22);
        VER_REGFILE(5'b00101, 8'h20, 24);
        VER_REGFILE(5'b00110, 8'h40, 26);
        VER_REGFILE(5'b00111, 8'h80, 28);
        PRINT_RESULT("LD X", TEST_LDX_COUNT);

        // LD Y
        LOAD_PROGRAM("ld_y.mem");
        VER_REGFILE(5'b00000, 8'h01, 14);
        VER_REGFILE(5'b00001, 8'h02, 16);
        VER_REGFILE(5'b00010, 8'h04, 18);
        VER_REGFILE(5'b00011, 8'h08, 20);
        VER_REGFILE(5'b00100, 8'h10, 22);
        VER_REGFILE(5'b00101, 8'h20, 24);
        VER_REGFILE(5'b00110, 8'h40, 26);
        VER_REGFILE(5'b00111, 8'h80, 28);
        PRINT_RESULT("LD Y", TEST_LDY_COUNT);

        // LD X+
        LOAD_PROGRAM("ld_px.mem");
        VER_REGFILE(5'b00000, 8'h01, 14);
        VER_REGFILE(5'b00001, 8'h02, 15);
        VER_REGFILE(5'b00010, 8'h04, 16);
        VER_REGFILE(5'b00011, 8'h08, 17);
        VER_REGFILE(5'b00100, 8'h10, 18);
        VER_REGFILE(5'b00101, 8'h20, 19);
        VER_REGFILE(5'b00110, 8'h40, 20);
        VER_REGFILE(5'b00111, 8'h80, 21);
        PRINT_RESULT("LD X+", TEST_LDPX_COUNT);

        // LD Y+
        LOAD_PROGRAM("ld_py.mem");
        VER_REGFILE(5'b00000, 8'h01, 14);
        VER_REGFILE(5'b00001, 8'h02, 15);
        VER_REGFILE(5'b00010, 8'h04, 16);
        VER_REGFILE(5'b00011, 8'h08, 17);
        VER_REGFILE(5'b00100, 8'h10, 18);
        VER_REGFILE(5'b00101, 8'h20, 19);
        VER_REGFILE(5'b00110, 8'h40, 20);
        VER_REGFILE(5'b00111, 8'h80, 21);
        PRINT_RESULT("LD Y+", TEST_LDPY_COUNT);

        // JMP
        LOAD_PROGRAM("jmp.mem");
        VER_REGFILE(5'b00000, 8'hFF, 5);
        PRINT_RESULT("JMP", TEST_JMP_COUNT);

        // JMPC
        LOAD_PROGRAM("jmpc.mem");
        VER_REGFILE(5'b00001, 8'h02, 4);
        VER_REGFILE(5'b00001, 8'h04, 8);
        VER_REGFILE(5'b00001, 8'h05, 12);
        VER_REGFILE(5'b00001, 8'h06, 16);
        PRINT_RESULT("JMPC", TEST_JMPC_COUNT);

        // JMPS
        LOAD_PROGRAM("jmps.mem");
        VER_REGFILE(5'b00001, 8'h01, 4);
        VER_REGFILE(5'b00001, 8'h02, 8);
        VER_REGFILE(5'b00001, 8'h04, 12);
        VER_REGFILE(5'b00001, 8'h06, 16);
        PRINT_RESULT("JMPS", TEST_JMPS_COUNT);

        // IRQ / RETI smoke check from methodical template
        LOAD_PROGRAM("check_irq.mem");
        INST_DONE(16'h0005);
        SET_IRQ = 1'b1;
        @(posedge IRQ);
        SET_IRQ = 1'b0;
        @(posedge CLK);
        #(PERIOD_CLK * 0.2);
        INST_DONE(16'h0005);
        $display("IRQ/RETI smoke check finished");

        PRINT_TOTAL_RESULT();
        #100;
        $stop;
    end

endmodule
