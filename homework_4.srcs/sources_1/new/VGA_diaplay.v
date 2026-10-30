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
    output [11:0] disp_RGB
    );

    reg clk_count;
    reg vga_clk;
    wire hcount_ov,vcount_ov;
    reg [9:0] hcount,vcount;
    wire [11:0] back_RGB;
    


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


    //移动坐标
    wire [9:0] blk_x,blk_y;
    block_move move (
        .clk(clk),
        .vsync(vsync),
        .blk_x(blk_x),
        .blk_y(blk_y)
    );


    //图片生成
    RGB_gen u (
        .vga_clk(vga_clk),
        .hcount(hcount),
        .vcount(vcount),
        .blk_x(blk_x),
        .blk_y(blk_y),
        .disp_RGB(disp_RGB)
    );


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
