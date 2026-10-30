`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/28 20:43:26
// Design Name: 
// Module Name: block_move
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


module block_move(
    input clk,
    input vsync,
    output reg [9:0] blk_x,
    output reg [9:0] blk_y
    );

    parameter SPEED = 2'd3;

    reg vsync_d1, vsync_d2;
    always @(posedge clk) begin
        vsync_d1 <= vsync;
        vsync_d2 <= vsync_d1;
    end

    // 提取下降沿，只在这个时钟周期内 frame_tick 为高电平
    wire frame_tick = (vsync_d2 == 1'b1) && (vsync_d1 == 1'b0); 

    // 使用时序逻辑（触发器）来更新坐标
    always @(posedge clk) begin
        if (frame_tick) begin
            blk_x <= blk_x + SPEED;
            blk_y <= blk_y + SPEED;
        end
    end

endmodule
