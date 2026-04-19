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

module cmd_decoder 
(
    input  wire [31:0] cmd,

    // Общие признаки
    output reg         valid,
    output reg         illegal,
    output reg         nop,
    output reg         reti,

    // Регистровые поля
    output reg  [4:0]  rd_addr,
    output reg  [4:0]  rr_addr,

    // Непосредственные данные
    output reg  [7:0]  lit8,
    output reg  [15:0] k16,
    output reg  [2:0]  num3,

    // Что использует команда
    output reg         use_rd,
    output reg         use_rr,
    output reg         use_lit,
    output reg         use_k,
    output reg         use_num,

    // Запись результата
    output reg         rf_we,      // запись в регфайл

    // ALU
    output reg  [3:0]  alu_op,

    // Переходы
    output reg         jump_abs,   // JMP
    output reg         jump_s,     // JMPS
    output reg         jump_c,     // JMPC

    // Память данных
    output reg         mem_rd,     // чтение из ОЗУ
    output reg         mem_wr,     // запись в ОЗУ
    output reg         mem_addr_x, // адрес = X
    output reg         mem_addr_y, // адрес = Y
    output reg         x_post_inc, // X = X + 1 после операции
    output reg         y_post_inc, // Y = Y + 1 после операции
    output reg         mem_wdata_is_rr,   // писать в память данные из Rr
    output reg         mem_wdata_is_lit,  // писать в память литерал

    // Для удобства автомата управления
    output reg  [3:0]  instr_class
);

    // ------------------------------------------------------------
    // Локальные поля команды
    // ------------------------------------------------------------
    wire [7:0] opcode = cmd[31:24];
    wire [3:0] op_hi  = cmd[31:28];
    wire [3:0] op_lo  = cmd[27:24];

    // Часто используемые поля из форматов методички
    wire [4:0] fld_rd  = cmd[27:23]; // Rd в форматах с Rd
    wire [4:0] fld_rr  = cmd[19:15]; // Rr в форматах Rd,Rr и ST ?,Rr
    wire [7:0] fld_lit = cmd[ 7: 0];
    wire [15:0] fld_k  = cmd[15: 0];

    // Для команд с BBBx / XXB0 / XXB1
    wire [2:0] fld_num = cmd[27:25];

    // ------------------------------------------------------------
    // Коды ALU
    // По таблице "Коды операций АЛУ"
    // ------------------------------------------------------------
    localparam [3:0] ALU_PASS = 4'b0000; // ALU_RES <= OPR0
    localparam [3:0] ALU_ADD  = 4'b0001; // OPR0 + OPR1
    localparam [3:0] ALU_SUB  = 4'b0010; // OPR0 - OPR1
    localparam [3:0] ALU_OR   = 4'b0011; // OPR0 | OPR1
    localparam [3:0] ALU_AND  = 4'b0100; // OPR0 & OPR1
    localparam [3:0] ALU_LSL  = 4'b0101; // OPR0 << BT_NUM
    localparam [3:0] ALU_LSR  = 4'b0110; // OPR0 >> BT_NUM
    localparam [3:0] ALU_JMPS = 4'b0111; // условие по SREG[0]
    localparam [3:0] ALU_JMPC = 4'b1000; // условие по SREG[1]

    // ------------------------------------------------------------
    // Классы команд
    // ------------------------------------------------------------
    localparam [3:0] IC_NOP   = 4'd0;
    localparam [3:0] IC_ALU   = 4'd1;
    localparam [3:0] IC_JUMP  = 4'd2;
    localparam [3:0] IC_LOAD  = 4'd3;
    localparam [3:0] IC_STORE = 4'd4;
    localparam [3:0] IC_MISC  = 4'd5;

    // ------------------------------------------------------------
    // Комбинаторный дешифратор
    // ------------------------------------------------------------
    always @(*) begin
        // Значения по умолчанию
        valid            = 1'b1;
        illegal          = 1'b0;
        nop              = 1'b0;
        reti             = 1'b0;

        rd_addr          = 5'd0;
        rr_addr          = 5'd0;

        lit8             = fld_lit;
        k16              = fld_k;
        num3             = fld_num;

        use_rd           = 1'b0;
        use_rr           = 1'b0;
        use_lit          = 1'b0;
        use_k            = 1'b0;
        use_num          = 1'b0;

        rf_we            = 1'b0;

        alu_op           = ALU_PASS;

        jump_abs         = 1'b0;
        jump_s           = 1'b0;
        jump_c           = 1'b0;

        mem_rd           = 1'b0;
        mem_wr           = 1'b0;
        mem_addr_x       = 1'b0;
        mem_addr_y       = 1'b0;
        x_post_inc       = 1'b0;
        y_post_inc       = 1'b0;
        mem_wdata_is_rr  = 1'b0;
        mem_wdata_is_lit = 1'b0;

        instr_class      = IC_MISC;

        case (op_hi)

            // ----------------------------------------------------
            // 0000 : NOP
            // ----------------------------------------------------
            4'b0000: begin
                instr_class = IC_NOP;
                nop         = 1'b1;

                // По таблице NOP имеет opcode[27:24] = 0000
                // и DATA = 0. При желании можно строго проверить:
                if (cmd != 32'h0000_0000) begin
                    // Формально можно считать illegal, но чаще
                    // удобно оставить как NOP-класс.
                    // illegal = 1'b1;
                    // valid   = 1'b0;
                end
            end

            // ----------------------------------------------------
            // 0001 : ADD
            // 0001_0xxx -> ADD Rd, Rr
            // 0001_1xxx -> ADD Rd, lit
            // ----------------------------------------------------
            4'b0001: begin
                instr_class = IC_ALU;
                rd_addr     = fld_rd;
                use_rd      = 1'b1;
                rf_we       = 1'b1;
                alu_op      = ALU_ADD;

                if (op_lo[3] == 1'b0) begin
                    rr_addr = fld_rr;
                    use_rr  = 1'b1;
                end else begin
                    use_lit = 1'b1;
                end
            end

            // ----------------------------------------------------
            // 0010 : SUB
            // ----------------------------------------------------
            4'b0010: begin
                instr_class = IC_ALU;
                rd_addr     = fld_rd;
                use_rd      = 1'b1;
                rf_we       = 1'b1;
                alu_op      = ALU_SUB;

                if (op_lo[3] == 1'b0) begin
                    rr_addr = fld_rr;
                    use_rr  = 1'b1;
                end else begin
                    use_lit = 1'b1;
                end
            end

            // ----------------------------------------------------
            // 0011 : OR
            // ----------------------------------------------------
            4'b0011: begin
                instr_class = IC_ALU;
                rd_addr     = fld_rd;
                use_rd      = 1'b1;
                rf_we       = 1'b1;
                alu_op      = ALU_OR;

                if (op_lo[3] == 1'b0) begin
                    rr_addr = fld_rr;
                    use_rr  = 1'b1;
                end else begin
                    use_lit = 1'b1;
                end
            end

            // ----------------------------------------------------
            // 0100 : AND
            // ----------------------------------------------------
            4'b0100: begin
                instr_class = IC_ALU;
                rd_addr     = fld_rd;
                use_rd      = 1'b1;
                rf_we       = 1'b1;
                alu_op      = ALU_AND;

                if (op_lo[3] == 1'b0) begin
                    rr_addr = fld_rr;
                    use_rr  = 1'b1;
                end else begin
                    use_lit = 1'b1;
                end
            end

            // ----------------------------------------------------
            // 0101 : INC Rd
            // ----------------------------------------------------
            4'b0101: begin
                instr_class = IC_ALU;
                rd_addr     = fld_rd;
                use_rd      = 1'b1;
                rf_we       = 1'b1;
                alu_op      = ALU_ADD;
                use_lit     = 1'b1;
                lit8        = 8'd1;
            end

            // ----------------------------------------------------
            // 0110 : DEC Rd
            // ----------------------------------------------------
            4'b0110: begin
                instr_class = IC_ALU;
                rd_addr     = fld_rd;
                use_rd      = 1'b1;
                rf_we       = 1'b1;
                alu_op      = ALU_SUB;
                use_lit     = 1'b1;
                lit8        = 8'd1;
            end

            // ----------------------------------------------------
            // 0111 : LSR Rd, num   (в методичке операция влево/вправо
            // именована через LSR/RSR, здесь просто следуем кодам АЛУ)
            // Формат: 0111_BBBx
            // ----------------------------------------------------
            4'b0111: begin
                instr_class = IC_ALU;
                rd_addr     = fld_rd;
                use_rd      = 1'b1;
                use_num     = 1'b1;
                rf_we       = 1'b1;
                alu_op      = ALU_LSL;
            end

            // ----------------------------------------------------
            // 1000 : RSR Rd, num
            // Формат: 1000_BBBx
            // ----------------------------------------------------
            4'b1000: begin
                instr_class = IC_ALU;
                rd_addr     = fld_rd;
                use_rd      = 1'b1;
                use_num     = 1'b1;
                rf_we       = 1'b1;
                alu_op      = ALU_LSR;
            end

            // ----------------------------------------------------
            // 1001 : JMP k
            // ----------------------------------------------------
            4'b1001: begin
                instr_class = IC_JUMP;
                jump_abs    = 1'b1;
                use_k       = 1'b1;
            end

            // ----------------------------------------------------
            // 1010 : JMPS / JMPC
            // 1010_XXB0 -> JMPS k, num
            // 1010_XXB1 -> JMPC k, num
            // ----------------------------------------------------
            4'b1010: begin
                instr_class = IC_JUMP;
                use_k       = 1'b1;
                use_num     = 1'b1;

                if (op_lo[0] == 1'b0) begin
                    jump_s = 1'b1;
                    alu_op = ALU_JMPS;
                end else begin
                    jump_c = 1'b1;
                    alu_op = ALU_JMPC;
                end
            end

            // ----------------------------------------------------
            // 1011 : LDL / MOV
            // 1011_0xxx -> LDL Rd, lit
            // 1011_1xxx -> MOV Rd, Rr
            // ----------------------------------------------------
            4'b1011: begin
                instr_class = IC_LOAD;
                rd_addr     = fld_rd;
                use_rd      = 1'b1;
                rf_we       = 1'b1;
                alu_op      = ALU_PASS;

                if (op_lo[3] == 1'b0) begin
                    use_lit = 1'b1;    // LDL
                end else begin
                    rr_addr = fld_rr;   // MOV
                    use_rr  = 1'b1;
                end
            end

            // ----------------------------------------------------
            // 1100 : LD Rd, X / X+ / Y / Y+
            // 00xx -> X
            // 01xx -> X+
            // 10xx -> Y
            // 11xx -> Y+
            // ----------------------------------------------------
            4'b1100: begin
                instr_class = IC_LOAD;
                rd_addr     = fld_rd;
                use_rd      = 1'b1;
                rf_we       = 1'b1;
                mem_rd      = 1'b1;

                case (op_lo[3:2])
                    2'b00: begin
                        mem_addr_x = 1'b1; // LD Rd, X
                    end
                    2'b01: begin
                        mem_addr_x = 1'b1; // LD Rd, X+
                        x_post_inc = 1'b1;
                    end
                    2'b10: begin
                        mem_addr_y = 1'b1; // LD Rd, Y
                    end
                    2'b11: begin
                        mem_addr_y = 1'b1; // LD Rd, Y+
                        y_post_inc = 1'b1;
                    end
                endcase
            end

            // ----------------------------------------------------
            // 1101 : STL X,lit / X+,lit / Y,lit / Y+,lit
            // ----------------------------------------------------
            4'b1101: begin
                instr_class      = IC_STORE;
                mem_wr           = 1'b1;
                use_lit          = 1'b1;
                mem_wdata_is_lit = 1'b1;

                case (op_lo[3:2])
                    2'b00: begin
                        mem_addr_x = 1'b1; // STL X, lit
                    end
                    2'b01: begin
                        mem_addr_x = 1'b1; // STL X+, lit
                        x_post_inc = 1'b1;
                    end
                    2'b10: begin
                        mem_addr_y = 1'b1; // STL Y, lit
                    end
                    2'b11: begin
                        mem_addr_y = 1'b1; // STL Y+, lit
                        y_post_inc = 1'b1;
                    end
                endcase
            end

            // ----------------------------------------------------
            // 1110 : ST X,Rr / X+,Rr / Y,Rr / Y+,Rr
            // ----------------------------------------------------
            4'b1110: begin
                instr_class     = IC_STORE;
                rr_addr         = fld_rr;
                use_rr          = 1'b1;
                mem_wr          = 1'b1;
                mem_wdata_is_rr = 1'b1;

                case (op_lo[3:2])
                    2'b00: begin
                        mem_addr_x = 1'b1; // ST X, Rr
                    end
                    2'b01: begin
                        mem_addr_x = 1'b1; // ST X+, Rr
                        x_post_inc = 1'b1;
                    end
                    2'b10: begin
                        mem_addr_y = 1'b1; // ST Y, Rr
                    end
                    2'b11: begin
                        mem_addr_y = 1'b1; // ST Y+, Rr
                        y_post_inc = 1'b1;
                    end
                endcase
            end

            // ----------------------------------------------------
            // 1111 : RETI
            // ----------------------------------------------------
            4'b1111: begin
                instr_class = IC_MISC;
                reti        = 1'b1;
            end

            default: begin
                valid   = 1'b0;
                illegal = 1'b1;
            end
        endcase
    end

endmodule
