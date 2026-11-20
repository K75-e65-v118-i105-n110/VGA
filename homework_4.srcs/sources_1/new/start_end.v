`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/05 16:03:14
// Design Name: 
// Module Name: start_end
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


module start_end(   //游戏状态机
    input clk,
    input rst,
    input game_over,
    input start_pause,
    output reg game_pause,
    output reg start
    );

    reg [1:0] state;
    reg [1:0] next_state;

    localparam START=2'd0,GAME_ON=2'd1,GAME_PAUSE=2'd2,GAME_OVER=2'd3;

    always @(posedge clk) begin
        if(rst) state <= START;
        else state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case(state)
            START: if(start_pause) next_state = GAME_ON;
            GAME_ON: begin
                if(game_over) next_state = GAME_OVER;
                else if(start_pause) next_state = GAME_PAUSE; 
            end
            GAME_PAUSE: if(start_pause) next_state = GAME_ON;
            GAME_OVER: if(start_pause) next_state = START;
        endcase
    end

    always @(*) begin
        start = 1'b0;
        game_pause = 1'b0;

        case(state) 
            START: start = 1'b1;
            GAME_ON: ;
            GAME_PAUSE: game_pause = 1'b1;
            GAME_OVER: game_pause = 1'b1;
        endcase
    end

endmodule
