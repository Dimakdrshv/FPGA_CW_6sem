`timescale 1ns / 1ps

module CW_CTRL_FSM (
    input wire CLK,
    input wire RST,

    input wire [31:0] PGMD,

    input wire MEM,
    input wire MEM_DONE,

    input  wire IRQ,
    input  wire EIRQ,

    output reg [31:0] CMD,
    output reg [3:0] STAGES,
    output reg DONE,
    output reg IRQ_FLG
    );

    localparam [2:0] ST_FETCH = 3'd0,
                     ST_EXEC1 = 3'd1,
                     ST_EXEC2 = 3'd2,
                     ST_EXEC3 = 3'd3,
                     ST_EXEC4 = 3'd4;

    localparam [3:0] OP_LD = 4'b1000;
    localparam [3:0] OP_RETI = 4'b0110;
    localparam [3:0] OP_NOP = 4'b0000;

    reg [2:0] state;
    reg [2:0] next_state;

    reg [31:0] next_cmd;
    reg [3:0] next_stages;
    reg next_done;
    reg next_irq_flg;

    wire [3:0] command = CMD[31:28];
    wire stage_done = ~MEM | MEM_DONE;

    always @(*) begin
        next_state = state;
        next_cmd = CMD;
        next_stages = STAGES;
        next_done = 1'b0;
        next_irq_flg = IRQ_FLG;

        case (state)
            ST_FETCH: begin
                next_stages = 4'b0000;

                if (IRQ && EIRQ) begin
                    next_cmd = {OP_NOP, 28'h0000000};
                    next_irq_flg = 1'b1;
                    next_stages = 4'b0001;
                    next_state = ST_EXEC1;
                end else begin
                    next_cmd = PGMD;
                    next_irq_flg = 1'b0;
                    next_stages = 4'b0001;
                    next_state = ST_EXEC1;
                end
            end

            ST_EXEC1: begin
                next_stages = 4'b0001;

                if (stage_done) begin
                    if (IRQ_FLG || (command == OP_LD) || (command == OP_RETI)) begin
                        next_stages = 4'b0010;
                        next_state = ST_EXEC2;
                    end else begin
                        next_done = 1'b1;
                        next_stages = 4'b0000;
                        next_state = ST_FETCH;
                    end
                end
            end

            ST_EXEC2: begin
                next_stages = 4'b0010;

                if (stage_done) begin
                    if (IRQ_FLG || (command == OP_RETI)) begin
                        next_stages = 4'b0100;
                        next_state = ST_EXEC3;
                    end else begin
                        next_done = 1'b1;
                        next_stages = 4'b0000;
                        next_state = ST_FETCH;
                    end
                end
            end

            ST_EXEC3: begin
                next_stages = 4'b0100;

                if (stage_done) begin
                    next_stages = 4'b1000;
                    next_state = ST_EXEC4;
                end
            end

            ST_EXEC4: begin
                next_stages = 4'b1000;

                if (stage_done) begin
                    next_done = 1'b1;
                    next_stages = 4'b0000;
                    next_state = ST_FETCH;
                    next_irq_flg = 1'b0;
                end
            end

            default: begin
                next_state = ST_FETCH;
                next_cmd = {OP_NOP, 28'h0000000};
                next_stages = 4'b0000;
                next_done = 1'b0;
                next_irq_flg = 1'b0;
            end
        endcase
    end

    always @(posedge CLK, posedge RST) begin
        if (RST) begin
            state <= ST_FETCH;
            CMD <= {OP_NOP, 28'h0000000};
            STAGES <= 4'b0000;
            DONE <= 1'b0;
            IRQ_FLG <= 1'b0;
        end else begin
            state <= next_state;
            CMD <= next_cmd;
            STAGES <= next_stages;
            DONE <= next_done;
            IRQ_FLG <= next_irq_flg;
        end
    end

endmodule
