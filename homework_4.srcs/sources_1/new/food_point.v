`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/17 20:56:22
// Design Name: 
// Module Name: food_point
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


module food_point(
    input clk,
    input rst,
    input food_type,
    input eat,
    output reg [3:0] food_point,
    output reg fail_get,
    output reg [31:0] elapsed_count
    );

    parameter integer CLK_HZ = 100_000_000;
    localparam integer TIME_LIMIT = CLK_HZ * 10;
    localparam integer SCORE_INTERVAL = TIME_LIMIT / 10;    

    
    reg [31:0] score_interval_count;        //得分递减计时
    reg active;     //正在计时
    reg armed;      //等待启动

    always @(posedge clk) begin
        fail_get <= 1'b0;

        if (rst) begin
            elapsed_count <= 32'd0;
            score_interval_count <= 32'd0;
            food_point <= 4'd0;
            active <= 1'b0;
            armed <= 1'b1;
            fail_get <= 1'b0;
        end else if (!food_type) begin
            elapsed_count <= 32'd0;
            score_interval_count <= 32'd0;
            food_point <= 4'd0;
            active <= 1'b0;
            armed <= 1'b1;
        end else if (!active && armed) begin
            elapsed_count <= 32'd0;
            score_interval_count <= 32'd0;
            food_point <= 4'd10;
            active <= 1'b1;
            armed <= 1'b0;
        end else if (active && eat) begin
            active <= 1'b0;
            elapsed_count <= 32'd0;
            score_interval_count <= 32'd0;
        end else if (active) begin
            if (elapsed_count == TIME_LIMIT - 1) begin
                elapsed_count <= 32'd0;
                score_interval_count <= 32'd0;
                food_point <= 4'd0;
                active <= 1'b0;
                fail_get <= 1'b1;
            end else begin
                elapsed_count <= elapsed_count + 1'b1;
                if (score_interval_count == SCORE_INTERVAL - 1) begin
                    score_interval_count <= 32'd0;
                    if (food_point != 4'd0)
                        food_point <= food_point - 1'b1;
                end else begin
                    score_interval_count <= score_interval_count + 1'b1;
                end
            end
        end
    end

endmodule
