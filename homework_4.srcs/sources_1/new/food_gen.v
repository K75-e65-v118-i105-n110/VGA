`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/05 16:35:53
// Design Name: 
// Module Name: food_gen
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


module food_gen(        //食物生成
    input clk,
    input rst,
    input refresh_food,     //食物刷新信号
    input start,
    input [449:0] wall_x,
    input [449:0] wall_y,
    input [159:0] snake_x,
    input [159:0] snake_y,
    input [4:0] snake_len,       
    output reg [4:0] food_x,
    output reg [4:0] food_y,
    output reg food_type
);

    reg [15:0] lfsr;
    reg [2:0] food_count;       //已吃食物计数
    reg pending;                //坐标更新使能
    reg candidate_on;           //刷新位置是否在其他物体上
    wire feedback = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];      //lfsr随机生成食物位置
    wire [4:0] candidate_x = lfsr[4:0];
    wire [4:0] candidate_y = lfsr[9:5];

    integer i;

    always @(*) begin
        candidate_on = 1'b0;
        for (i = 0; i < 32; i = i + 1) begin
            if (i <= snake_len &&
                snake_x[i*5 +: 5] == candidate_x &&
                snake_y[i*5 +: 5] == candidate_y)
                candidate_on = 1'b1;
        end
        for (i=0; i<90; i = i + 1) begin
            if(wall_x[i*5 +: 5] == candidate_x &&
                wall_y[i*5 +: 5] == candidate_y)
                candidate_on = 1'b1;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            lfsr   <= 16'hACE1;  // 非零初值
            pending <= 1'b1;
            food_x <= 5'd5;
            food_y <= 5'd5;
            food_type <= 1'b0;
            food_count <= 3'd0;
        end else begin
            lfsr <= {lfsr[14:0], feedback};
            if(start) begin 
                food_count <= 3'd0;     
                food_type <= 1'b0;
            end
            else if (refresh_food)begin
                pending <= 1'b1;
                food_type <= 1'b0;
                if(food_count == 3'd7) begin    //每当吃8个食物后刷新计分食物
                    food_type <= 1'b1;
                    food_count <= 3'd0;
                end else food_count <= food_count + 3'd1;
            end

            if (pending || refresh_food) begin
                if (candidate_x != 0 &&         //刷新位置在其他物体上则候选无效
                    candidate_y != 0 &&
                    candidate_y < 5'd23 &&
                    candidate_x < 5'd31 &&
                    !candidate_on) begin    
                    food_x <= candidate_x;
                    food_y <= candidate_y;
                    pending <= 1'b0;
                end else begin
                    pending <= 1'b1;  // 候选无效，后续时钟继续尝试
                end
            end
        end
    end
endmodule
