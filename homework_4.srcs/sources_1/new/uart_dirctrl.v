`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/17 14:22:57
// Design Name: 
// Module Name: uart_dirctrl
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


module uart_dirctrl#(
    parameter integer CLK_HZ = 100_000_000,
    parameter integer BAUD   = 115_200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       uart_rx,

    output wire       up_pulse,
    output wire       down_pulse,
    output wire       left_pulse,
    output wire       right_pulse,
    output wire       start_pulse,
    output wire       speed_ctrl
);

    wire [7:0] rx_data;
    wire       rx_valid;

    uart_rx #(
        .CLK_HZ(CLK_HZ),
        .BAUD  (BAUD)
    ) u_uart_rx (
        .clk         (clk),
        .rst       (rst),
        .uart_rx     (uart_rx),
        .data_out    (rx_data),
        .data_valid  (rx_valid)
    );

    uart_decode u_decode (
        .clk             (clk),
        .rst           (rst),
        .rx_data         (rx_data),
        .rx_valid        (rx_valid),
        .up_pulse        (up_pulse),
        .down_pulse      (down_pulse),
        .left_pulse      (left_pulse),
        .right_pulse     (right_pulse),
        .start_pulse     (start_pulse),
        .speed_ctrl      (speed_ctrl)
    );

endmodule