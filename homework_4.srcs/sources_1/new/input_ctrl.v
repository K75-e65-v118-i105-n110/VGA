`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/10/30 22:06:08
// Design Name: 
// Module Name: input_ctrl
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


module input_ctrl(  //方向状态机
    input clk,
    input rst,
    input start,
    input game_pause,
    input game_tick,
    input [3:0] direc_in,//up,down,left,right 优先级：up>down>left>right
    output reg [1:0] direc_state
    );

    localparam [1:0] UP = 2'b11,
                     DOWN = 2'b10,
                     LEFT = 2'b01,
                     RIGHT = 2'b00;

    reg [1:0] last_move_dir;// 上一次实际移动的方向
    reg [1:0] requested_dir;
    reg [1:0] forbidden_dir;// 当前移动周期内禁止接受的反方向。
    reg request_valid;

    always @(*) begin
        request_valid = 1'b1;
        if (direc_in[3])
            requested_dir = UP;
        else if (direc_in[2])
            requested_dir = DOWN;
        else if (direc_in[1])
            requested_dir = LEFT;
        else if (direc_in[0])
            requested_dir = RIGHT;
        else begin
            requested_dir = direc_state;
            request_valid = 1'b0;
        end

        case (game_tick ? direc_state : last_move_dir)
            UP: forbidden_dir = DOWN;
            DOWN: forbidden_dir = UP;
            LEFT: forbidden_dir = RIGHT;
            default: forbidden_dir = LEFT;
        endcase
    end

    always @(posedge clk) begin
        if (rst || start) begin
            direc_state <= RIGHT;
            last_move_dir <= RIGHT;
        end else begin
            if (game_tick && !game_pause)   // 仅在游戏实际移动时更新方向基准，暂停时保留原记录。
                last_move_dir <= direc_state;
            if (!game_pause && request_valid &&// 有效且非反向的输入立即更新方向；没有输入或暂停时保持原方向。
                (requested_dir != forbidden_dir))
                direc_state <= requested_dir;
        end
    end

endmodule
