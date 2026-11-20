`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/17 22:12:19
// Design Name: 
// Module Name: point_food_rgb
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


module point_food_rgb(      //计分食物的呼吸显示
    input vga_clk,
    input rst,
    input [8:0] addra,
    input clk,
    input [31:0] elapsed_count,
    input food_type,
    output reg [11:0] point_food_rgb    //计分食物rgb
    );

    parameter integer CLK_HZ = 100_000_000;
    localparam integer BREATH_INTERVAL = (CLK_HZ * 5) / 32; //每个状态持续周期
    localparam [1:0] SIZE_BIG = 2'd0,
                     SIZE_MEDIUM = 2'd1,
                     SIZE_SMALL = 2'd2;

    reg [1:0] size_sel;
    reg [1:0] size_sel_vga;
    reg [1:0] breath_phase;     //状态机，当前显示哪种大小
    reg [31:0] breath_counter;  //计数器
    reg food_type_vga;
    reg food_pixel;
    wire small_pixel;
    wire medium_pixel;
    wire big_pixel;

    always @(posedge clk) begin
        if (rst || !food_type) begin
            breath_counter <= 32'd0;
            breath_phase <= 2'd0;
            size_sel <= SIZE_BIG;
        end else if (breath_counter == BREATH_INTERVAL - 1) begin
            breath_counter <= 32'd0;
            case (breath_phase)
                2'd0: begin
                    breath_phase <= 2'd1;
                    size_sel <= SIZE_MEDIUM;
                end
                2'd1: begin
                    breath_phase <= 2'd2;
                    size_sel <= SIZE_SMALL;
                end
                2'd2: begin
                    breath_phase <= 2'd3;
                    size_sel <= SIZE_MEDIUM;
                end
                default: begin
                    breath_phase <= 2'd0;
                    size_sel <= SIZE_BIG;
                end
            endcase
        end else begin
            breath_counter <= breath_counter + 1'b1;
        end
    end

    always @(posedge vga_clk) begin
        if (rst) begin
            size_sel_vga <= SIZE_BIG;
            food_type_vga <= 1'b0;
        end else begin
            size_sel_vga <= size_sel;
            food_type_vga <= food_type;
        end
    end

    food_point_small u_food_point_small_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(small_pixel)
    );

    food_point_medium u_food_point_medium_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(medium_pixel)
    );

    food_point_big u_food_point_big_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(big_pixel)
    );

    always @(*) begin
        case (size_sel_vga)
            SIZE_BIG: food_pixel = big_pixel;
            SIZE_MEDIUM: food_pixel = medium_pixel;
            SIZE_SMALL: food_pixel = small_pixel;
            default: food_pixel = 1'b0;
        endcase

        if (food_type_vga && food_pixel)
            point_food_rgb = 12'hF00;
        else
            point_food_rgb = 12'h000;
    end

endmodule
