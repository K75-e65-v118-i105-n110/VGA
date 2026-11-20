`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: food_gen_tb
// Description: 自检式测试平台。检查食物生成：
//              1) 生成的坐标落在游戏区内（1..30, 1..22）；
//              2) 不会落在蛇身任何一节上，也不会落在墙体上；
//              3) 每刷新 8 次恰好出现 1 次奖励食物（food_type=1）。
//////////////////////////////////////////////////////////////////////////////////

module food_gen_tb;

    reg         clk;
    reg         rst;
    reg         refresh_food;
    reg         start;
    reg  [449:0] wall_x;
    reg  [449:0] wall_y;
    reg  [159:0] snake_x;
    reg  [159:0] snake_y;
    reg  [4:0]  snake_len;
    wire [4:0]  food_x;
    wire [4:0]  food_y;
    wire        food_type;

    integer     errors;
    integer     i;
    integer     bonus;
    integer     j;

    food_gen dut (
        .clk         (clk),
        .rst         (rst),
        .refresh_food(refresh_food),
        .start       (start),
        .wall_x      (wall_x),
        .wall_y      (wall_y),
        .snake_x     (snake_x),
        .snake_y     (snake_y),
        .snake_len   (snake_len),
        .food_x      (food_x),
        .food_y      (food_y),
        .food_type   (food_type)
    );

    always #5 clk = ~clk;

    // 检查当前食物坐标是否合法
    task check_food;
        input integer tag;
        integer k;
        begin
            if (food_x < 1 || food_x > 30 || food_y < 1 || food_y > 22) begin
                $display("FAIL[%0d]: 食物越界 (%0d,%0d)", tag, food_x, food_y);
                errors = errors + 1;
            end
            for (k = 0; k <= snake_len; k = k + 1) begin
                if (snake_x[k*5 +: 5] == food_x && snake_y[k*5 +: 5] == food_y) begin
                    $display("FAIL[%0d]: 食物落在蛇身 (%0d,%0d)", tag, food_x, food_y);
                    errors = errors + 1;
                end
            end
            for (k = 0; k < 90; k = k + 1) begin
                if (wall_x[k*5 +: 5] == food_x && wall_y[k*5 +: 5] == food_y) begin
                    $display("FAIL[%0d]: 食物落在墙体 (%0d,%0d)", tag, food_x, food_y);
                    errors = errors + 1;
                end
            end
        end
    endtask

    initial begin
        clk          = 1'b0;
        rst          = 1'b1;
        refresh_food = 1'b0;
        start        = 1'b0;
        errors       = 0;
        bonus        = 0;

        // 墙体表：只放一块砖 (20,15)，其余为 (0,0)
        wall_x = 450'd0;
        wall_y = 450'd0;
        wall_x[4:0] = 5'd20;
        wall_y[4:0] = 5'd15;

        // 蛇身：三节，位于第 10 行
        snake_x = 160'd0;
        snake_y = 160'd0;
        snake_x[4:0]   = 5'd14;  snake_y[4:0]   = 5'd10;
        snake_x[9:5]   = 5'd13;  snake_y[9:5]   = 5'd10;
        snake_x[14:10] = 5'd12;  snake_y[14:10] = 5'd10;
        snake_len     = 5'd2;

        repeat (4) @(posedge clk);
        rst = 1'b0;
        repeat (100) @(posedge clk);          // 等待第一枚食物生成

        $display("---- 初始食物 (%0d,%0d) type=%b ----", food_x, food_y, food_type);
        check_food(0);
        if (food_type !== 1'b0) begin
            $display("FAIL: 第一枚食物不应是奖励食物");
            errors = errors + 1;
        end

        $display("---- 连续刷新 24 次 ----");
        for (i = 0; i < 24; i = i + 1) begin
            @(negedge clk);
            refresh_food = 1'b1;
            @(negedge clk);
            refresh_food = 1'b0;
            repeat (40) @(posedge clk);       // 等待新食物落定
            check_food(i + 1);
            if (food_type === 1'b1)
                bonus = bonus + 1;
        end

        if (bonus !== 3) begin
            $display("FAIL: 24 次刷新中奖励食物应为 3 次，实测 %0d 次", bonus);
            errors = errors + 1;
        end else begin
            $display("  ok  : 24 次刷新中出现 %0d 次奖励食物", bonus);
        end

        if (errors == 0)
            $display("PASS: food_gen_tb 全部检查通过");
        else
            $display("FAIL: food_gen_tb 共 %0d 处错误", errors);
        $finish;
    end

    initial begin
        #500000;
        $display("FAIL: food_gen_tb 超时");
        $finish;
    end

endmodule
