`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Testbench: CW_TOP_TB
// Variant  : Kudryashov D.S.
// Engineer : Ilyasov A.E.
// Purpose  : End-to-end check of CW_TOP with the assembled program in prg_mem.mem.
//////////////////////////////////////////////////////////////////////////////////

module CW_TOP_TB;

    reg CLK_48;
    reg SYS_NRST;

    wire N_ST;
    wire [7:0] COL_R_;
    wire [7:0] COL_G_;
    wire [7:0] COL_B_;
    wire [7:0] ROW;
    wire [7:0] AN;
    wire [7:0] CAT;

    reg [7:0] SW_A_VALUE;
    reg [7:0] SW_B_VALUE;

    reg BTN_0;
    reg BTN_1;
    reg BTN_2;
    reg BTN_3;

    wire LED_0;
    wire LED_1;
    wire LED_2;
    wire LED_3;
    wire LED_4;
    wire LED_5;
    wire LED_6;
    wire LED_7;
    wire LED_8;
    wire LED_9;
    wire LED_A;
    wire LED_B;
    wire LED_C;
    wire LED_D;
    wire LED_E;
    wire LED_F;

    localparam PERIOD_CLK = 20.8;
    localparam IDLE_PC    = 16'h0038;

    integer CHECKS;
    integer ERRORS;

    always begin
        CLK_48 = 1'b0;
        #(PERIOD_CLK / 2.0);
        CLK_48 = 1'b1;
        #(PERIOD_CLK / 2.0);
    end

    CW_TOP dut (
        .CLK_48  (CLK_48),
        .SYS_NRST(SYS_NRST),
        .N_ST    (N_ST),

        .COL_R_(COL_R_),
        .COL_G_(COL_G_),
        .COL_B_(COL_B_),
        .ROW   (ROW),

        .AN (AN),
        .CAT(CAT),

        .SW_0(SW_B_VALUE[0]),
        .SW_1(SW_B_VALUE[1]),
        .SW_2(SW_B_VALUE[2]),
        .SW_3(SW_B_VALUE[3]),
        .SW_4(SW_B_VALUE[4]),
        .SW_5(SW_B_VALUE[5]),
        .SW_6(SW_B_VALUE[6]),
        .SW_7(SW_B_VALUE[7]),
        .SW_8(SW_A_VALUE[0]),
        .SW_9(SW_A_VALUE[1]),
        .SW_A(SW_A_VALUE[2]),
        .SW_B(SW_A_VALUE[3]),
        .SW_C(SW_A_VALUE[4]),
        .SW_D(SW_A_VALUE[5]),
        .SW_E(SW_A_VALUE[6]),
        .SW_F(SW_A_VALUE[7]),

        .BTN_0(BTN_0),
        .BTN_1(BTN_1),
        .BTN_2(BTN_2),
        .BTN_3(BTN_3),

        .LED_0(LED_0),
        .LED_1(LED_1),
        .LED_2(LED_2),
        .LED_3(LED_3),
        .LED_4(LED_4),
        .LED_5(LED_5),
        .LED_6(LED_6),
        .LED_7(LED_7),
        .LED_8(LED_8),
        .LED_9(LED_9),
        .LED_A(LED_A),
        .LED_B(LED_B),
        .LED_C(LED_C),
        .LED_D(LED_D),
        .LED_E(LED_E),
        .LED_F(LED_F)
    );

    // Speed up CE_1kHz generation for button-filter simulation.
    defparam dut.cw_divider.MOD = 4;
    defparam dut.cw_divider_cascade.MOD = 2;

    function [7:0] seg_byte;
        input integer idx;
        begin
            case (idx)
                0: seg_byte = dut.cw_7seg_cntrl.HEX_IN[31:24];
                1: seg_byte = dut.cw_7seg_cntrl.HEX_IN[23:16];
                2: seg_byte = dut.cw_7seg_cntrl.HEX_IN[15:8];
                3: seg_byte = dut.cw_7seg_cntrl.HEX_IN[7:0];
                default: seg_byte = 8'hxx;
            endcase
        end
    endfunction

    task check8;
        input [8*48-1:0] name;
        input [7:0] actual;
        input [7:0] expected;
        begin
            CHECKS = CHECKS + 1;
            if (actual === expected) begin
                $display("PASS: %0s = %02h", name, actual);
            end else begin
                ERRORS = ERRORS + 1;
                $display("FAIL: %0s expected=%02h actual=%02h", name, expected, actual);
            end
        end
    endtask

    task check4;
        input [8*48-1:0] name;
        input [3:0] actual;
        input [3:0] expected;
        begin
            CHECKS = CHECKS + 1;
            if (actual === expected) begin
                $display("PASS: %0s = %01h", name, actual);
            end else begin
                ERRORS = ERRORS + 1;
                $display("FAIL: %0s expected=%01h actual=%01h", name, expected, actual);
            end
        end
    endtask

    task wait_idle;
        integer guard;
        begin
            guard = 0;
            while ((dut.cw_cpu_core.u_pc.PC !== IDLE_PC) && (guard < 20000)) begin
                @(posedge CLK_48);
                guard = guard + 1;
            end

            if (guard >= 20000) begin
                ERRORS = ERRORS + 1;
                $display("FAIL: timeout waiting for idle PC=%04h, current PC=%04h",
                         IDLE_PC, dut.cw_cpu_core.u_pc.PC);
            end

            repeat (20) @(posedge CLK_48);
        end
    endtask

    task set_btn;
        input integer idx;
        input value;
        begin
            case (idx)
                0: BTN_0 = value;
                1: BTN_1 = value;
                2: BTN_2 = value;
                3: BTN_3 = value;
            endcase
        end
    endtask

    task wait_irq_flag_value;
        input integer idx;
        input value;
        integer guard;
        begin
            guard = 0;
            case (idx)
                0: while ((dut.cw_irq_monitor.irq_flag[0] !== value) && (guard < 20000)) begin @(posedge CLK_48); guard = guard + 1; end
                1: while ((dut.cw_irq_monitor.irq_flag[1] !== value) && (guard < 20000)) begin @(posedge CLK_48); guard = guard + 1; end
                2: while ((dut.cw_irq_monitor.irq_flag[2] !== value) && (guard < 20000)) begin @(posedge CLK_48); guard = guard + 1; end
                3: while ((dut.cw_irq_monitor.irq_flag[3] !== value) && (guard < 20000)) begin @(posedge CLK_48); guard = guard + 1; end
            endcase

            if (guard >= 20000) begin
                ERRORS = ERRORS + 1;
                $display("FAIL: timeout waiting BTN%0d irq_flag=%0d", idx, value);
            end
        end
    endtask

    task wait_btn_filter_value;
        input integer idx;
        input value;
        integer guard;
        begin
            guard = 0;
            case (idx)
                0: while ((dut.cw_irq_monitor.u_btn_filter_0.BTN_OUT !== value) && (guard < 20000)) begin @(posedge CLK_48); guard = guard + 1; end
                1: while ((dut.cw_irq_monitor.u_btn_filter_1.BTN_OUT !== value) && (guard < 20000)) begin @(posedge CLK_48); guard = guard + 1; end
                2: while ((dut.cw_irq_monitor.u_btn_filter_2.BTN_OUT !== value) && (guard < 20000)) begin @(posedge CLK_48); guard = guard + 1; end
                3: while ((dut.cw_irq_monitor.u_btn_filter_3.BTN_OUT !== value) && (guard < 20000)) begin @(posedge CLK_48); guard = guard + 1; end
            endcase

            if (guard >= 20000) begin
                ERRORS = ERRORS + 1;
                $display("FAIL: timeout waiting BTN%0d filter=%0d", idx, value);
            end
        end
    endtask

    task press_btn;
        input integer idx;
        begin
            wait_btn_filter_value(idx, 1'b0);
            set_btn(idx, 1'b1);
            wait_irq_flag_value(idx, 1'b1);
            wait_btn_filter_value(idx, 1'b1);
            set_btn(idx, 1'b0);
            wait_irq_flag_value(idx, 1'b0);
            wait_btn_filter_value(idx, 1'b0);
            wait_idle();
        end
    endtask

    task set_operands;
        input [7:0] operand_a;
        input [7:0] operand_b;
        begin
            SW_A_VALUE = operand_a;
            SW_B_VALUE = operand_b;
            repeat (5) @(posedge CLK_48);
        end
    endtask

    task check_default_state;
        begin
            check8("mode state", dut.cw_reg_sti.OUT[7:0], 8'h00);
            check8("7seg mode", seg_byte(0), 8'h00);
            check8("7seg operand A", seg_byte(1), 8'h00);
            check8("7seg operand B", seg_byte(2), 8'h00);
            check8("7seg result", seg_byte(3), 8'h00);
            check8("7seg blank", dut.cw_7seg_cntrl.BLANK, 8'h00);
            check4("matrix initial symbol", dut.cw_rgb_matrix_cntrl.DATA_HEX, 4'he);
            check8("red initial", dut.cw_rgb_matrix_cntrl.PWM_R, 8'h20);
            check8("green initial", dut.cw_rgb_matrix_cntrl.PWM_G, 8'h20);
            check8("blue initial", dut.cw_rgb_matrix_cntrl.PWM_B, 8'h20);
            check8("IRQ mask", {4'h0, dut.cw_irq_monitor.mirq}, 8'h0f);
        end
    endtask

    initial begin
        $dumpfile("CW_TOP_TB.vcd");
        $dumpvars(0, CW_TOP_TB);

        CHECKS = 0;
        ERRORS = 0;
        SYS_NRST = 1'b0;
        SW_A_VALUE = 8'h00;
        SW_B_VALUE = 8'h00;
        BTN_0 = 1'b0;
        BTN_1 = 1'b0;
        BTN_2 = 1'b0;
        BTN_3 = 1'b0;

        repeat (10) @(posedge CLK_48);
        SYS_NRST = 1'b1;

        wait_idle();
        $display("------------------------------------------------------------");
        $display("CW_TOP_TB: Kudryashov program");
        $display("------------------------------------------------------------");

        check_default_state();

        // Mode 0: A - B, display mode | A | B | result.
        set_operands(8'h12, 8'h05);
        press_btn(1);
        check8("mode0 7seg A", seg_byte(1), 8'h12);
        press_btn(2);
        check8("mode0 7seg B", seg_byte(2), 8'h05);
        press_btn(3);
        check8("mode0 result A-B", seg_byte(3), 8'h0d);

        // Mode 1: A + B.
        press_btn(0);
        check8("mode1 7seg mode", seg_byte(0), 8'h01);
        set_operands(8'h0a, 8'h07);
        press_btn(1);
        press_btn(2);
        press_btn(3);
        check8("mode1 result A+B", seg_byte(3), 8'h11);

        // Mode 2: middle pairs are off, right pair shows sequence symbol.
        press_btn(0);
        check8("mode2 7seg mode", seg_byte(0), 8'h02);
        check8("mode2 blank mask", dut.cw_7seg_cntrl.BLANK, 8'h3c);
        check8("mode2 current symbol", seg_byte(3), 8'h0e);
        press_btn(3);
        check4("mode2 matrix symbol E->1", dut.cw_rgb_matrix_cntrl.DATA_HEX, 4'h1);
        check8("mode2 7seg symbol E->1", seg_byte(3), 8'h01);
        press_btn(3);
        check4("mode2 matrix symbol 1->B", dut.cw_rgb_matrix_cntrl.DATA_HEX, 4'hb);
        check8("mode2 7seg symbol 1->B", seg_byte(3), 8'h0b);

        // Mode 3: A OR B.
        press_btn(0);
        check8("mode3 blank mask", dut.cw_7seg_cntrl.BLANK, 8'h00);
        set_operands(8'h50, 8'h0f);
        press_btn(1);
        press_btn(2);
        press_btn(3);
        check8("mode3 result A OR B", seg_byte(3), 8'h5f);

        // Mode 4: display mode | R | G | B and increase color by 9.
        press_btn(0);
        check8("mode4 7seg mode", seg_byte(0), 8'h04);
        check8("mode4 7seg R initial", seg_byte(1), 8'h20);
        check8("mode4 7seg G initial", seg_byte(2), 8'h20);
        check8("mode4 7seg B initial", seg_byte(3), 8'h20);
        press_btn(1);
        check8("mode4 red PWM", dut.cw_rgb_matrix_cntrl.PWM_R, 8'h29);
        check8("mode4 7seg R", seg_byte(1), 8'h29);
        press_btn(2);
        check8("mode4 green PWM", dut.cw_rgb_matrix_cntrl.PWM_G, 8'h29);
        check8("mode4 7seg G", seg_byte(2), 8'h29);
        press_btn(3);
        check8("mode4 blue PWM", dut.cw_rgb_matrix_cntrl.PWM_B, 8'h29);
        check8("mode4 7seg B", seg_byte(3), 8'h29);

        // Mode 5: A AND B.
        press_btn(0);
        check8("mode5 7seg mode", seg_byte(0), 8'h05);
        set_operands(8'hf0, 8'h0f);
        press_btn(1);
        press_btn(2);
        press_btn(3);
        check8("mode5 result A AND B", seg_byte(3), 8'h00);

        // Wrap back to mode 0.
        press_btn(0);
        check8("mode wrap 5->0", seg_byte(0), 8'h00);

        $display("------------------------------------------------------------");
        $display("CW_TOP_TB CHECKS = %0d", CHECKS);
        $display("CW_TOP_TB ERRORS = %0d", ERRORS);
        $display("------------------------------------------------------------");

        if (ERRORS == 0) begin
            $display("CW_TOP_TB PASSED");
        end else begin
            $display("CW_TOP_TB FAILED");
        end

        #100;
        $finish;
    end

endmodule