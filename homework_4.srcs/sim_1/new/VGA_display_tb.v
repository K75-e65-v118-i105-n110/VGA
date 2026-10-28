`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/27 16:15:49
// Design Name: 
// Module Name: VGA_display_tb
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


module VGA_display_tb;

    reg clk;
    wire hsync;
    wire vsync;
    wire [11:0] disp_RGB;
    reg [9:0] expected_hcount;
    reg [9:0] expected_vcount;
    integer completed_lines;
    reg [9:0] sample_x;

    VGA_diaplay uut (
        .clk(clk),
        .hsync(hsync),
        .vsync(vsync),
        .disp_RGB(disp_RGB)
    );

    function [11:0] expected_color;
        input [9:0] x;
        begin
            if (x < 10'd223)
                expected_color = 12'b1111_0000_0000;
            else if (x < 10'd303)
                expected_color = 12'b1111_1010_0000;
            else if (x < 10'd383)
                expected_color = 12'b1111_1111_0000;
            else if (x < 10'd463)
                expected_color = 12'b0000_1111_0000;
            else if (x < 10'd543)
                expected_color = 12'b0000_1111_1111;
            else if (x < 10'd623)
                expected_color = 12'b0000_0000_1111;
            else if (x < 10'd703)
                expected_color = 12'b1111_0000_1111;
            else
                expected_color = 12'b1111_1111_1100;
        end
    endfunction

    initial begin
        clk = 1'b0;

        uut.clk_count = 1'b0;
        uut.vga_clk = 1'b0;
        uut.hcount = 10'd0;
        uut.vcount = 10'd0;
        expected_hcount = 10'd1;
        expected_vcount = 10'd0;
        completed_lines = 0;
    end

    always #10 clk = ~clk;

    always @(posedge uut.vga_clk) begin
        #1;

        if (uut.hcount !== expected_hcount)
            $fatal(1, "hcount mismatch: expected %0d, got %0d",
                   expected_hcount, uut.hcount);
        if (uut.vcount !== expected_vcount)
            $fatal(1, "vcount mismatch: expected %0d, got %0d",
                   expected_vcount, uut.vcount);

        if (hsync !== (uut.hcount > 10'd95))
            $fatal(1, "hsync mismatch at hcount=%0d", uut.hcount);
        if (vsync !== (uut.vcount > 10'd1))
            $fatal(1, "vsync mismatch at vcount=%0d", uut.vcount);

        sample_x = (uut.hcount == 10'd0) ? 10'd799 : uut.hcount - 10'd1;
        if ((sample_x >= 10'd143) && (sample_x < 10'd783)) begin
            if (disp_RGB !== expected_color(sample_x))
                $fatal(1, "RGB mismatch at x=%0d: expected %03h, got %03h",
                       sample_x, expected_color(sample_x), disp_RGB);
        end

        if (uut.hcount == 10'd0) begin
            completed_lines = completed_lines + 1;
            if (uut.vcount == 10'd0) begin
                if (completed_lines != 525)
                    $fatal(1, "expected 525 lines, observed %0d",
                           completed_lines);
                $display("PASS: one frame scanned; 800 pixels x 525 lines, sync and RGB checks passed.");
                $finish;
            end
        end

        if (expected_hcount == 10'd799) begin
            expected_hcount = 10'd0;
            if (expected_vcount == 10'd524)
                expected_vcount = 10'd0;
            else
                expected_vcount = expected_vcount + 10'd1;
        end else begin
            expected_hcount = expected_hcount + 10'd1;
        end
    end

    initial begin
        #40000000;
        $fatal(1, "simulation timed out before completing one frame");
    end
endmodule
