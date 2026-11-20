`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/22 16:58:41
// Design Name: 
// Module Name: VGA_display
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


module VGA_display(     //640x480@60Hz
    input clk,
    output hsync,
    output vsync,
    output reg [9:0] hcount,
    output reg [9:0] vcount,
    output reg vga_clk
    );

    reg clk_count;
    wire hcount_ov,vcount_ov;
    


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





endmodule
