`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: game_core_tb
// Description: 自检式集成测试平台。把“串口输入 + 游戏状态机 + 方向状态机 +
//              节拍 + 规则 + 计分”按顶层的方式连起来（不含 VGA 渲染，因此不需要
//              ROM 模型），从串口引脚送入按键，检查整条游戏链路：
//              1) 开局按空格后离开 START，蛇开始移动；
//              2) 串口送入方向键后，蛇按新方向前进；
//              3) 暂停时蛇停止移动，再按空格后恢复；
//              4) 分数初值为 0。
//////////////////////////////////////////////////////////////////////////////////

module game_core_tb;

    localparam integer CLK_HZ     = 100_000_000;
    localparam integer BAUD       = 10_000_000;
    localparam integer BIT_CYCLES = 10;
    localparam integer DIV        = 32;         // 游戏节拍：32 个时钟
    localparam [1:0]   UP = 2'b11, DOWN = 2'b10, LEFT = 2'b01, RIGHT = 2'b00;

    reg         clk;
    reg         rst;
    reg         rx;

    wire        up_pulse, down_pulse, left_pulse, right_pulse;
    wire        start_pulse, speed_ctrl;
    wire [1:0]  direc_state;
    wire        start, game_pause, game_tick, game_over;
    wire [159:0] snake_x, snake_y;
    wire [4:0]  food_x, food_y, snake_len;
    wire        food_type;
    wire [3:0]  food_point;
    wire [31:0] elapsed_count;
    wire [3:0]  hundreds, tens, ones;

    integer     errors;
    integer     i;
    reg [4:0]   y0;

    // ---------------- 串口输入通道 ----------------
    uart_dirctrl #(
        .CLK_HZ(CLK_HZ),
        .BAUD  (BAUD)
    ) u_uart (
        .clk        (clk),
        .rst        (rst),
        .uart_rx    (rx),
        .up_pulse   (up_pulse),
        .down_pulse (down_pulse),
        .left_pulse (left_pulse),
        .right_pulse(right_pulse),
        .start_pulse(start_pulse),
        .speed_ctrl (speed_ctrl)
    );

    // ---------------- 游戏状态机 ----------------
    start_end u_state (
        .clk        (clk),
        .rst        (rst),
        .game_over  (game_over),
        .start_pause(start_pulse),
        .game_pause (game_pause),
        .start      (start)
    );

    // ---------------- 方向状态机 ----------------
    input_ctrl u_dir (
        .clk        (clk),
        .rst        (rst),
        .start      (start),
        .game_pause (game_pause),
        .direc_in   ({up_pulse, down_pulse, left_pulse, right_pulse}),
        .direc_state(direc_state)
    );

    // ---------------- 游戏节拍 ----------------
    game_tick #(
        .DIV(DIV)
    ) u_tick (
        .clk       (clk),
        .rst       (rst),
        .speed_ctrl(speed_ctrl),
        .game_tick (game_tick)
    );

    // ---------------- 规则核心 ----------------
    game_rule #(
        .MAX_LEN(5'd31)
    ) u_rule (
        .clk          (clk),
        .rst          (rst),
        .game_tick    (game_tick),
        .start        (start),
        .game_pause   (game_pause),
        .direc_state  (direc_state),
        .wall_x       (450'd0),
        .wall_y       (450'd0),
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

    // ---------------- 计分 ----------------
    point_count u_score (
        .clk       (clk),
        .rst       (rst),
        .start     (start),
        .snake_len (snake_len),
        .food_point(food_point),
        .hundreds  (hundreds),
        .tens      (tens),
        .ones      (ones)
    );

    always #5 clk = ~clk;

    // 从串口引脚发送一个字节
    task send_byte;
        input [7:0] data;
        integer     k;
        begin
            rx = 1'b0;
            repeat (BIT_CYCLES) @(posedge clk);
            for (k = 0; k < 8; k = k + 1) begin
                rx = data[k];
                repeat (BIT_CYCLES) @(posedge clk);
            end
            rx = 1'b1;
            repeat (BIT_CYCLES) @(posedge clk);
        end
    endtask

    // 等待下一个游戏节拍，并多等半拍让蛇身完成更新
    task wait_move;
        begin
            @(negedge clk);
            while (!game_tick) @(negedge clk);
            @(negedge clk);
        end
    endtask

    task check_dir;
        input [1:0] exp;
        input integer tag;
        begin
            if (direc_state !== exp) begin
                $display("FAIL[%0d]: 方向应为 %b，实为 %b", tag, exp, direc_state);
                errors = errors + 1;
            end else begin
                $display("  ok[%0d]: 方向 = %b", tag, direc_state);
            end
        end
    endtask

    initial begin
        clk    = 1'b0;
        rst    = 1'b1;
        rx     = 1'b1;
        errors = 0;

        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (5) @(posedge clk);

        $display("---- 复位后处于 START ----");
        if (start !== 1'b1 || game_pause !== 1'b0) begin
            $display("FAIL: 复位后应在 START（start=1, game_pause=0），实为 start=%b pause=%b",
                      start, game_pause);
            errors = errors + 1;
        end else begin
            $display("  ok  : start = 1");
        end
        if (hundreds !== 4'd0 || tens !== 4'd0 || ones !== 4'd0) begin
            $display("FAIL: 初始分数应为 0，实为 %0d%0d%0d", hundreds, tens, ones);
            errors = errors + 1;
        end

        $display("---- 串口送空格开始游戏 ----");
        send_byte(8'h20);
        for (i = 0; i < 60; i = i + 1) begin
            @(posedge clk);
            if (start === 1'b0) i = 60;
        end
        if (start !== 1'b0) begin
            $display("FAIL: 按空格后仍停留在 START");
            errors = errors + 1;
        end else begin
            $display("  ok  : 已进入 GAME_ON");
        end

        $display("---- 串口送 'W' 改为向上 ----");
        send_byte(8'h57);
        repeat (5) @(posedge clk);
        check_dir(UP, 0);

        $display("---- 向上移动一格 ----");
        wait_move;                       // 对齐到节拍
        y0 = snake_y[4:0];
        wait_move;                       // 下一个节拍应向上走一格
        if (snake_y[4:0] !== ((y0 == 5'd1) ? 5'd22 : (y0 - 5'd1))) begin
            $display("FAIL: 向上移动后 y 应由 %0d 变为 %0d，实为 %0d",
                      y0, (y0 == 5'd1) ? 5'd22 : (y0 - 5'd1), snake_y[4:0]);
            errors = errors + 1;
        end else begin
            $display("  ok  : y 由 %0d 变为 %0d", y0, snake_y[4:0]);
        end

        $display("---- 串口送 'A' 改为向左 ----");
        send_byte(8'h41);
        repeat (5) @(posedge clk);
        check_dir(LEFT, 1);

        $display("---- 空格暂停，蛇应停止 ----");
        send_byte(8'h20);
        repeat (5) @(posedge clk);
        if (game_pause !== 1'b1) begin
            $display("FAIL: 暂停后 game_pause 应为 1，实为 %b", game_pause);
            errors = errors + 1;
        end
        y0 = snake_y[4:0];
        repeat (4 * DIV) @(posedge clk);      // 至少 4 个节拍
        if (snake_y[4:0] !== y0) begin
            $display("FAIL: 暂停期间蛇不应移动（y 由 %0d 变为 %0d）", y0, snake_y[4:0]);
            errors = errors + 1;
        end else begin
            $display("  ok  : 暂停期间位置保持 (%0d,%0d)", snake_x[4:0], snake_y[4:0]);
        end

        $display("---- 再按空格恢复 ----");
        send_byte(8'h20);
        repeat (5) @(posedge clk);
        if (game_pause !== 1'b0) begin
            $display("FAIL: 恢复后 game_pause 应为 0，实为 %b", game_pause);
            errors = errors + 1;
        end
        y0 = snake_y[4:0];
        repeat (4 * DIV) @(posedge clk);
        if (snake_y[4:0] === y0 && snake_x[4:0] === 5'd0) begin
            $display("FAIL: 恢复后蛇未移动");
            errors = errors + 1;
        end else begin
            $display("  ok  : 恢复后蛇继续移动");
        end

        if (errors == 0)
            $display("PASS: game_core_tb 全部检查通过");
        else
            $display("FAIL: game_core_tb 共 %0d 处错误", errors);
        $finish;
    end

    initial begin
        #2000000;
        $display("FAIL: game_core_tb 超时");
        $finish;
    end

endmodule
