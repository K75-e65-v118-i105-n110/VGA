`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/17 17:12:10
// Design Name: 
// Module Name: point_count
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


module point_count(     //计分模块
    input clk,
    input rst,
    input start,
    input [4:0] snake_len,      //蛇长
    input [3:0] food_point,     //吃到计分食物获得的
    output wire [3:0] hundreds, //百位BCD   
    output wire [3:0] tens,     //十位BCD
    output wire [3:0] ones      //个位BCD
    );

    reg [9:0] score;    //总得分
    reg [4:0] previous_snake_len;

    always @(posedge clk) begin
        if (rst | start) begin
            score <= 10'd0;
            previous_snake_len <= 5'd2;
        end else begin
            if (snake_len > previous_snake_len)     //在每次吃到食物后更新得分
                score <= score + 10'd2 + food_point;

            previous_snake_len <= snake_len;
        end
    end

    assign hundreds = score / 10'd100;
    assign tens = (score / 10'd10) % 10'd10;
    assign ones = score % 10'd10;

endmodule
