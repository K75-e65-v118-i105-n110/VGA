`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/17 18:02:38
// Design Name: 
// Module Name: point_rgb
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


module point_rgb(       //计分显示
    input [1:0] figure_pos,     //位选信号
    input [8:0] addra,
    input clk,
    input vga_clk,
    input rst,
    input start,
    input [4:0] snake_len,
    input [3:0] food_point,
    output [11:0] point_rgb     //计分rgb
    );

    wire [3:0] hundreds;
    wire [3:0] tens;
    wire [3:0] ones;
    wire [0:0] digit_0_pixel;
    wire [0:0] digit_1_pixel;
    wire [0:0] digit_2_pixel;
    wire [0:0] digit_3_pixel;
    wire [0:0] digit_4_pixel;
    wire [0:0] digit_5_pixel;
    wire [0:0] digit_6_pixel;
    wire [0:0] digit_7_pixel;
    wire [0:0] digit_8_pixel;
    wire [0:0] digit_9_pixel;
    reg [3:0] pos_sel;
    reg [3:0] pos_sel_d;
    reg digit_pixel;

    point_count u_point_count (
        .clk(clk),
        .rst(rst),
        .start(start),
        .snake_len(snake_len),
        .food_point(food_point),
        .hundreds(hundreds),
        .tens(tens),
        .ones(ones)
    );

    always@(*) begin
        case(figure_pos)
            2'd0: pos_sel = ones;
            2'd1: pos_sel = tens;
            2'd2: pos_sel = hundreds;
            default: pos_sel = ones;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            pos_sel_d <= 4'd0;
        else
            pos_sel_d <= pos_sel;
    end

    digit_0 u_digit_0_rom (
        .clka(vga_clk), .ena(1'b1), .addra(addra), .douta(digit_0_pixel)
    );

    digit_1 u_digit_1_rom (
        .clka(vga_clk), .ena(1'b1), .addra(addra), .douta(digit_1_pixel)
    );

    digit_2 u_digit_2_rom (
        .clka(vga_clk), .ena(1'b1), .addra(addra), .douta(digit_2_pixel)
    );

    digit_3 u_digit_3_rom (
        .clka(vga_clk), .ena(1'b1), .addra(addra), .douta(digit_3_pixel)
    );

    digit_4 u_digit_4_rom (
        .clka(vga_clk), .ena(1'b1), .addra(addra), .douta(digit_4_pixel)
    );

    digit_5 u_digit_5_rom (
        .clka(vga_clk), .ena(1'b1), .addra(addra), .douta(digit_5_pixel)
    );

    digit_6 u_digit_6_rom (
        .clka(vga_clk), .ena(1'b1), .addra(addra), .douta(digit_6_pixel)
    );

    digit_7 u_digit_7_rom (
        .clka(vga_clk), .ena(1'b1), .addra(addra), .douta(digit_7_pixel)
    );

    digit_8 u_digit_8_rom (
        .clka(vga_clk), .ena(1'b1), .addra(addra), .douta(digit_8_pixel)
    );

    digit_9 u_digit_9_rom (
        .clka(vga_clk), .ena(1'b1), .addra(addra), .douta(digit_9_pixel)
    );

    always @(*) begin
        case (pos_sel_d)
            4'd0: digit_pixel = digit_0_pixel[0];
            4'd1: digit_pixel = digit_1_pixel[0];
            4'd2: digit_pixel = digit_2_pixel[0];
            4'd3: digit_pixel = digit_3_pixel[0];
            4'd4: digit_pixel = digit_4_pixel[0];
            4'd5: digit_pixel = digit_5_pixel[0];
            4'd6: digit_pixel = digit_6_pixel[0];
            4'd7: digit_pixel = digit_7_pixel[0];
            4'd8: digit_pixel = digit_8_pixel[0];
            4'd9: digit_pixel = digit_9_pixel[0];
            default: digit_pixel = 1'b0;
        endcase
    end

    assign point_rgb = digit_pixel ? 12'hFFF : 12'h000;

endmodule
