`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/17 14:22:57
// Design Name: 
// Module Name: uart_rx
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


module uart_rx #(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer BAUD   = 115_200  //波特率
) (
    input clk,
    input rst,      
    input uart_rx,
    output reg [7:0] data_out,
    output reg data_valid       //串口数据有效信号，单周期脉冲
);

    localparam integer CLKS_PER_BIT = (CLK_HZ + (BAUD / 2)) / BAUD;     
    localparam integer HALF_BIT     = CLKS_PER_BIT / 2;

    localparam [1:0] S_IDLE  = 2'd0;
    localparam [1:0] S_START = 2'd1;
    localparam [1:0] S_DATA  = 2'd2;
    localparam [1:0] S_STOP  = 2'd3;

    (* ASYNC_REG = "TRUE" *) reg [2:0] rx_sync;

    always @(posedge clk) begin
        if (rst) begin
            rx_sync <= 3'b111;
        end else begin
            rx_sync <= {rx_sync[1:0], uart_rx};
        end
    end

    wire rx_bit    = rx_sync[1];
    wire start_edge = rx_sync[2] & ~rx_sync[1];

    reg [1:0]  state;
    reg [31:0] clk_cnt;
    reg [2:0]  bit_idx;
    reg [7:0]  shift_reg;

    always @(posedge clk) begin
        if (rst) begin
            state       <= S_IDLE;
            clk_cnt     <= 32'd0;
            bit_idx     <= 3'd0;
            shift_reg   <= 8'd0;
            data_out    <= 8'd0;
            data_valid  <= 1'b0;
        end else begin
            data_valid  <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (start_edge) begin
                        state   <= S_START;
                        clk_cnt <= 32'd0;
                    end
                end

                S_START: begin
                    if (clk_cnt >= (HALF_BIT - 1)) begin
                        clk_cnt <= 32'd0;
                        if (!rx_bit) begin
                            state   <= S_DATA;
                            bit_idx <= 3'd0;
                        end else begin
                            state <= S_IDLE;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 32'd1;
                    end
                end

                S_DATA: begin
                    if (clk_cnt >= (CLKS_PER_BIT - 1)) begin
                        clk_cnt <= 32'd0;
                        shift_reg[bit_idx] <= rx_bit;
                        if (bit_idx == 3'd7) begin
                            state <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 3'd1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 32'd1;
                    end
                end

                S_STOP: begin
                    if (clk_cnt >= (CLKS_PER_BIT - 1)) begin
                        clk_cnt <= 32'd0;
                        state   <= S_IDLE;
                        if (rx_bit) begin
                            data_out   <= shift_reg;
                            data_valid <= 1'b1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 32'd1;
                    end
                end

                default: begin
                    state   <= S_IDLE;
                    clk_cnt <= 32'd0;
                end
            endcase
        end
    end

endmodule