`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: point_count_tb
// Description: 自检式测试平台。检查计分：
//              1) 蛇长每增加一节计一次分，基础 2 分再加奖励分值；
//              2) 百/十/个位 BCD 输出正确；
//              3) 蛇长不变或减小不计分；
//              4) start 有效时分数清零。
//////////////////////////////////////////////////////////////////////////////////

module point_count_tb;

    reg        clk;
    reg        rst;
    reg        start;
    reg  [4:0] snake_len;
    reg  [3:0] food_point;
    wire [3:0] hundreds;
    wire [3:0] tens;
    wire [3:0] ones;

    integer    errors;
    integer    exp_score;
    integer    i;
    integer    eh, et, eo;

    point_count dut (
        .clk        (clk),
        .rst        (rst),
        .start      (start),
        .snake_len  (snake_len),
        .food_point (food_point),
        .hundreds   (hundreds),
        .tens       (tens),
        .ones       (ones)
    );

    always #5 clk = ~clk;

    task check_score;
        input integer sc;
        input integer tag;
        begin
            eh = (sc / 100) % 10;
            et = (sc / 10) % 10;
            eo = sc % 10;
            #1;
            if (hundreds !== eh[3:0] || tens !== et[3:0] || ones !== eo[3:0]) begin
                $display("FAIL[%0d]: 分数 %0d 应显示 %0d%0d%0d，实为 %0d%0d%0d",
                          tag, sc, eh, et, eo, hundreds, tens, ones);
                errors = errors + 1;
            end else begin
                $display("  ok[%0d]: 分数 %0d 显示为 %0d%0d%0d", tag, sc, hundreds, tens, ones);
            end
        end
    endtask

    initial begin
        clk        = 1'b0;
        rst        = 1'b1;
        start      = 1'b1;
        snake_len  = 5'd2;
        food_point = 4'd0;
        errors     = 0;
        exp_score  = 0;

        repeat (4) @(posedge clk);
        rst   = 1'b0;
        start = 1'b0;
        repeat (2) @(posedge clk);
        check_score(0, 0);

        $display("---- 吃到普通食物 ----");
        snake_len = 5'd3;  exp_score = 2;   repeat (2) @(posedge clk); check_score(exp_score, 1);
        snake_len = 5'd4;  exp_score = 4;   repeat (2) @(posedge clk); check_score(exp_score, 2);

        $display("---- 吃到奖励食物（+10） ----");
        food_point = 4'd10;
        snake_len  = 5'd5;  exp_score = 16; repeat (2) @(posedge clk); check_score(exp_score, 3);

        $display("---- 连续进食直到百位变化 ----");
        for (i = 0; i < 20; i = i + 1) begin
            snake_len = snake_len + 5'd1;
            exp_score = exp_score + 12;
            repeat (2) @(posedge clk);
        end
        check_score(exp_score, 4);

        $display("---- 蛇长减少不应计分 ----");
        snake_len = 5'd3;
        repeat (3) @(posedge clk);
        check_score(exp_score, 5);

        $display("---- start 清零 ----");
        @(negedge clk);
        snake_len = 5'd2;          // 与 start 同时回到初始长度，模拟真实开局
        start     = 1'b1;
        repeat (2) @(posedge clk);
        start = 1'b0;
        repeat (2) @(posedge clk);
        check_score(0, 6);

        if (errors == 0)
            $display("PASS: point_count_tb 全部检查通过");
        else
            $display("FAIL: point_count_tb 共 %0d 处错误", errors);
        $finish;
    end

    initial begin
        #100000;
        $display("FAIL: point_count_tb 超时");
        $finish;
    end

endmodule
