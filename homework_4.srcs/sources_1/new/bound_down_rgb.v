`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/17 22:39:01
// Design Name: 
// Module Name: bound_down_rgb
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


module bound_down_rgb(      //底部倒计时条
    input clk,
    input [9:0] hcount,
    input [9:0] vcount,
    input [31:0] elapsed_count,
    input food_type,
    output reg [11:0] bound_down_rgb
    );

    parameter integer CLK_HZ = 100_000_000;
    localparam [9:0] BAR_X_START = 10'd143,         //显示位置相关参数
                     BAR_X_END = 10'd783,
                     BAR_Y_START = 10'd494,
                     BAR_Y_END = 10'd514,
                     BAR_INNER_WIDTH = 10'd638;
    localparam [41:0] TIME_LIMIT = CLK_HZ * 10;

    wire bar_area = (hcount > BAR_X_START) && (hcount <= BAR_X_END) &&
                    (vcount > BAR_Y_START) && (vcount <= BAR_Y_END);
    wire bar_border = (hcount == BAR_X_START + 10'd1) ||
                      (hcount == BAR_X_END) ||
                      (vcount == BAR_Y_START + 10'd1) ||
                      (vcount == BAR_Y_END);
    wire [9:0] bar_inner_x = hcount - (BAR_X_START + 10'd2);
    wire [9:0] pixels_remaining = BAR_INNER_WIDTH - bar_inner_x;
    wire [41:0] elapsed_scaled = {10'd0, elapsed_count} * 42'd638;
    wire [41:0] remaining_scaled = {32'd0, pixels_remaining} * TIME_LIMIT;

    always @(*) begin
        bound_down_rgb = 12'h000;
        if (food_type && bar_area) begin
            if (bar_border)
                bound_down_rgb = 12'h888;
            else if (elapsed_scaled < remaining_scaled)
                bound_down_rgb = 12'hF00;
        end
    end

endmodule
