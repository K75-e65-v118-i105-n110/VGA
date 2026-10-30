`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/28 19:19:12
// Design Name: 
// Module Name: back_RGB
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

module back_RGB(
    input vga_clk,
    input [9:0] hcount,
    input [9:0] vcount,
    output reg [11:0] back_RGB
    );

    localparam hsync_end = 10'd95,
               hdat_begin = 10'd143,
               hdat_end = 10'd783,
               h_line = 10'd799,
               vsync_end = 10'd1,
               vdat_begin = 10'd34,
               vdat_end = 10'd514,
               v_line = 10'd524;

    reg [18:0] pixel_x,pixel_y;
    wire [18:0] pic_addr;
    wire [11:0] valid_RGB;
    wire [3:0] color_index;

    //图片地址计算
    always @(*) begin
        if((hcount > hdat_begin-2)&&(hcount <= hdat_end-2)&&(vcount >vdat_begin)&&(vcount <= vdat_end)) begin
            pixel_x = hcount - hdat_begin - 1;
            pixel_y = vcount - vdat_begin - 1;
        end else begin
            pixel_x = 19'd0;
            pixel_y = 19'd0;
        end
    end
    assign pic_addr = pixel_y * 640 + pixel_x;

    //图片ROM
    blk_mem_gen_0 image_rom (
        .clka(vga_clk),    // input wire clka
        .ena(1'b1),      // input wire ena
        .addra(pic_addr),  // input wire [18 : 0] addra
        .douta(color_index)  // output wire [3 : 0] douta
    );

    //颜色索引
    blk_mem_gen_1 image_color_rom (
        .clka(vga_clk),    // input wire clka
        .ena(1'b1),      // input wire ena
        .addra(color_index),  // input wire [3 : 0] addra
        .douta(valid_RGB)  // output wire [11 : 0] douta
    );

    //无效区与有效区信号选择
    always @(*) begin
        if((hcount > hdat_begin)&&(hcount <= hdat_end)&&(vcount >vdat_begin)&&(vcount <= vdat_end)) begin
            back_RGB = valid_RGB;
        end else back_RGB = 12'd0;
    end

endmodule

