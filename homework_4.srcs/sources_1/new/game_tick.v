`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/30 21:37:06
// Design Name: 
// Module Name: game_tick
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


module game_tick(
    input clk,
    input rst,
    input speed_ctrl,
    output reg game_tick
    );

    parameter DIV = 32'd20_000_000;     //分频比

    reg [31:0] cnt;
    reg [31:0] div_sel;

    always @(*) begin
        if(speed_ctrl) div_sel = DIV >> 1;
        else div_sel = DIV;
    end

    always @(posedge clk) begin
        if (rst) begin
            cnt  <= 16'd0;
            game_tick <= 1'b0;
        end else if (cnt >= div_sel - 1) begin
            cnt  <= 16'd0;
            game_tick <= 1'b1;                // 单周期脉冲
        end else begin
            cnt  <= cnt + 1'b1;
            game_tick <= 1'b0;
        end
    end

endmodule