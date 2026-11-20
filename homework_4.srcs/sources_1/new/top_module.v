`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/30 21:30:35
// Design Name: 
// Module Name: top_module
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


module top_module(
    input clk,
    input rst,          
    input uart_rx,      //uart信号
    output hsync,       //行同步信号
    output vsync,       //场同步信号
    output [11:0] RGB   //rgb信号
    );

    parameter MAX_LEN =  5'd31,
              DIV = 32'd20_000_000,
              CLK_HZ = 100_000_000,
              BAUD   = 115_200;

    wire game_over,game_pause,start;        //游戏结束、暂停、开始信号
    wire [3:0] direc_in;                    //方向信号
    wire [1:0] direc_state;                 //方向状态
    wire game_tick;                         //游戏更新使能
    wire [159:0] snake_x,snake_y;           //蛇格子坐标
    wire [4:0] food_x,food_y,snake_len;     //食物坐标，蛇身长度
    wire [3:0] food_point;                  //计分食物得分
    wire food_type;                         //计分食物使能
    wire [31:0] elapsed_count;              //计分食物使能
    wire [9:0] hcount,vcount;               //行计数、场计数
    wire vga_clk;                           //像素时钟
    wire start_pause;                       //开始、暂停信号[space]
    wire speed_ctrl;                        //速度切换
    reg [449:0] wall_x = {                  //墙横坐标
        5'd31, 5'd30, 5'd24, 5'd23, 5'd16, 5'd15, 5'd1, 5'd0, 5'd31, 5'd0,
        5'd11, 5'd10, 5'd9, 5'd8, 5'd7, 5'd6, 5'd5, 5'd5, 5'd11, 5'd10,
        5'd9, 5'd8, 5'd7, 5'd5, 5'd28, 5'd27, 5'd24, 5'd11, 5'd5, 5'd24,
        5'd11, 5'd9, 5'd8, 5'd7, 5'd6, 5'd5, 5'd11, 5'd11, 5'd10, 5'd9,
        5'd8, 5'd7, 5'd6, 5'd5, 5'd0, 5'd16, 5'd15, 5'd0, 5'd31, 5'd27,
        5'd16, 5'd15, 5'd31, 5'd11, 5'd10, 5'd9, 5'd7, 5'd6, 5'd5, 5'd23,
        5'd22, 5'd21, 5'd11, 5'd5, 5'd28, 5'd20, 5'd11, 5'd5, 5'd28, 5'd11,
        5'd5, 5'd11, 5'd5, 5'd27, 5'd26, 5'd25, 5'd11, 5'd10, 5'd9, 5'd7,
        5'd6, 5'd5, 5'd31, 5'd0, 5'd31, 5'd30, 5'd17, 5'd16, 5'd1, 5'd0
    };
    reg [449:0] wall_y = {                  //墙纵坐标
        5'd22, 5'd22, 5'd22, 5'd22, 5'd22, 5'd22, 5'd22, 5'd22, 5'd21, 5'd21,
        5'd20, 5'd20, 5'd20, 5'd20, 5'd20, 5'd20, 5'd20, 5'd19, 5'd18, 5'd18,
        5'd18, 5'd18, 5'd18, 5'd18, 5'd17, 5'd17, 5'd17, 5'd17, 5'd17, 5'd16,
        5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd16, 5'd15, 5'd14, 5'd14, 5'd14,
        5'd14, 5'd14, 5'd14, 5'd14, 5'd13, 5'd12, 5'd12, 5'd12, 5'd11, 5'd11,
        5'd11, 5'd11, 5'd10, 5'd9, 5'd9, 5'd9, 5'd9, 5'd9, 5'd9, 5'd8,
        5'd8, 5'd8, 5'd8, 5'd8, 5'd7, 5'd7, 5'd7, 5'd7, 5'd6, 5'd5,
        5'd5, 5'd4, 5'd4, 5'd3, 5'd3, 5'd3, 5'd3, 5'd3, 5'd3, 5'd3,
        5'd3, 5'd3, 5'd2, 5'd2, 5'd1, 5'd1, 5'd1, 5'd1, 5'd1, 5'd1
    };

    //游戏状态机
    start_end game_state (
        .clk(clk),
        .rst(rst),
        .game_over(game_over),
        .game_pause(game_pause),
        .start(start),
        .start_pause(start_pause)
    );

    //VGA扫描
    VGA_display scan (
        .clk(clk),
        .hsync(hsync),
        .vsync(vsync),
        .hcount(hcount),
        .vcount(vcount),
        .vga_clk(vga_clk)
    );

    //键盘输入
    uart_dirctrl#(
        .CLK_HZ(CLK_HZ),
        .BAUD(BAUD)) u_uart_ctrl(
        .clk(clk),
        .rst(rst),
        .uart_rx(uart_rx),
        .up_pulse(direc_in[3]),
        .down_pulse(direc_in[2]),
        .left_pulse(direc_in[1]),
        .right_pulse(direc_in[0]),
        .start_pulse(start_pause),
        .speed_ctrl(speed_ctrl)
);

    //方向状态机
    input_ctrl direction (
    .clk(clk),
    .rst(rst),
    .game_tick(game_tick),
    .start(start),
    .game_pause(game_pause),
    .direc_in(direc_in),//up,down,left,right 优先级：up>down>left>right
    .direc_state(direc_state)
    );

    //游戏更新触发
    game_tick #(
    .DIV(DIV)
    ) tick (
        .clk(clk),
        .rst(rst),
        .speed_ctrl(speed_ctrl),
        .game_tick(game_tick)
    );

    //游戏运行规则
    game_rule #(
    .MAX_LEN(MAX_LEN),
    .CLK_HZ(CLK_HZ)
    ) rule (
        .clk(clk),
        .rst(rst),
        .game_tick(game_tick),
        .start(start),
        .game_pause(game_pause),
        .direc_state(direc_state),
        .wall_x(wall_x),
        .wall_y(wall_y),
        .snake_x(snake_x),
        .snake_y(snake_y),
        .food_x(food_x),
        .food_y(food_y),
        .snake_len(snake_len),   //蛇长-1
        .food_type(food_type),
        .food_point(food_point),
        .elapsed_count(elapsed_count),
        .game_over(game_over)
    );

    //rgb信号的选择输出
    RGB_gen #(
    .MAX_LEN(MAX_LEN),
    .CLK_HZ(CLK_HZ)
    ) RGB_u (     //32X24棋盘格
        .clk(clk),
        .rst(rst),
        .vga_clk(vga_clk),
        .start(start),
        .game_over(game_over),
        .direc_state(direc_state),
        .hcount(hcount),
        .vcount(vcount),
        .wall_x(wall_x),
        .wall_y(wall_y),
        .snake_x(snake_x),  //每格5位
        .snake_y(snake_y),
        .food_x(food_x),
        .food_y(food_y),
        .elapsed_count(elapsed_count),
        .snake_len(snake_len),
        .food_point(food_point),
        .food_type(food_type),
        .disp_RGB(RGB)
    );

endmodule
