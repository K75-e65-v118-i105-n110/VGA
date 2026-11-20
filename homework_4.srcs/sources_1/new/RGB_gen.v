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


module RGB_gen(     //32X24棋盘格
    input clk,
    input rst,
    input vga_clk,
    input start,
    input game_over,    
    input [1:0] direc_state,
    input [9:0] hcount,
    input [9:0] vcount,
    input [449:0] wall_x,
    input [449:0] wall_y,
    input [159:0] snake_x,  //每格5位
    input [159:0] snake_y,
    input [4:0] food_x,
    input [4:0] food_y,
    input [31:0] elapsed_count,
    input [4:0] snake_len,
    input [3:0] food_point,
    input food_type,
    output reg [11:0] disp_RGB
    );

    integer i;

    parameter MAX_LEN =  5'd31;
    parameter integer CLK_HZ = 100_000_000;
    localparam hdat_begin = 10'd143,
               hdat_end = 10'd783,
               vdat_begin = 10'd34,
               vdat_end = 10'd514,
               start_text_x = 10'd300,
               start_text_y = 10'd355,
               restart_text_x = 10'd284,
               gameover_text_x = 10'd354,
               gameover_text_y = 10'd280,
               blk_width = 10'd40,
               blk_height = 10'd40;

    localparam WALL_COUNT = 90;

    reg act_area,wall,head,body,food,tail,point,bound_down;
    reg [1:0] figure_pos;
    reg [14:0] point_x = {5'd2,5'd1,5'd0};
    reg [4:0] point_y = 5'd0;
    
    wire [9:0] point_y_pixel = point_y * 10'd20 + vdat_begin;
    wire [9:0] point_x0_pixel = point_x[4:0] * 10'd20 + hdat_begin;
    wire [9:0] point_x1_pixel = point_x[9:5] * 10'd20 + hdat_begin;
    wire [9:0] point_x2_pixel = point_x[14:10] * 10'd20 + hdat_begin;
    wire point_x0_area = (hcount > point_x0_pixel) &&
                         (hcount <= point_x0_pixel + 10'd20) &&
                         (vcount > point_y_pixel) &&
                         (vcount <= point_y_pixel + 10'd20);
    wire point_x1_area = (hcount > point_x1_pixel) &&
                         (hcount <= point_x1_pixel + 10'd20) &&
                         (vcount > point_y_pixel) &&
                         (vcount <= point_y_pixel + 10'd20);
    wire point_x2_area = (hcount > point_x2_pixel) &&
                         (hcount <= point_x2_pixel + 10'd20) &&
                         (vcount > point_y_pixel) &&
                         (vcount <= point_y_pixel + 10'd20);
    reg wall_area;
    integer wall_i;
    wire [9:0] wall_pixel_x = hcount - hdat_begin - 10'd1;
    wire [9:0] wall_pixel_y = vcount - vdat_begin - 10'd1;
    wire [4:0] wall_cell_x = wall_pixel_x / 10'd20;
    wire [4:0] wall_cell_y = wall_pixel_y / 10'd20;
    wire wall_in_board = (hcount > hdat_begin) && (hcount <= hdat_end) &&
                         (vcount > vdat_begin) && (vcount <= vdat_end);
    reg [9:0] snake_pixel_x;
    reg [9:0] snake_pixel_y;
    wire [9:0] food_pixel_x = food_x * 20 + hdat_begin;
    wire [9:0] food_pixel_y = food_y * 20 + vdat_begin;
    wire [4:0] relate_x,relate_y;
    wire [8:0] addra;
    wire [13:0] start_text_addra;
    wire [13:0] restart_text_addra;
    wire [13:0] gameover_text_addra;
    wire [9:0] text_h_next = hcount + 10'd1;
    wire start_text_prefetch = start &&
        (text_h_next >= start_text_x) &&
        (text_h_next < start_text_x + 10'd328) &&
        (vcount >= start_text_y) &&
        (vcount < start_text_y + 10'd31);
    wire restart_text_prefetch = game_over &&
        (text_h_next >= restart_text_x) &&
        (text_h_next < restart_text_x + 10'd359) &&
        (vcount >= start_text_y) &&
        (vcount < start_text_y + 10'd31);
    wire gameover_text_prefetch = game_over &&
        (text_h_next >= gameover_text_x) &&
        (text_h_next < gameover_text_x + 10'd220) &&
        (vcount >= gameover_text_y) &&
        (vcount < gameover_text_y + 10'd55);
    wire [9:0] start_text_x_offset = text_h_next - start_text_x;
    wire [9:0] start_text_y_offset = vcount - start_text_y;
    wire [9:0] restart_text_x_offset = text_h_next - restart_text_x;
    wire [9:0] gameover_text_x_offset = text_h_next - gameover_text_x;
    wire [9:0] gameover_text_y_offset = vcount - gameover_text_y;
    wire [11:0] start_text_rgb;
    wire [11:0] restart_text_rgb;
    wire [11:0] gameover_text_rgb;
    wire [11:0] wall_rgb;
    wire [11:0] food_rgb;
    wire [11:0] point_rgb;
    wire [11:0] point_food_rgb;
    wire [11:0] bound_down_rgb;
    reg start_notice;
    reg restart_notice;
    reg gameover_notice;
    reg turn_down_right;
    reg turn_left_down;
    reg turn_right_up;
    reg turn_up_left;
    reg body_left_right;
    reg body_up_down;
    reg tail_up;
    reg tail_down;
    reg tail_left;
    reg tail_right;
    reg [4:0] segment_x, segment_y;
    reg [4:0] prev_x, prev_y;
    reg [4:0] next_x, next_y;
    reg [1:0] head_direction;
    wire prev_up = (prev_x == segment_x) &&
                   (((segment_y == 5'd1) && (prev_y == 5'd22)) ||
                    ((segment_y > 5'd1) && (prev_y == segment_y - 5'd1)));
    wire prev_down = (prev_x == segment_x) &&
                     (((segment_y == 5'd22) && (prev_y == 5'd1)) ||
                      ((segment_y < 5'd22) && (prev_y == segment_y + 5'd1)));
    wire prev_left = (prev_y == segment_y) &&
                     (((segment_x == 5'd0) && (prev_x == 5'd31)) ||
                      ((segment_x > 5'd0) && (prev_x == segment_x - 5'd1)));
    wire prev_right = (prev_y == segment_y) &&
                      (((segment_x == 5'd31) && (prev_x == 5'd0)) ||
                       ((segment_x < 5'd31) && (prev_x == segment_x + 5'd1)));
    wire next_up = (next_x == segment_x) &&
                   (((segment_y == 5'd1) && (next_y == 5'd22)) ||
                    ((segment_y > 5'd1) && (next_y == segment_y - 5'd1)));
    wire next_down = (next_x == segment_x) &&
                     (((segment_y == 5'd22) && (next_y == 5'd1)) ||
                      ((segment_y < 5'd22) && (next_y == segment_y + 5'd1)));
    wire next_left = (next_y == segment_y) &&
                     (((segment_x == 5'd0) && (next_x == 5'd31)) ||
                      ((segment_x > 5'd0) && (next_x == segment_x - 5'd1)));
    wire next_right = (next_y == segment_y) &&
                      (((segment_x == 5'd31) && (next_x == 5'd0)) ||
                       ((segment_x < 5'd31) && (next_x == segment_x + 5'd1)));

    always @(*) begin
        wall_area = 1'b0;
        if (wall_in_board) begin
            for (wall_i = 0; wall_i < WALL_COUNT; wall_i = wall_i + 1) begin
                if ((wall_x[wall_i * 5 +: 5] == wall_cell_x) &&
                    (wall_y[wall_i * 5 +: 5] == wall_cell_y))
                    wall_area = 1'b1;
            end
        end
    end

    always @(*) begin
        act_area = 1'b0;
        wall = 1'b0;
        head = 1'b0;
        body = 1'b0;
        food = 1'b0;
        tail = 1'b0;
        point = 0;
        figure_pos = 2'd0;
        start_notice = 1'b0;
        restart_notice = 1'b0;
        gameover_notice = 1'b0;
        turn_down_right = 1'b0;
        turn_left_down = 1'b0;
        turn_right_up = 1'b0;
        turn_up_left = 1'b0;
        body_left_right = 1'b0;
        body_up_down = 1'b0;
        tail_up = 1'b0;
        tail_down = 1'b0;
        tail_left = 1'b0;
        tail_right = 1'b0;
        segment_x = 5'd0;
        segment_y = 5'd0;
        prev_x = 5'd0;
        prev_y = 5'd0;
        next_x = 5'd0;
        next_y = 5'd0;
        head_direction = 2'b00;
        bound_down = 1'b0;

        if((hcount > hdat_begin)&&(hcount <= hdat_end)&&(vcount > vdat_begin)&&(vcount <= vdat_end)) begin
            act_area = 1'b1;
            if(game_over) begin
                if((hcount >= gameover_text_x) &&
                   (hcount < gameover_text_x + 10'd220) &&
                   (vcount >= gameover_text_y) &&
                   (vcount < gameover_text_y + 10'd55))
                    gameover_notice = 1'b1;
                else if((hcount >= restart_text_x) &&
                        (hcount < restart_text_x + 10'd359) &&
                        (vcount >= start_text_y) &&
                        (vcount < start_text_y + 10'd31))
                    restart_notice = 1'b1;
            end
            else if(start &&
                    (hcount >= start_text_x) &&
                    (hcount < start_text_x + 10'd328) &&
                    (vcount >= start_text_y) &&
                    (vcount < start_text_y + 10'd31)) begin
                start_notice = 1'b1;
            end

            if(point_x0_area || point_x1_area || point_x2_area) begin
                point = 1'b1;
                if(point_x0_area)
                    figure_pos = 2'd2;
                else if(point_x1_area)
                    figure_pos = 2'd1;
                else
                    figure_pos = 2'd0;
            end
            else if(wall_area)
                wall = 1'b1;
            else if((vcount > vdat_end - 10'd20) && (vcount <= vdat_end)) bound_down = 1'b1;
            else begin
                for(i=0;i<=MAX_LEN;i=i+1) begin
                    if(i <= snake_len) begin
                        snake_pixel_x = snake_x[i*5 +: 5] * 20 + hdat_begin;
                        snake_pixel_y = snake_y[i*5 +: 5] * 20 + vdat_begin;
                        if((hcount > snake_pixel_x) && (hcount <= snake_pixel_x + 10'd20) && (vcount > snake_pixel_y) && (vcount <= snake_pixel_y + 10'd20))begin
                            if(i==0) begin
                                head = 1'b1;
                                if((snake_y[4:0] == 5'd22) &&
                                   (snake_y[9:5] == 5'd1))
                                    head_direction = 2'b11;
                                else if((snake_y[4:0] == 5'd1) &&
                                        (snake_y[9:5] == 5'd22))
                                    head_direction = 2'b10;
                                else if(snake_x[4:0] > snake_x[9:5])
                                    head_direction = 2'b00;
                                else if(snake_x[4:0] < snake_x[9:5])
                                    head_direction = 2'b01;
                                else if(snake_y[4:0] > snake_y[9:5])
                                    head_direction = 2'b10;
                                else if(snake_y[4:0] < snake_y[9:5])
                                    head_direction = 2'b11;
                            end
                            else if(i < snake_len) begin body = 1'b1;
                                segment_x = snake_x[i*5 +: 5];
                                segment_y = snake_y[i*5 +: 5];
                                prev_x = snake_x[(i-1)*5 +: 5];
                                prev_y = snake_y[(i-1)*5 +: 5];
                                next_x = snake_x[(i+1)*5 +: 5];
                                next_y = snake_y[(i+1)*5 +: 5];

                                if((prev_x == segment_x) && (next_x == segment_x))
                                    body_up_down = 1'b1;
                                else if((prev_y == segment_y) && (next_y == segment_y))
                                    body_left_right = 1'b1;
                                else if((prev_down && next_right) ||
                                        (next_down && prev_right))
                                    turn_down_right = 1'b1;
                                else if((prev_left && next_down) ||
                                        (next_left && prev_down))
                                    turn_left_down = 1'b1;
                                else if((prev_right && next_up) ||
                                        (next_right && prev_up))
                                    turn_right_up = 1'b1;
                                else if((prev_up && next_left) ||
                                        (next_up && prev_left))
                                    turn_up_left = 1'b1;
                            end
                            else if(i == snake_len) begin
                                tail = 1'b1;
                                segment_x = snake_x[i*5 +: 5];
                                segment_y = snake_y[i*5 +: 5];
                                prev_x = snake_x[(i-1)*5 +: 5];
                                prev_y = snake_y[(i-1)*5 +: 5];

                                if(prev_down)
                                    tail_up = 1'b1;
                                else if(prev_up)
                                    tail_down = 1'b1;
                                else if(prev_right)
                                    tail_left = 1'b1;
                                else if(prev_left)
                                    tail_right = 1'b1;
                            end
                        end
                    end
                end
                if((hcount > food_pixel_x) && (hcount <= food_pixel_x + 10'd20) && (vcount > food_pixel_y) && (vcount <= food_pixel_y + 10'd20))
                    food = 1'b1;
            end
        end
    end


    assign relate_x = (hcount - hdat_begin + 5'd1) % 5'd20;
    assign relate_y = (vcount - vdat_begin - 5'd1) % 5'd20;
    assign addra = relate_x + relate_y * 20;
    assign start_text_addra = start_text_prefetch
        ? (start_text_y_offset * 14'd328) + start_text_x_offset
        : 14'd0;
    assign restart_text_addra = restart_text_prefetch
        ? ((vcount - start_text_y) * 14'd359) + restart_text_x_offset
        : 14'd0;
    assign gameover_text_addra = gameover_text_prefetch
        ? (gameover_text_y_offset * 14'd220) + gameover_text_x_offset
        : 14'd0;

    press_start u_press_start_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(start_text_addra),
        .douta(start_text_rgb)
    );

    press_restart u_press_restart_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(restart_text_addra),
        .douta(restart_text_rgb)
    );

    game_over u_game_over_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(gameover_text_addra),
        .douta(gameover_text_rgb)
    );

    wire [11:0] body_left_right_rgb;
    wire [11:0] body_up_down_rgb;
    wire [11:0] head_down_rgb;
    wire [11:0] head_left_rgb;
    wire [11:0] head_right_rgb;
    wire [11:0] head_up_rgb;
    wire [11:0] tail_down_rgb;
    wire [11:0] tail_left_rgb;
    wire [11:0] tail_right_rgb;
    wire [11:0] tail_up_rgb;
    wire [11:0] turn_down_right_rgb;
    wire [11:0] turn_left_down_rgb;
    wire [11:0] turn_right_up_rgb;
    wire [11:0] turn_up_left_rgb;

    body_left_right u_body_left_right_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(body_left_right_rgb)
    );

    body_up_down u_body_up_down_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(body_up_down_rgb)
    );

    head_down u_head_down_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(head_down_rgb)
    );

    head_left u_head_left_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(head_left_rgb)
    );

    head_right u_head_right_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(head_right_rgb)
    );

    head_up u_head_up_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(head_up_rgb)
    );

    tail_down u_tail_down_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(tail_down_rgb)
    );

    tail_left u_tail_left_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(tail_left_rgb)
    );

    tail_right u_tail_right_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(tail_right_rgb)
    );

    tail_up u_tail_up_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(tail_up_rgb)
    );

    turn_down_right u_turn_down_right_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(turn_down_right_rgb)
    );

    turn_left_down u_turn_left_down_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(turn_left_down_rgb)
    );

    turn_right_up u_turn_right_up_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(turn_right_up_rgb)
    );

    turn_up_left u_turn_up_left_rom (
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(turn_up_left_rgb)
    );

    point_rgb u_point_rgb (
            .figure_pos(figure_pos),
            .addra(addra),
            .clk(clk),
            .vga_clk(vga_clk),
            .rst(rst),
            .start(start),
            .snake_len(snake_len),
            .food_point(food_point),
            .point_rgb(point_rgb)
    );

    wall u_wall(
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(wall_rgb)
    );

    food u_food(
        .clka(vga_clk),
        .ena(1'b1),
        .addra(addra),
        .douta(food_rgb)
    );

    point_food_rgb #(
    .CLK_HZ(CLK_HZ)
    ) u_point_food_rgb(
    .vga_clk(vga_clk),
    .rst(rst),
    .addra(addra),
    .clk(clk),
    .elapsed_count(elapsed_count),
    .food_type(food_type),
    .point_food_rgb(point_food_rgb)
    );

    bound_down_rgb #(
    .CLK_HZ(CLK_HZ)
    ) u_bound_down_rgb(
    .clk(vga_clk),
    .hcount(hcount),
    .vcount(vcount),
    .elapsed_count(elapsed_count),
    .food_type(food_type),
    .bound_down_rgb(bound_down_rgb)
    );

    always @(*) begin
        if(!act_area) disp_RGB = 12'h000;
        else if(gameover_notice) disp_RGB = gameover_text_rgb;
        else if(restart_notice) disp_RGB = restart_text_rgb;
        else if(start_notice) disp_RGB = start_text_rgb;
        else if(point) disp_RGB = point_rgb;
        else if(wall) disp_RGB = wall_rgb;
        else if(bound_down) disp_RGB = bound_down_rgb;
        else if(head) begin
            case(head_direction)
                2'b11: disp_RGB = head_up_rgb;
                2'b10: disp_RGB = head_down_rgb;
                2'b01: disp_RGB = head_left_rgb;
                2'b00: disp_RGB = head_right_rgb;
            endcase
        end
        else if(body) begin
            if(body_left_right) disp_RGB = body_left_right_rgb;
            else if(body_up_down) disp_RGB = body_up_down_rgb;
            else if(turn_down_right) disp_RGB = turn_down_right_rgb;
            else if(turn_left_down) disp_RGB = turn_left_down_rgb;
            else if(turn_right_up) disp_RGB = turn_right_up_rgb;
            else if(turn_up_left) disp_RGB = turn_up_left_rgb;
            else disp_RGB = 12'h00F;
        end
        else if(tail) begin
            if(tail_up) disp_RGB = tail_down_rgb;
            else if(tail_down) disp_RGB = tail_up_rgb;
            else if(tail_left) disp_RGB = tail_right_rgb;
            else if(tail_right) disp_RGB = tail_left_rgb;
            else disp_RGB = 12'h00F;
        end
        else if(food) begin
            if(!food_type) disp_RGB = food_rgb;
            else disp_RGB = point_food_rgb;
        end
        else disp_RGB = 12'h000;
    end

endmodule
