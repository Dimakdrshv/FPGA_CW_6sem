`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////
// Testbench: CW_CPU_CORE_TB
// Variant  : Kudryashov D.S.
// Purpose  : Task-based verification of CW_CPU_CORE_V10 without external .mem files.
//            The testbench generates command words itself using Kudryashov opcodes.
//////////////////////////////////////////////////////////////////////////////////////

module CW_CPU_CORE_TB;

// ------------------------------------------------------------
// Clock/reset
// ------------------------------------------------------------
reg CLK;
reg RST;

parameter PERIOD_CLK = 20.8;
parameter DUTY_CYCLE_CLK = 0.4;

always begin
    CLK = 1'b0;
    #(PERIOD_CLK * (1.0 - DUTY_CYCLE_CLK));
    CLK = 1'b1;
    #(PERIOD_CLK * DUTY_CYCLE_CLK);
end

// ------------------------------------------------------------
// STI program memory port
// ------------------------------------------------------------
wire        PGM_S_EX_REQ;
wire [17:2] PGM_S_ADDR;
wire [ 3:0] PGM_S_NBE;
wire [ 2:0] PGM_S_CMD;
wire [31:0] PGM_S_D_WR;
wire        PGM_S_EX_ACK;
wire [31:0] PGM_S_D_RD;

// ------------------------------------------------------------
// STI data memory port
// ------------------------------------------------------------
wire        DM_S_EX_REQ;
wire [15:0] DM_S_ADDR;
wire [ 2:0] DM_S_CMD;
wire [ 7:0] DM_S_D_WR;
wire        DM_S_EX_ACK;
wire [ 7:0] DM_S_D_RD;

// ------------------------------------------------------------
// Processor debug/control STI port
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
// Kudryashov command opcodes, CMD[31:28]
// ------------------------------------------------------------
localparam [3:0] OP_ADD  = 4'b0001;
localparam [3:0] OP_SUB  = 4'b1110;
localparam [3:0] OP_OR   = 4'b1100;
localparam [3:0] OP_AND  = 4'b0100;
localparam [3:0] OP_INC  = 4'b0111;
localparam [3:0] OP_DEC  = 4'b1111;
localparam [3:0] OP_LSR  = 4'b0101;
localparam [3:0] OP_RSR  = 4'b0010;
localparam [3:0] OP_JMP  = 4'b1011;
localparam [3:0] OP_JMPS = 4'b1010; // JMPS/JMPC share opcode; flag is selected by mode bits
localparam [3:0] OP_MOV  = 4'b1001; // LDL/MOV
localparam [3:0] OP_LD   = 4'b1000;
localparam [3:0] OP_STL  = 4'b0011;
localparam [3:0] OP_ST   = 4'b1101;
localparam [3:0] OP_NOP  = 4'b0000;
localparam [3:0] OP_RETI = 4'b0110;

// ------------------------------------------------------------
// Registers
// ------------------------------------------------------------
localparam [4:0] R0  = 5'd0;
localparam [4:0] R1  = 5'd1;
localparam [4:0] R2  = 5'd2;
localparam [4:0] R3  = 5'd3;
localparam [4:0] R4  = 5'd4;
localparam [4:0] R5  = 5'd5;
localparam [4:0] R6  = 5'd6;
localparam [4:0] R7  = 5'd7;
localparam [4:0] R16 = 5'd16;
localparam [4:0] R17 = 5'd17;
localparam [4:0] XL  = 5'd26;
localparam [4:0] XH  = 5'd27;
localparam [4:0] YL  = 5'd28;
localparam [4:0] YH  = 5'd29;
localparam [4:0] SPL = 5'd30;
localparam [4:0] SPH = 5'd31;

// ------------------------------------------------------------
// Addressing modes. Decoder uses mode[3] for Y and mode[3:2] for post-increment.
// ------------------------------------------------------------
localparam [3:0] MODE_X  = 4'b0000;
localparam [3:0] MODE_XP = 4'b0100;
localparam [3:0] MODE_Y  = 4'b1000;
localparam [3:0] MODE_YP = 4'b1100;

// SREG bits used by conditional jumps
localparam [2:0] FLAG_C = 3'd0;
localparam [2:0] FLAG_Z = 3'd1;

localparam [31:0] CMD_NOP_WORD = 32'h00000000;

// ------------------------------------------------------------
// UUT
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
// Program memory model
// ------------------------------------------------------------
reg [31:0] PGM_MEM [0:65535];

assign PGM_S_EX_ACK = PGM_S_EX_REQ;
assign PGM_S_D_RD   = PGM_MEM[PGM_S_ADDR];

// ------------------------------------------------------------
// Data memory model
// Asynchronous read is intentional: LD uses data after memory request stage.
// ------------------------------------------------------------
reg [7:0] DM_MEM [0:65535];
integer mem_i;

assign DM_S_EX_ACK = DM_S_EX_REQ;
assign DM_S_D_RD   = DM_MEM[DM_S_ADDR];

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        for (mem_i = 0; mem_i < 65536; mem_i = mem_i + 1) begin
            DM_MEM[mem_i] <= 8'h00;
        end
    end else begin
        if (DM_S_EX_REQ && (DM_S_CMD == STI_WR)) begin
            DM_MEM[DM_S_ADDR] <= DM_S_D_WR;
        end
    end
end

// ------------------------------------------------------------
// Optional IRQ generator
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
// Command builders
// ------------------------------------------------------------
function [31:0] MAKE_CMD;
    input [3:0] OP;
    input [3:0] MODE;
    input [4:0] RD;
    input [4:0] RR;
    input [7:0] LIT;
    begin
        MAKE_CMD = {OP, MODE, RD, 3'b000, RR, 3'b000, LIT};
    end
endfunction

function [31:0] CMD_LDL;
    input [4:0] RD;
    input [7:0] LIT;
    begin
        CMD_LDL = MAKE_CMD(OP_MOV, 4'b0000, RD, 5'd0, LIT);
    end
endfunction

function [31:0] CMD_MOV;
    input [4:0] RD;
    input [4:0] RR;
    begin
        CMD_MOV = MAKE_CMD(OP_MOV, 4'b1000, RD, RR, 8'h00);
    end
endfunction

function [31:0] CMD_ALU_R;
    input [3:0] OP;
    input [4:0] RD;
    input [4:0] RR;
    begin
        CMD_ALU_R = MAKE_CMD(OP, 4'b0000, RD, RR, 8'h00);
    end
endfunction

function [31:0] CMD_ALU_L;
    input [3:0] OP;
    input [4:0] RD;
    input [7:0] LIT;
    begin
        CMD_ALU_L = MAKE_CMD(OP, 4'b1000, RD, 5'd0, LIT);
    end
endfunction

function [31:0] CMD_SHIFT;
    input [3:0] OP;
    input [4:0] RD;
    input [2:0] SHIFT;
    begin
        CMD_SHIFT = MAKE_CMD(OP, {SHIFT, 1'b0}, RD, 5'd0, 8'h00);
    end
endfunction

function [31:0] CMD_STL;
    input [3:0] MODE;
    input [7:0] LIT;
    begin
        CMD_STL = MAKE_CMD(OP_STL, MODE, 5'd0, 5'd0, LIT);
    end
endfunction

function [31:0] CMD_ST;
    input [3:0] MODE;
    input [4:0] RR;
    begin
        CMD_ST = MAKE_CMD(OP_ST, MODE, 5'd0, RR, 8'h00);
    end
endfunction

function [31:0] CMD_LD;
    input [4:0] RD;
    input [3:0] MODE;
    begin
        CMD_LD = MAKE_CMD(OP_LD, MODE, RD, 5'd0, 8'h00);
    end
endfunction

function [31:0] CMD_JMP;
    input [15:0] ADDR;
    begin
        CMD_JMP = {OP_JMP, 4'h0, 8'h00, ADDR};
    end
endfunction

function [31:0] CMD_JMPS;
    input [2:0] FLAG_NUM;
    input       JUMP_IF_SET;
    input [15:0] OFFSET;
    reg   [3:0] MODE;
    begin
        MODE = {FLAG_NUM, ~JUMP_IF_SET};
        CMD_JMPS = {OP_JMPS, MODE, 8'h00, OFFSET};
    end
endfunction

function [31:0] CMD_RETI;
    input DUMMY;
    begin
        CMD_RETI = {OP_RETI, 28'h0000000};
    end
endfunction

// ------------------------------------------------------------
// Common service tasks
// ------------------------------------------------------------
integer pgm_i;
integer SUCCESS_TEST_COUNT;
integer TOTAL_SUCCESS_COUNT;
integer ERROR_TEST_COUNT;
integer TOTAL_TEST_COUNT;
integer SUCCESS;

task CLEAR_PGM;
    begin
        for (pgm_i = 0; pgm_i < 65536; pgm_i = pgm_i + 1) begin
            PGM_MEM[pgm_i] = CMD_NOP_WORD;
        end
    end
endtask

task SET_PGM;
    input [15:0] ADDR;
    input [31:0] DATA;
    begin
        PGM_MEM[ADDR] = DATA;
    end
endtask

task GEN_RST;
    begin
        RST           = 1'b1;
        PROC_S_EX_REQ = 1'b0;
        PROC_S_ADDR   = 6'h00;
        PROC_S_CMD    = STI_RD;
        PROC_S_D_WR   = 8'h00;
        IADDR         = 16'h0010;
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
            $display("FAIL: timeout while waiting DONE at PC=%04h", PC_VALUE);
            ERROR_TEST_COUNT = ERROR_TEST_COUNT + 1;
        end

        @(posedge CLK);
        #(PERIOD_CLK * 0.2);
    end
endtask

function CHECK_REGFILE;
    input [4:0] ADDR;
    input [7:0] DATA;
    begin
        CHECK_REGFILE = (uut.u_regfile.REGFILE[ADDR] == DATA);
    end
endfunction

function CHECK_MEM;
    input [15:0] ADDR;
    input [7:0] DATA;
    begin
        CHECK_MEM = (DM_MEM[ADDR] == DATA);
    end
endfunction

function CHECK_SREG;
    input [7:0] DATA;
    begin
        CHECK_SREG = ({5'h00, uut.u_sreg.SREG} == DATA);
    end
endfunction

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

task VER_REGFILE_NOW;
    input [4:0] ADDR;
    input [7:0] DATA;
    begin
        TOTAL_TEST_COUNT = TOTAL_TEST_COUNT + 1;
        if (CHECK_REGFILE(ADDR, DATA)) begin
            SUCCESS_TEST_COUNT = SUCCESS_TEST_COUNT + 1;
            TOTAL_SUCCESS_COUNT = TOTAL_SUCCESS_COUNT + 1;
            $display("PASS: REG[%02d]=%02h", ADDR, DATA);
        end else begin
            ERROR_TEST_COUNT = ERROR_TEST_COUNT + 1;
            $display("FAIL: REG[%02d] expected=%02h actual=%02h",
                     ADDR, DATA, uut.u_regfile.REGFILE[ADDR]);
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
                     PC_VALUE, ADDR, DATA, uut.u_regfile.REGFILE[ADDR], SREG_DATA, {5'h00, uut.u_sreg.SREG});
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

task PRINT_RESULT;
    input [8*32-1:0] TEST_NAME;
    input integer EXPECTED_COUNT;
    begin
        $display("Success %0s: %0d/%0d", TEST_NAME, SUCCESS_TEST_COUNT, EXPECTED_COUNT);
        if (SUCCESS_TEST_COUNT != EXPECTED_COUNT) begin
            $display("WARNING: %0s has failed checks.", TEST_NAME);
        end
        $display("------------------------------------------------------------");
    end
endtask

// ------------------------------------------------------------
// Test scenarios
// ------------------------------------------------------------
task TEST_LDL;
    begin
        CLEAR_PGM();
        SET_PGM(16'h0001, CMD_LDL(5'd0,  8'h01));
        SET_PGM(16'h0002, CMD_LDL(5'd1,  8'h02));
        SET_PGM(16'h0003, CMD_LDL(5'd2,  8'h04));
        SET_PGM(16'h0004, CMD_LDL(5'd3,  8'h08));
        SET_PGM(16'h0005, CMD_LDL(5'd4,  8'h10));
        SET_PGM(16'h0006, CMD_LDL(5'd5,  8'h20));
        SET_PGM(16'h0007, CMD_LDL(5'd6,  8'h40));
        SET_PGM(16'h0008, CMD_LDL(5'd7,  8'h80));
        SET_PGM(16'h0009, CMD_LDL(5'd8,  8'h80));
        SET_PGM(16'h000a, CMD_LDL(5'd9,  8'h40));
        SET_PGM(16'h000b, CMD_LDL(5'd10, 8'h20));
        SET_PGM(16'h000c, CMD_LDL(5'd11, 8'h10));
        SET_PGM(16'h000d, CMD_LDL(5'd12, 8'h08));
        SET_PGM(16'h000e, CMD_LDL(5'd13, 8'h04));
        SET_PGM(16'h000f, CMD_LDL(5'd14, 8'h02));
        SET_PGM(16'h0010, CMD_LDL(5'd15, 8'h01));
        SET_PGM(16'h0011, CMD_LDL(5'd16, 8'h01));
        SET_PGM(16'h0012, CMD_LDL(5'd17, 8'h02));
        SET_PGM(16'h0013, CMD_LDL(5'd18, 8'h04));
        SET_PGM(16'h0014, CMD_LDL(5'd19, 8'h08));
        SET_PGM(16'h0015, CMD_LDL(5'd20, 8'h10));
        SET_PGM(16'h0016, CMD_LDL(5'd21, 8'h20));
        SET_PGM(16'h0017, CMD_LDL(5'd22, 8'h40));
        SET_PGM(16'h0018, CMD_LDL(5'd23, 8'h80));
        SET_PGM(16'h0019, CMD_LDL(5'd24, 8'h80));
        SET_PGM(16'h001a, CMD_LDL(5'd25, 8'h40));
        SET_PGM(16'h001b, CMD_LDL(5'd26, 8'h20));
        SET_PGM(16'h001c, CMD_LDL(5'd27, 8'h10));
        SET_PGM(16'h001d, CMD_LDL(5'd28, 8'h08));
        SET_PGM(16'h001e, CMD_LDL(5'd29, 8'h04));
        SET_PGM(16'h001f, CMD_LDL(5'd30, 8'h02));
        SET_PGM(16'h0020, CMD_LDL(5'd31, 8'h01));

        GEN_RST();
        VER_REGFILE(5'd0,  8'h01, 16'h0001);
        VER_REGFILE(5'd1,  8'h02, 16'h0002);
        VER_REGFILE(5'd2,  8'h04, 16'h0003);
        VER_REGFILE(5'd3,  8'h08, 16'h0004);
        VER_REGFILE(5'd4,  8'h10, 16'h0005);
        VER_REGFILE(5'd5,  8'h20, 16'h0006);
        VER_REGFILE(5'd6,  8'h40, 16'h0007);
        VER_REGFILE(5'd7,  8'h80, 16'h0008);
        VER_REGFILE(5'd8,  8'h80, 16'h0009);
        VER_REGFILE(5'd9,  8'h40, 16'h000a);
        VER_REGFILE(5'd10, 8'h20, 16'h000b);
        VER_REGFILE(5'd11, 8'h10, 16'h000c);
        VER_REGFILE(5'd12, 8'h08, 16'h000d);
        VER_REGFILE(5'd13, 8'h04, 16'h000e);
        VER_REGFILE(5'd14, 8'h02, 16'h000f);
        VER_REGFILE(5'd15, 8'h01, 16'h0010);
        VER_REGFILE(5'd16, 8'h01, 16'h0011);
        VER_REGFILE(5'd17, 8'h02, 16'h0012);
        VER_REGFILE(5'd18, 8'h04, 16'h0013);
        VER_REGFILE(5'd19, 8'h08, 16'h0014);
        VER_REGFILE(5'd20, 8'h10, 16'h0015);
        VER_REGFILE(5'd21, 8'h20, 16'h0016);
        VER_REGFILE(5'd22, 8'h40, 16'h0017);
        VER_REGFILE(5'd23, 8'h80, 16'h0018);
        VER_REGFILE(5'd24, 8'h80, 16'h0019);
        VER_REGFILE(5'd25, 8'h40, 16'h001a);
        VER_REGFILE(5'd26, 8'h20, 16'h001b);
        VER_REGFILE(5'd27, 8'h10, 16'h001c);
        VER_REGFILE(5'd28, 8'h08, 16'h001d);
        VER_REGFILE(5'd29, 8'h04, 16'h001e);
        VER_REGFILE(5'd30, 8'h02, 16'h001f);
        VER_REGFILE(5'd31, 8'h01, 16'h0020);
        PRINT_RESULT("LDL", 32);
    end
endtask

task BUILD_ALU_R_CASE;
    input [15:0] BASE;
    input [3:0] OP;
    input [7:0] A;
    input [7:0] B;
    begin
        SET_PGM(BASE + 0, CMD_LDL(R16, A));
        SET_PGM(BASE + 1, CMD_MOV(R0, R16));
        SET_PGM(BASE + 2, CMD_LDL(R17, B));
        SET_PGM(BASE + 3, CMD_MOV(R1, R17));
        SET_PGM(BASE + 4, CMD_ALU_R(OP, R0, R1));
    end
endtask

task BUILD_ALU_L_CASE;
    input [15:0] BASE;
    input [3:0] OP;
    input [7:0] A;
    input [7:0] B;
    begin
        SET_PGM(BASE + 0, CMD_LDL(R16, A));
        SET_PGM(BASE + 1, CMD_MOV(R0, R16));
        SET_PGM(BASE + 2, CMD_ALU_L(OP, R0, B));
    end
endtask

task TEST_ADD;
    begin
        CLEAR_PGM();
        BUILD_ALU_R_CASE(16'h0001, OP_ADD, 8'h80, 8'h80);
        BUILD_ALU_R_CASE(16'h0006, OP_ADD, 8'he0, 8'h20);
        BUILD_ALU_R_CASE(16'h000b, OP_ADD, 8'h20, 8'he0);
        BUILD_ALU_R_CASE(16'h0010, OP_ADD, 8'h70, 8'h01);
        BUILD_ALU_R_CASE(16'h0015, OP_ADD, 8'h08, 8'h08);
        BUILD_ALU_R_CASE(16'h001a, OP_ADD, 8'h0e, 8'h02);
        BUILD_ALU_R_CASE(16'h001f, OP_ADD, 8'h02, 8'h0e);
        GEN_RST();
        VER_ALU(R0, 8'h00, 8'h07, 16'h0005);
        VER_ALU(R0, 8'h00, 8'h07, 16'h000a);
        VER_ALU(R0, 8'h00, 8'h07, 16'h000f);
        VER_ALU(R0, 8'h71, 8'h04, 16'h0014);
        VER_ALU(R0, 8'h10, 8'h04, 16'h0019);
        VER_ALU(R0, 8'h10, 8'h04, 16'h001e);
        VER_ALU(R0, 8'h10, 8'h04, 16'h0023);
        PRINT_RESULT("ADD", 7);
    end
endtask

task TEST_ADDL;
    begin
        CLEAR_PGM();
        BUILD_ALU_L_CASE(16'h0001, OP_ADD, 8'h80, 8'h80);
        BUILD_ALU_L_CASE(16'h0004, OP_ADD, 8'he0, 8'h20);
        BUILD_ALU_L_CASE(16'h0007, OP_ADD, 8'h20, 8'he0);
        BUILD_ALU_L_CASE(16'h000a, OP_ADD, 8'h70, 8'h01);
        BUILD_ALU_L_CASE(16'h000d, OP_ADD, 8'h08, 8'h08);
        BUILD_ALU_L_CASE(16'h0010, OP_ADD, 8'h0e, 8'h02);
        BUILD_ALU_L_CASE(16'h0013, OP_ADD, 8'h02, 8'h0e);
        GEN_RST();
        VER_ALU(R0, 8'h00, 8'h07, 16'h0003);
        VER_ALU(R0, 8'h00, 8'h07, 16'h0006);
        VER_ALU(R0, 8'h00, 8'h07, 16'h0009);
        VER_ALU(R0, 8'h71, 8'h04, 16'h000c);
        VER_ALU(R0, 8'h10, 8'h04, 16'h000f);
        VER_ALU(R0, 8'h10, 8'h04, 16'h0012);
        VER_ALU(R0, 8'h10, 8'h04, 16'h0015);
        PRINT_RESULT("ADDL", 7);
    end
endtask

task TEST_SUB;
    begin
        CLEAR_PGM();
        SET_PGM(16'h0001, CMD_LDL(R16, 8'h05)); SET_PGM(16'h0002, CMD_LDL(R17, 8'h07)); SET_PGM(16'h0003, CMD_ALU_R(OP_SUB, R16, R17));
        SET_PGM(16'h0004, CMD_LDL(R16, 8'h05)); SET_PGM(16'h0005, CMD_LDL(R17, 8'hf9)); SET_PGM(16'h0006, CMD_ALU_R(OP_SUB, R16, R17));
        SET_PGM(16'h0007, CMD_LDL(R16, 8'hfb)); SET_PGM(16'h0008, CMD_LDL(R17, 8'h07)); SET_PGM(16'h0009, CMD_ALU_R(OP_SUB, R16, R17));
        SET_PGM(16'h000a, CMD_LDL(R16, 8'hfb)); SET_PGM(16'h000b, CMD_LDL(R17, 8'hf9)); SET_PGM(16'h000c, CMD_ALU_R(OP_SUB, R16, R17));
        SET_PGM(16'h000d, CMD_LDL(R16, 8'h00)); SET_PGM(16'h000e, CMD_LDL(R17, 8'h00)); SET_PGM(16'h000f, CMD_ALU_R(OP_SUB, R16, R17));
        GEN_RST();
        VER_ALU(R16, 8'hfe, 8'h05, 16'h0003);
        VER_ALU(R16, 8'h0c, 8'h05, 16'h0006);
        VER_ALU(R16, 8'hf4, 8'h04, 16'h0009);
        VER_ALU(R16, 8'h02, 8'h04, 16'h000c);
        VER_ALU(R16, 8'h00, 8'h06, 16'h000f);
        PRINT_RESULT("SUB", 5);
    end
endtask

task TEST_SUBL;
    begin
        CLEAR_PGM();
        SET_PGM(16'h0001, CMD_LDL(R16, 8'h05)); SET_PGM(16'h0002, CMD_ALU_L(OP_SUB, R16, 8'h07));
        SET_PGM(16'h0003, CMD_LDL(R16, 8'h05)); SET_PGM(16'h0004, CMD_ALU_L(OP_SUB, R16, 8'hf9));
        SET_PGM(16'h0005, CMD_LDL(R16, 8'hfb)); SET_PGM(16'h0006, CMD_ALU_L(OP_SUB, R16, 8'h07));
        SET_PGM(16'h0007, CMD_LDL(R16, 8'hfb)); SET_PGM(16'h0008, CMD_ALU_L(OP_SUB, R16, 8'hf9));
        SET_PGM(16'h0009, CMD_LDL(R16, 8'h00)); SET_PGM(16'h000a, CMD_ALU_L(OP_SUB, R16, 8'h00));
        GEN_RST();
        VER_ALU(R16, 8'hfe, 8'h05, 16'h0002);
        VER_ALU(R16, 8'h0c, 8'h05, 16'h0004);
        VER_ALU(R16, 8'hf4, 8'h04, 16'h0006);
        VER_ALU(R16, 8'h02, 8'h04, 16'h0008);
        VER_ALU(R16, 8'h00, 8'h06, 16'h000a);
        PRINT_RESULT("SUBL", 5);
    end
endtask

task TEST_OR_AND;
    begin
        CLEAR_PGM();
        SET_PGM(16'h0001, CMD_LDL(R16, 8'h00)); SET_PGM(16'h0002, CMD_LDL(R17, 8'h00)); SET_PGM(16'h0003, CMD_ALU_R(OP_OR, R16, R17));
        SET_PGM(16'h0004, CMD_LDL(R16, 8'h00)); SET_PGM(16'h0005, CMD_LDL(R17, 8'h0f)); SET_PGM(16'h0006, CMD_ALU_R(OP_OR, R16, R17));
        SET_PGM(16'h0007, CMD_LDL(R16, 8'h00)); SET_PGM(16'h0008, CMD_LDL(R17, 8'hf0)); SET_PGM(16'h0009, CMD_ALU_R(OP_OR, R16, R17));
        SET_PGM(16'h000a, CMD_LDL(R16, 8'h00)); SET_PGM(16'h000b, CMD_LDL(R17, 8'hff)); SET_PGM(16'h000c, CMD_ALU_R(OP_OR, R16, R17));
        GEN_RST();
        VER_ALU(R16, 8'h00, 8'h06, 16'h0003);
        VER_ALU(R16, 8'h0f, 8'h04, 16'h0006);
        VER_ALU(R16, 8'hf0, 8'h04, 16'h0009);
        VER_ALU(R16, 8'hff, 8'h04, 16'h000c);
        PRINT_RESULT("OR", 4);

        CLEAR_PGM();
        SET_PGM(16'h0001, CMD_LDL(R16, 8'hff)); SET_PGM(16'h0002, CMD_LDL(R17, 8'h00)); SET_PGM(16'h0003, CMD_ALU_R(OP_AND, R16, R17));
        SET_PGM(16'h0004, CMD_LDL(R16, 8'hff)); SET_PGM(16'h0005, CMD_LDL(R17, 8'h0f)); SET_PGM(16'h0006, CMD_ALU_R(OP_AND, R16, R17));
        SET_PGM(16'h0007, CMD_LDL(R16, 8'hff)); SET_PGM(16'h0008, CMD_LDL(R17, 8'hf0)); SET_PGM(16'h0009, CMD_ALU_R(OP_AND, R16, R17));
        SET_PGM(16'h000a, CMD_LDL(R16, 8'hff)); SET_PGM(16'h000b, CMD_LDL(R17, 8'hff)); SET_PGM(16'h000c, CMD_ALU_R(OP_AND, R16, R17));
        GEN_RST();
        VER_ALU(R16, 8'h00, 8'h06, 16'h0003);
        VER_ALU(R16, 8'h0f, 8'h04, 16'h0006);
        VER_ALU(R16, 8'hf0, 8'h04, 16'h0009);
        VER_ALU(R16, 8'hff, 8'h04, 16'h000c);
        PRINT_RESULT("AND", 4);
    end
endtask

task TEST_INC_DEC_SHIFT;
    begin
        CLEAR_PGM();
        SET_PGM(16'h0001, CMD_LDL(R16, 8'h00)); SET_PGM(16'h0002, CMD_ALU_L(OP_INC, R16, 8'h00));
        SET_PGM(16'h0003, CMD_LDL(R16, 8'h7f)); SET_PGM(16'h0004, CMD_ALU_L(OP_INC, R16, 8'h00));
        SET_PGM(16'h0005, CMD_ALU_L(OP_INC, R16, 8'h00));
        SET_PGM(16'h0006, CMD_LDL(R16, 8'hff)); SET_PGM(16'h0007, CMD_ALU_L(OP_INC, R16, 8'h00));
        GEN_RST();
        VER_ALU(R16, 8'h01, 8'h04, 16'h0002);
        VER_ALU(R16, 8'h80, 8'h04, 16'h0004);
        VER_ALU(R16, 8'h81, 8'h04, 16'h0005);
        VER_ALU(R16, 8'h00, 8'h07, 16'h0007);
        PRINT_RESULT("INC", 4);

        CLEAR_PGM();
        SET_PGM(16'h0001, CMD_LDL(R16, 8'h01)); SET_PGM(16'h0002, CMD_ALU_L(OP_DEC, R16, 8'h00));
        SET_PGM(16'h0003, CMD_ALU_L(OP_DEC, R16, 8'h00));
        SET_PGM(16'h0004, CMD_LDL(R16, 8'h81)); SET_PGM(16'h0005, CMD_ALU_L(OP_DEC, R16, 8'h00));
        SET_PGM(16'h0006, CMD_ALU_L(OP_DEC, R16, 8'h00));
        GEN_RST();
        VER_ALU(R16, 8'h00, 8'h06, 16'h0002);
        VER_ALU(R16, 8'hff, 8'h05, 16'h0003);
        VER_ALU(R16, 8'h80, 8'h04, 16'h0005);
        VER_ALU(R16, 8'h7f, 8'h04, 16'h0006);
        PRINT_RESULT("DEC", 4);

        CLEAR_PGM();
        SET_PGM(16'h0001, CMD_LDL(R0, 8'hff)); SET_PGM(16'h0002, CMD_SHIFT(OP_LSR, R0, 3'd0));
        SET_PGM(16'h0003, CMD_LDL(R0, 8'hff)); SET_PGM(16'h0004, CMD_SHIFT(OP_LSR, R0, 3'd1));
        SET_PGM(16'h0005, CMD_LDL(R0, 8'hff)); SET_PGM(16'h0006, CMD_SHIFT(OP_LSR, R0, 3'd2));
        SET_PGM(16'h0007, CMD_LDL(R0, 8'hff)); SET_PGM(16'h0008, CMD_SHIFT(OP_LSR, R0, 3'd3));
        SET_PGM(16'h0009, CMD_LDL(R0, 8'hff)); SET_PGM(16'h000a, CMD_SHIFT(OP_LSR, R0, 3'd4));
        SET_PGM(16'h000b, CMD_LDL(R0, 8'hff)); SET_PGM(16'h000c, CMD_SHIFT(OP_LSR, R0, 3'd5));
        SET_PGM(16'h000d, CMD_LDL(R0, 8'hff)); SET_PGM(16'h000e, CMD_SHIFT(OP_LSR, R0, 3'd6));
        SET_PGM(16'h000f, CMD_LDL(R0, 8'hfe)); SET_PGM(16'h0010, CMD_SHIFT(OP_LSR, R0, 3'd7));
        GEN_RST();
        VER_ALU(R0, 8'hff, 8'h04, 16'h0002);
        VER_ALU(R0, 8'hfe, 8'h04, 16'h0004);
        VER_ALU(R0, 8'hfc, 8'h04, 16'h0006);
        VER_ALU(R0, 8'hf8, 8'h04, 16'h0008);
        VER_ALU(R0, 8'hf0, 8'h04, 16'h000a);
        VER_ALU(R0, 8'he0, 8'h04, 16'h000c);
        VER_ALU(R0, 8'hc0, 8'h04, 16'h000e);
        VER_ALU(R0, 8'h00, 8'h06, 16'h0010);
        PRINT_RESULT("LSR", 8);

        CLEAR_PGM();
        SET_PGM(16'h0001, CMD_LDL(R0, 8'hff)); SET_PGM(16'h0002, CMD_SHIFT(OP_RSR, R0, 3'd0));
        SET_PGM(16'h0003, CMD_LDL(R0, 8'hff)); SET_PGM(16'h0004, CMD_SHIFT(OP_RSR, R0, 3'd1));
        SET_PGM(16'h0005, CMD_LDL(R0, 8'hff)); SET_PGM(16'h0006, CMD_SHIFT(OP_RSR, R0, 3'd2));
        SET_PGM(16'h0007, CMD_LDL(R0, 8'hff)); SET_PGM(16'h0008, CMD_SHIFT(OP_RSR, R0, 3'd3));
        SET_PGM(16'h0009, CMD_LDL(R0, 8'hff)); SET_PGM(16'h000a, CMD_SHIFT(OP_RSR, R0, 3'd4));
        SET_PGM(16'h000b, CMD_LDL(R0, 8'hff)); SET_PGM(16'h000c, CMD_SHIFT(OP_RSR, R0, 3'd5));
        SET_PGM(16'h000d, CMD_LDL(R0, 8'hff)); SET_PGM(16'h000e, CMD_SHIFT(OP_RSR, R0, 3'd6));
        SET_PGM(16'h000f, CMD_LDL(R0, 8'h40)); SET_PGM(16'h0010, CMD_SHIFT(OP_RSR, R0, 3'd7));
        GEN_RST();
        VER_ALU(R0, 8'hff, 8'h04, 16'h0002);
        VER_ALU(R0, 8'h7f, 8'h04, 16'h0004);
        VER_ALU(R0, 8'h3f, 8'h04, 16'h0006);
        VER_ALU(R0, 8'h1f, 8'h04, 16'h0008);
        VER_ALU(R0, 8'h0f, 8'h04, 16'h000a);
        VER_ALU(R0, 8'h07, 8'h04, 16'h000c);
        VER_ALU(R0, 8'h03, 8'h04, 16'h000e);
        VER_ALU(R0, 8'h00, 8'h06, 16'h0010);
        PRINT_RESULT("RSR", 8);
    end
endtask

task BUILD_INIT_R0_R7;
    begin
        SET_PGM(16'h0001, CMD_LDL(R0, 8'h01));
        SET_PGM(16'h0002, CMD_LDL(R1, 8'h02));
        SET_PGM(16'h0003, CMD_LDL(R2, 8'h04));
        SET_PGM(16'h0004, CMD_LDL(R3, 8'h08));
        SET_PGM(16'h0005, CMD_LDL(R4, 8'h10));
        SET_PGM(16'h0006, CMD_LDL(R5, 8'h20));
        SET_PGM(16'h0007, CMD_LDL(R6, 8'h40));
        SET_PGM(16'h0008, CMD_LDL(R7, 8'h80));
    end
endtask

task TEST_MEM;
    begin
        CLEAR_PGM();
        SET_PGM(16'h0001, CMD_LDL(XH, 8'h00));
        SET_PGM(16'h0002, CMD_LDL(XL, 8'h00));
        SET_PGM(16'h0003, CMD_STL(MODE_X, 8'h01)); SET_PGM(16'h0004, CMD_ALU_L(OP_INC, XL, 8'h00));
        SET_PGM(16'h0005, CMD_STL(MODE_X, 8'h02)); SET_PGM(16'h0006, CMD_ALU_L(OP_INC, XL, 8'h00));
        SET_PGM(16'h0007, CMD_STL(MODE_X, 8'h04)); SET_PGM(16'h0008, CMD_ALU_L(OP_INC, XL, 8'h00));
        SET_PGM(16'h0009, CMD_STL(MODE_X, 8'h08)); SET_PGM(16'h000a, CMD_ALU_L(OP_INC, XL, 8'h00));
        SET_PGM(16'h000b, CMD_STL(MODE_X, 8'h10)); SET_PGM(16'h000c, CMD_ALU_L(OP_INC, XL, 8'h00));
        SET_PGM(16'h000d, CMD_STL(MODE_X, 8'h20)); SET_PGM(16'h000e, CMD_ALU_L(OP_INC, XL, 8'h00));
        SET_PGM(16'h000f, CMD_STL(MODE_X, 8'h40)); SET_PGM(16'h0010, CMD_ALU_L(OP_INC, XL, 8'h00));
        SET_PGM(16'h0011, CMD_STL(MODE_X, 8'h80));
        GEN_RST();
        INST_DONE(16'h0001); INST_DONE(16'h0002);
        VER_MEM(16'h0000, 8'h01, 16'h0003);
        VER_MEM(16'h0001, 8'h02, 16'h0005);
        VER_MEM(16'h0002, 8'h04, 16'h0007);
        VER_MEM(16'h0003, 8'h08, 16'h0009);
        VER_MEM(16'h0004, 8'h10, 16'h000b);
        VER_MEM(16'h0005, 8'h20, 16'h000d);
        VER_MEM(16'h0006, 8'h40, 16'h000f);
        VER_MEM(16'h0007, 8'h80, 16'h0011);
        PRINT_RESULT("STL_X", 8);

        CLEAR_PGM();
        SET_PGM(16'h0001, CMD_LDL(XH, 8'h00));
        SET_PGM(16'h0002, CMD_LDL(XL, 8'h00));
        SET_PGM(16'h0003, CMD_STL(MODE_XP, 8'h01));
        SET_PGM(16'h0004, CMD_STL(MODE_XP, 8'h02));
        SET_PGM(16'h0005, CMD_STL(MODE_XP, 8'h04));
        SET_PGM(16'h0006, CMD_STL(MODE_XP, 8'h08));
        SET_PGM(16'h0007, CMD_STL(MODE_XP, 8'h10));
        SET_PGM(16'h0008, CMD_STL(MODE_XP, 8'h20));
        SET_PGM(16'h0009, CMD_STL(MODE_XP, 8'h40));
        SET_PGM(16'h000a, CMD_STL(MODE_XP, 8'h80));
        GEN_RST();
        INST_DONE(16'h0001); INST_DONE(16'h0002);
        VER_MEM(16'h0000, 8'h01, 16'h0003);
        VER_MEM(16'h0001, 8'h02, 16'h0004);
        VER_MEM(16'h0002, 8'h04, 16'h0005);
        VER_MEM(16'h0003, 8'h08, 16'h0006);
        VER_MEM(16'h0004, 8'h10, 16'h0007);
        VER_MEM(16'h0005, 8'h20, 16'h0008);
        VER_MEM(16'h0006, 8'h40, 16'h0009);
        VER_MEM(16'h0007, 8'h80, 16'h000a);
        VER_REGFILE_NOW(XL, 8'h08);
        PRINT_RESULT("STL_X_PLUS", 9);

        CLEAR_PGM();
        SET_PGM(16'h0001, CMD_LDL(XH, 8'h00)); SET_PGM(16'h0002, CMD_LDL(XL, 8'h00));
        SET_PGM(16'h0003, CMD_STL(MODE_XP, 8'h01)); SET_PGM(16'h0004, CMD_STL(MODE_XP, 8'h02));
        SET_PGM(16'h0005, CMD_STL(MODE_XP, 8'h04)); SET_PGM(16'h0006, CMD_STL(MODE_XP, 8'h08));
        SET_PGM(16'h0007, CMD_STL(MODE_XP, 8'h10)); SET_PGM(16'h0008, CMD_STL(MODE_XP, 8'h20));
        SET_PGM(16'h0009, CMD_STL(MODE_XP, 8'h40)); SET_PGM(16'h000a, CMD_STL(MODE_XP, 8'h80));
        SET_PGM(16'h000b, CMD_LDL(XH, 8'h00)); SET_PGM(16'h000c, CMD_LDL(XL, 8'h00));
        SET_PGM(16'h000d, CMD_LD(R0, MODE_XP));
        SET_PGM(16'h000e, CMD_LD(R1, MODE_XP));
        SET_PGM(16'h000f, CMD_LD(R2, MODE_XP));
        SET_PGM(16'h0010, CMD_LD(R3, MODE_XP));
        SET_PGM(16'h0011, CMD_LD(R4, MODE_XP));
        SET_PGM(16'h0012, CMD_LD(R5, MODE_XP));
        SET_PGM(16'h0013, CMD_LD(R6, MODE_XP));
        SET_PGM(16'h0014, CMD_LD(R7, MODE_XP));
        GEN_RST();
        INST_DONE(16'h000b); INST_DONE(16'h000c);
        VER_REGFILE(R0, 8'h01, 16'h000d);
        VER_REGFILE(R1, 8'h02, 16'h000e);
        VER_REGFILE(R2, 8'h04, 16'h000f);
        VER_REGFILE(R3, 8'h08, 16'h0010);
        VER_REGFILE(R4, 8'h10, 16'h0011);
        VER_REGFILE(R5, 8'h20, 16'h0012);
        VER_REGFILE(R6, 8'h40, 16'h0013);
        VER_REGFILE(R7, 8'h80, 16'h0014);
        PRINT_RESULT("LD_X_PLUS", 8);
    end
endtask

task TEST_JUMPS;
    begin
        CLEAR_PGM();
        SET_PGM(16'h0001, CMD_JMP(16'h0004));
        SET_PGM(16'h0002, CMD_LDL(R4, 8'haa));
        SET_PGM(16'h0003, CMD_LDL(R4, 8'hbb));
        SET_PGM(16'h0004, CMD_LDL(R4, 8'h55));
        GEN_RST();
        INST_DONE(16'h0001);
        VER_REGFILE(R4, 8'h55, 16'h0004);
        PRINT_RESULT("JMP", 1);

        CLEAR_PGM();
        SET_PGM(16'h0001, CMD_LDL(R5, 8'h01));
        SET_PGM(16'h0002, CMD_ALU_L(OP_SUB, R5, 8'h01));
        SET_PGM(16'h0003, CMD_JMPS(FLAG_Z, 1'b1, 16'h0001));
        SET_PGM(16'h0004, CMD_LDL(R0, 8'haa));
        SET_PGM(16'h0005, CMD_LDL(R0, 8'h55));
        GEN_RST();
        INST_DONE(16'h0001);
        VER_ALU(R5, 8'h00, 8'h06, 16'h0002);
        VER_REGFILE(R0, 8'h55, 16'h0005);
        PRINT_RESULT("JMPS_Z_SET", 2);

        CLEAR_PGM();
        SET_PGM(16'h0001, CMD_LDL(R0, 8'h00));
        SET_PGM(16'h0002, CMD_ALU_L(OP_SUB, R0, 8'h01));
        SET_PGM(16'h0003, CMD_JMPS(FLAG_C, 1'b1, 16'h0001));
        SET_PGM(16'h0004, CMD_LDL(R1, 8'haa));
        SET_PGM(16'h0005, CMD_LDL(R1, 8'h55));
        GEN_RST();
        VER_ALU(R0, 8'hff, 8'h05, 16'h0002);
        VER_REGFILE(R1, 8'h55, 16'h0005);
        PRINT_RESULT("JMPC_C_SET", 2);
    end
endtask

// ------------------------------------------------------------
// Main sequence
// ------------------------------------------------------------
initial begin
    $dumpfile("CW_CPU_CORE_TB.vcd");
    $dumpvars(0, CW_CPU_CORE_TB);

    SUCCESS_TEST_COUNT = 0;
    TOTAL_SUCCESS_COUNT = 0;
    ERROR_TEST_COUNT = 0;
    TOTAL_TEST_COUNT = 0;
    SUCCESS = 0;

    CLEAR_PGM();
    RST           = 1'b1;
    PROC_S_EX_REQ = 1'b0;
    PROC_S_ADDR   = 6'h00;
    PROC_S_CMD    = STI_RD;
    PROC_S_D_WR   = 8'h00;
    IADDR         = 16'h0010;
    SET_IRQ       = 1'b0;

    $display("------------------------------------------------------------");
    $display("CW_CPU_CORE_TB: Kudryashov variant, generated commands");
    $display("------------------------------------------------------------");

    TEST_LDL();
    TEST_ADD();
    TEST_ADDL();
    TEST_SUB();
    TEST_SUBL();
    TEST_OR_AND();
    TEST_INC_DEC_SHIFT();
    TEST_MEM();
    TEST_JUMPS();

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

    #100;
    $stop;
end

endmodule
