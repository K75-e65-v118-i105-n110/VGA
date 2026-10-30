`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/28 19:13:34
// Design Name: 
// Module Name: RGB_gen
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


module RGB_gen(
    input vga_clk,
    input [9:0] hcount,
    input [9:0] vcount,
    input [9:0] blk_x,
    input [9:0] blk_y,
    output reg [12:0] disp_RGB
    );

    localparam hdat_begin = 10'd143,
               hdat_end = 10'd783,
               vdat_begin = 10'd34,
               vdat_end = 10'd514,
               blk_width = 10'd40,
               blk_height = 10'd40;


    wire [18:0] pixel_x,pixel_y;
    wire [18:0] pic_addr;
    wire [6:0] blk_addr;
    wire [11:0] valid_RGB;
    reg [3:0] color_index;
    wire [3:0] back_index;
    wire [3:0] blk_index;
    reg [1:0] EN;//[1]_blk,[0]_back

    //图片地址计算
    assign pixel_x = hcount - hdat_begin - 1;
    assign pixel_y = vcount - vdat_begin - 1;
    assign pic_addr = pixel_y * 640 + pixel_x;
    assign blk_addr =( vcount - vdat_begin - blk_y - 1) * blk_width + hcount - hdat_begin - 1 - blk_x;
    


    //按坐标选RGB
    always @(*) begin
        if((hcount > hdat_begin-2)&&(hcount <= hdat_end-2)&&(vcount > vdat_begin)&&(vcount <= vdat_end)) begin
            if((hcount > hdat_begin + blk_x - 2)&&(hcount < hdat_begin + blk_x + blk_width - 2)&&(vcount > vdat_begin + blk_y -2)&&(vcount < vdat_begin + blk_y + blk_height - 2)) begin
                EN <= 2'b10;
            end else EN <= 2'b01;
        end else EN <= 2'b00;
    end


    //图片ROM
    blk_mem_gen_0 back_ROM (
        .clka(vga_clk),    // input wire clka
        .ena(EN[0]),      // input wire ena
        .addra(pic_addr),  // input wire [18 : 0] addra
        .douta(back_index)  // output wire [3 : 0] douta
    );

    blk_mem_gen_2 block_ROM (
        .clka(vga_clk),    // input wire clka
        .ena(EN[1]),      // input wire ena
        .addra(blk_addr),  // input wire [6 : 0] addra
        .douta(blk_index)  // output wire [3 : 0] douta
    );




    //颜色索引
    always @(*) begin
        case(EN)
            2'b10: color_index = blk_index;
            2'b01: color_index = back_index;
            default: color_index = 4'hf;//区外默认
        endcase
    end

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

endmodule
