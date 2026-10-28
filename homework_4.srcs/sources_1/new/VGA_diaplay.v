`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/22 16:58:41
// Design Name: 
// Module Name: VGA_diaplay
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


module VGA_diaplay(     //640x480@60Hz
    input clk,
    //input [11:0] RGB_in,
    output hsync,
    output vsync,
    output reg [11:0] disp_RGB
    );

    reg clk_count;
    reg vga_clk;
    wire hcount_ov,vcount_ov;
    reg [9:0] hcount,vcount;
    reg [18:0] pixel_x,pixel_y;
    wire [18:0] pic_addr;
    wire [11:0] valid_RGB;
    wire [3:0] color_index;


    localparam hsync_end = 10'd95,
               hdat_begin = 10'd143,
               hdat_end = 10'd783,
               h_line = 10'd799,
               vsync_end = 10'd1,
               vdat_begin = 10'd34,
               vdat_end = 10'd514,
               v_line = 10'd524;

    //25MHz时钟生成
    always @(posedge clk) begin
        if(clk_count >= 1'd1) begin
            vga_clk <= ~vga_clk;
            clk_count <= 1'b0;
        end else begin
            clk_count <= clk_count + 1'b1;
        end
    end

    //行场扫描
    always @(posedge vga_clk) begin
        if(hcount_ov) hcount <= 10'd0;
        else hcount <= hcount + 10'd1;
    end 

    always @(posedge vga_clk) begin
        if(hcount_ov) begin
            if(vcount_ov) vcount <= 10'd0;
            else vcount <= vcount + 10'd1;
        end
    end

    //相关信号运算
    assign hcount_ov = (hcount >= h_line);
    assign vcount_ov = (vcount >= v_line);
    assign hsync = (hcount > hsync_end);
    assign vsync = (vcount > vsync_end);

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
            disp_RGB = valid_RGB;
        end else disp_RGB = 12'd0;
    end


    // //竖彩条信号显示
    // always @(*) begin
    //     if(hcount < hdat_begin)
    //         disp_RGB = 12'd0;
    //     else if((hcount >= hdat_begin) && (hcount < 10'd223))
    //         disp_RGB = 12'b1111_0000_0000;
    //     else if(hcount < 10'd303)
    //         disp_RGB = 12'b1111_1010_0000;
    //     else if(hcount < 10'd383)
    //         disp_RGB = 12'b1111_1111_0000;
    //     else if(hcount < 10'd463)
    //         disp_RGB = 12'b0000_1111_0000;
    //     else if(hcount < 10'd543)
    //         disp_RGB = 12'b0000_1111_1111;
    //     else if(hcount < 10'd623)
    //         disp_RGB = 12'b0000_0000_1111;
    //     else if(hcount < 10'd703)
    //         disp_RGB = 12'b1111_0000_1111;
    //     else if(hcount < hdat_end)
    //         disp_RGB = 12'b1111_1111_1111;
    //     else disp_RGB = 12'd0;
    // end

    // always @(posedge vga_clk) begin
    //     if((hcount >= hdat_begin) && (hcount < hdat_end))
    //         disp_RGB <= RGB_in;
    //     else disp_RGB <= 12'd0;
    // end





endmodule
