`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: game_rule_tb
// Description: 自检式测试平台。检查游戏规则模块：
//              1) 复位/开局后蛇身位置与长度正确；
//              2) 每个节拍沿方向前进一格，越界后从对侧回环；
//              3) 头部碰墙时给出 game_over；
//              4) 吃到食物后蛇身增长，且长度达到 MAX_LEN 时结束。
//              为便于观察，把 MAX_LEN 缩小为 3（吃到一枚就达到上限），
//              并用 force 把食物放到指定位置，使进食过程可以确定地复现。
//////////////////////////////////////////////////////////////////////////////////

module game_rule_tb;

    localparam [1:0] RIGHT = 2'b00,
                     LEFT  = 2'b01,
                     DOWN  = 2'b10,
                     UP    = 2'b11;
    localparam MAX_LEN = 3;

    reg         clk;
    reg         rst;
    reg         game_tick;
    reg         start;
    reg         game_pause;
    reg  [1:0]  direc_state;
    reg  [449:0] wall_x;
    reg  [449:0] wall_y;
    wire [159:0] snake_x;
    wire [159:0] snake_y;
    wire [4:0]  food_x;
    wire [4:0]  food_y;
    wire [4:0]  snake_len;
    wire        game_over;
    wire        food_type;
    wire [3:0]  food_point;
    wire [31:0] elapsed_count;

    integer     errors;
    integer     steps;

    game_rule #(
        .MAX_LEN(MAX_LEN)
    ) dut (
        .clk          (clk),
        .rst          (rst),
        .game_tick    (game_tick),
        .start        (start),
        .game_pause   (game_pause),
        .direc_state  (direc_state),
        .wall_x       (wall_x),
        .wall_y       (wall_y),
        .snake_x      (snake_x),
        .snake_y      (snake_y),
        .food_x       (food_x),
        .food_y       (food_y),
        .snake_len    (snake_len),
        .food_type    (food_type),
        .food_point   (food_point),
        .elapsed_count(elapsed_count),
        .game_over    (game_over)
    );

    always #5 clk = ~clk;

    // 产生一个游戏节拍，并在节拍前给出方向
    task step;
        input [1:0] dir;
        begin
            @(negedge clk);
            direc_state = dir;
            game_tick   = 1'b1;
            @(negedge clk);
            game_tick   = 1'b0;
            repeat (2) @(posedge clk);
        end
    endtask

    // 开局：start 有效时蛇身回到初始位置
    task do_start;
        begin
            @(negedge clk);
            start = 1'b1;
            repeat (3) @(negedge clk);
            start = 1'b0;
            repeat (2) @(posedge clk);
        end
    endtask

    task check_head;
        input [4:0] ex;
        input [4:0] ey;
        input integer tag;
        begin
            if (snake_x[4:0] !== ex || snake_y[4:0] !== ey) begin
                $display("FAIL[%0d]: 头部应为 (%0d,%0d)，实为 (%0d,%0d)",
                          tag, ex, ey, snake_x[4:0], snake_y[4:0]);
                errors = errors + 1;
            end else begin
                $display("  ok[%0d]: 头部 = (%0d,%0d)", tag, snake_x[4:0], snake_y[4:0]);
            end
        end
    endtask

    initial begin
        clk         = 1'b0;
        rst         = 1'b1;
        game_tick   = 1'b0;
        start       = 1'b0;
        game_pause  = 1'b0;
        direc_state = RIGHT;
        wall_x      = 450'd0;
        wall_y      = 450'd0;
        errors      = 0;

        repeat (4) @(posedge clk);
        rst = 1'b0;
        repeat (2) @(posedge clk);

        // 把食物固定到 (1,1)，避免随机位置影响移动测试
        force dut.food_x = 5'd1;
        force dut.food_y = 5'd1;

        $display("---- 开局后的初始蛇身 ----");
        do_start;
        if (snake_len !== 5'd2) begin
            $display("FAIL: 初始长度索引应为 2，实为 %0d", snake_len);
            errors = errors + 1;
        end
        check_head(5'd14, 5'd10, 0);

        $display("---- 向右前进一格 ----");
        step(RIGHT);
        check_head(5'd15, 5'd10, 1);

        $display("---- 一直向右，检查 31 -> 0 回环 ----");
        steps = 0;
        while (snake_x[4:0] != 5'd31 && steps < 40) begin
            step(RIGHT);
            steps = steps + 1;
        end
        check_head(5'd31, 5'd10, 2);
        step(RIGHT);
        check_head(5'd0, 5'd10, 3);

        $display("---- 向上，检查 1 -> 22 回环 ----");
        steps = 0;
        while (snake_y[4:0] != 5'd1 && steps < 40) begin
            step(UP);
            steps = steps + 1;
        end
        check_head(5'd0, 5'd1, 4);
        step(UP);
        check_head(5'd0, 5'd22, 5);

        $display("---- 撞墙 ----");
        do_start;
        wall_x[4:0] = 5'd15;
        wall_y[4:0] = 5'd10;
        step(RIGHT);
        check_head(5'd15, 5'd10, 6);
        repeat (3) @(posedge clk);
        if (game_over !== 1'b1) begin
            $display("FAIL: 头部撞墙后 game_over 应为 1，实为 %b", game_over);
            errors = errors + 1;
        end else begin
            $display("  ok  : 撞墙后 game_over = 1");
        end

        $display("---- 吃到食物（长度达到上限） ----");
        do_start;
        wall_x = 450'd0;
        wall_y = 450'd0;
        force dut.food_x = 5'd15;
        force dut.food_y = 5'd10;
        step(RIGHT);
        check_head(5'd15, 5'd10, 7);
        if (snake_len !== 5'd3) begin
            $display("FAIL: 吃到后长度索引应为 3，实为 %0d", snake_len);
            errors = errors + 1;
        end else begin
            $display("  ok  : 吃到后长度索引 = 3");
        end
        // 增长的一节应复制原尾坐标 (12,10)，落在索引 3（bit 19:15）
        if (snake_x[19:15] !== 5'd12 || snake_y[19:15] !== 5'd10) begin
            $display("FAIL: 新增尾部应为 (12,10)，实为 (%0d,%0d)",
                      snake_x[19:15], snake_y[19:15]);
            errors = errors + 1;
        end else begin
            $display("  ok  : 尾部追加 (12,10)");
        end
        repeat (3) @(posedge clk);
        if (game_over !== 1'b1) begin
            $display("FAIL: 长度到达 MAX_LEN 后 game_over 应为 1，实为 %b", game_over);
            errors = errors + 1;
        end else begin
            $display("  ok  : 长度达到上限后 game_over = 1");
        end

        release dut.food_x;
        release dut.food_y;

        if (errors == 0)
            $display("PASS: game_rule_tb 全部检查通过");
        else
            $display("FAIL: game_rule_tb 共 %0d 处错误", errors);
        $finish;
    end

    initial begin
        #500000;
        $display("FAIL: game_rule_tb 超时");
        $finish;
    end

endmodule
