`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: input_ctrl_tb
// Description: 自检式测试平台。按新版方向状态机检查：
//              1) 复位/开局默认向右；
//              2) 只禁止与“上一次实际移动方向”相反的按键，其余转向立即生效；
//              3) 同一拍按多个键时按 up > down > left > right 取一个；
//              4) 暂停期间不接收转向，也不更新移动方向基准；
//              5) 与 game_tick 同拍的转向请求，按本拍正在移动的方向判断反方向；
//              6) start 有效时把方向与移动基准一起复位。
//////////////////////////////////////////////////////////////////////////////////

module input_ctrl_tb;

    localparam [1:0] RIGHT = 2'b00,
                     LEFT  = 2'b01,
                     DOWN  = 2'b10,
                     UP    = 2'b11;

    reg       clk;
    reg       rst;
    reg       start;
    reg       game_pause;
    reg       game_tick;
    reg [3:0] direc_in;        // {up, down, left, right}
    wire [1:0] direc_state;

    integer   errors;

    input_ctrl dut (
        .clk        (clk),
        .rst        (rst),
        .start      (start),
        .game_pause (game_pause),
        .game_tick  (game_tick),
        .direc_in   (direc_in),
        .direc_state(direc_state)
    );

    always #5 clk = ~clk;

    // 按住按键两拍后释放
    task press;
        input [3:0] key;
        begin
            @(negedge clk);
            direc_in = key;
            repeat (2) @(negedge clk);
            direc_in = 4'b0000;
            @(negedge clk);
        end
    endtask

    // 一个 game_tick 脉冲
    task tick;
        begin
            @(negedge clk);
            game_tick = 1'b1;
            @(negedge clk);
            game_tick = 1'b0;
            @(negedge clk);
        end
    endtask

    // 按键与 game_tick 出现在同一拍
    task press_with_tick;
        input [3:0] key;
        begin
            @(negedge clk);
            direc_in  = key;
            game_tick = 1'b1;
            @(negedge clk);
            direc_in  = 4'b0000;
            game_tick = 1'b0;
            @(negedge clk);
        end
    endtask

    task expect_state;
        input [1:0] exp;
        input integer tag;
        begin
            if (direc_state !== exp) begin
                $display("FAIL[%0d]: 期望方向 %b，实为 %b", tag, exp, direc_state);
                errors = errors + 1;
            end else begin
                $display("  ok[%0d]: 方向 = %b", tag, direc_state);
            end
        end
    endtask

    initial begin
        clk        = 1'b0;
        rst        = 1'b1;
        start      = 1'b0;
        game_pause = 1'b0;
        game_tick  = 1'b0;
        direc_in   = 4'b0000;
        errors     = 0;

        repeat (4) @(posedge clk);
        rst = 1'b0;
        repeat (2) @(posedge clk);

        $display("---- 复位后默认向右 ----");
        expect_state(RIGHT, 0);

        $display("---- 向右时按左键（反方向）应被忽略 ----");
        press(4'b0010);
        expect_state(RIGHT, 1);

        $display("---- 向右时按上键，立即生效 ----");
        press(4'b1000);
        expect_state(UP, 2);

        $display("---- 移动一拍后，反方向基准变为上 ----");
        tick;
        press(4'b0100);            // 下，是上的反方向
        expect_state(UP, 3);

        $display("---- 向上时按左键，允许立即转向 ----");
        press(4'b0010);
        expect_state(LEFT, 4);

        $display("---- 移动一拍后再按右键应被忽略 ----");
        tick;
        press(4'b0001);
        expect_state(LEFT, 5);

        $display("---- 多键同按：优先级 up > down > left > right ----");
        press(4'b1111);
        expect_state(UP, 6);
        press(4'b0110);            // down + left
        expect_state(DOWN, 7);
        press(4'b0011);            // left + right
        expect_state(LEFT, 8);

        $display("---- 按同方向键保持不变 ----");
        press(4'b0010);
        expect_state(LEFT, 9);

        $display("---- 暂停期间转向被屏蔽 ----");
        game_pause = 1'b1;
        press(4'b1000);
        expect_state(LEFT, 10);
        tick;                      // 暂停中的节拍不应更新移动基准
        game_pause = 1'b0;
        press(4'b0001);            // 右键仍是左的反方向，应被忽略
        expect_state(LEFT, 11);

        $display("---- 与 game_tick 同拍的反方向应被忽略 ----");
        press(4'b1000);            // 先转向，上
        tick;                      // 基准变为上
        press_with_tick(4'b0100);  // 同一拍按反方向下
        expect_state(UP, 12);
        press_with_tick(4'b0010);  // 同一拍按左，垂直方向允许
        expect_state(LEFT, 13);

        $display("---- start 复位方向与移动基准 ----");
        @(negedge clk);
        start = 1'b1;
        repeat (2) @(negedge clk);
        start = 1'b0;
        @(negedge clk);
        expect_state(RIGHT, 14);
        press(4'b0010);            // 左是右的反方向
        expect_state(RIGHT, 15);

        if (errors == 0)
            $display("PASS: input_ctrl_tb 全部检查通过");
        else
            $display("FAIL: input_ctrl_tb 共 %0d 处错误", errors);
        $finish;
    end

    initial begin
        #200000;
        $display("FAIL: input_ctrl_tb 超时");
        $finish;
    end

endmodule
