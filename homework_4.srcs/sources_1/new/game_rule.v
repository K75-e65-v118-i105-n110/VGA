`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/30 22:48:16
// Design Name: 
// Module Name: game_rule
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


module game_rule(
    input clk,
    input rst,
    input game_tick,
    input start,
    input game_pause,
    input [1:0] direc_state,
    input [449:0] wall_x,
    input [449:0] wall_y,
    output reg [159:0] snake_x,
    output reg [159:0] snake_y,
    output [4:0] food_x,
    output [4:0] food_y,
    output reg [4:0] snake_len,   //蛇长-1
    output reg game_over,
    output wire food_type,
    output wire [3:0] food_point,
    output wire [31:0] elapsed_count
    );

    parameter MAX_LEN =  5'd31;
    parameter integer CLK_HZ = 100_000_000;
    localparam UP = 2'b11,DOWN = 2'b10,LEFT = 2'b01,RIGHT = 2'b00;
    integer i;
    localparam WALL_COUNT = 90;
    reg snake_on_wall;

    wire eat,fail_get;
    reg [4:0] next_x,next_y;
    reg refresh_food;
    

    //蛇身增长逻辑
    assign eat = game_tick && (next_x == food_x) && (next_y == food_y);
    always @(posedge clk) begin     
        if(rst | start) begin
            snake_len <= 5'd2;
            snake_x[4:0] <= 5'd14;
            snake_y[4:0] <= 5'd10;
            snake_x[9:5] <= 5'd13;
            snake_y[9:5] <= 5'd10;
            snake_x[14:10] <= 5'd12;
            snake_y[14:10] <= 5'd10;
            snake_x[159:15] <= 145'd0;
            snake_y[159:15] <= 145'd0;
        end else if(game_tick &(~game_pause)) begin
            for(i=1;i<= MAX_LEN;i = i+1) begin
                if(i <= snake_len) begin
                    snake_x[i*5 +: 5] <= snake_x[(i-1)*5 +: 5];
                    snake_y[i*5 +: 5] <= snake_y[(i-1)*5 +: 5];
                end
            end
                snake_x[4:0] <= next_x;
                snake_y[4:0] <= next_y;
            if(eat) begin
                snake_len <= snake_len + 5'd1;
                snake_x[(snake_len+1)*5 +: 5] <= snake_x[(snake_len)*5 +: 5];
                snake_y[(snake_len+1)*5 +: 5] <= snake_y[(snake_len)*5 +: 5];
            end
            else begin
                snake_x[(snake_len+1)*5 +: 5] <= 5'd0;
                snake_y[(snake_len+1)*5 +: 5] <= 5'd0;
            end
        end
    end

    //移动次态逻辑
    always @(*) begin   
        case(direc_state)
            UP: begin
                    next_x = snake_x[4:0];
                    if (snake_y[4:0] == 5'd1)
                        next_y = 5'd22;
                    else
                        next_y = snake_y[4:0] - 5'd1;
                end
            DOWN:begin
                    next_x = snake_x[4:0];
                    if (snake_y[4:0] == 5'd22)
                        next_y = 5'd1;
                    else
                        next_y = snake_y[4:0] + 5'd1;
                end
            RIGHT:begin
                    if (snake_x[4:0] == 5'd31)
                        next_x = 5'd0;
                    else
                        next_x = snake_x[4:0] + 5'd1;
                    next_y = snake_y[4:0];
                end
            LEFT:begin
                    if (snake_x[4:0] == 5'd0)
                        next_x = 5'd31;
                    else
                        next_x = snake_x[4:0] - 5'd1;
                    next_y = snake_y[4:0];
                end
        endcase
    end

    //结束逻辑
    always @(*) begin
        snake_on_wall = 1'b0;
        for (i = 0; i < WALL_COUNT; i = i + 1) begin
            if ((wall_x[i * 5 +: 5] == snake_x[4:0]) &&
                (wall_y[i * 5 +: 5] == snake_y[4:0]))
                snake_on_wall = 1'b1;
        end
    end
    always @(posedge clk) begin   
        game_over <= 1'b0;
        if(snake_len == MAX_LEN) game_over <= 1'b1;
        else if(snake_on_wall) game_over <= 1'b1;
        else begin
            for(i=1;i <= MAX_LEN;i=i+1) begin
                if((snake_x[i*5 +: 5] == snake_x[4:0]) && (snake_y [i*5 +: 5] == snake_y [4:0])) game_over <= 1'b1;
            end
        end
    end

    //食物刷新
    always @(posedge clk) begin
        if(rst) begin
            refresh_food <= 1'b0;
        end else begin
            refresh_food <= 1'b0;
            if(eat|fail_get)
                refresh_food <= 1'b1;
        end
    end

    food_gen food_gen_u ( 
        .clk(clk),
        .rst(rst),
        .start(start),
        .refresh_food(refresh_food),
        .wall_x(wall_x),
        .wall_y(wall_y),
        .snake_x(snake_x),
        .snake_y(snake_y),
        .snake_len(snake_len),
        .food_x(food_x),
        .food_y(food_y),
        .food_type(food_type)
    );

    food_point #(
        .CLK_HZ(CLK_HZ)
    ) u_food_point(
        .clk(clk),
        .rst(rst),
        .food_type(food_type),
        .eat(eat),
        .food_point(food_point),
        .fail_get(fail_get),
        .elapsed_count(elapsed_count)
    );

endmodule
