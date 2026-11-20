`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: food_point_tb
// Description: 自检式测试平台。检查奖励食物的分值与时序：
//              1) 奖励食物出现时分值为 10；
//              2) 每满 1 s 分值减 1；
//              3) 吃到后停止计时、分值保持；
//              4) 超过 10 s 未被吃到时给出 fail_get 回收脉冲。
//              仿真时把 CLK_HZ 缩小为 1000，使 1 s = 1000 个时钟。
//////////////////////////////////////////////////////////////////////////////////

module food_point_tb;

    localparam integer CLK_HZ     = 1000;
    localparam integer T_LIMIT    = CLK_HZ * 10;   // 10000 个时钟
    localparam integer T_INTERVAL = T_LIMIT / 10;  // 1000 个时钟

    reg        clk;
    reg        rst;
    reg        food_type;
    reg        eat;
    wire [3:0] food_point;
    wire       fail_get;
    wire [31:0] elapsed_count;

    integer    errors;
    integer    fail_cnt;
    integer    i;

    food_point #(
        .CLK_HZ(CLK_HZ)
    ) dut (
        .clk          (clk),
        .rst          (rst),
        .food_type    (food_type),
        .eat          (eat),
        .food_point   (food_point),
        .fail_get     (fail_get),
        .elapsed_count(elapsed_count)
    );

    always #5 clk = ~clk;

    always @(posedge clk)
        if (fail_get) fail_cnt = fail_cnt + 1;

    initial begin
        clk       = 1'b0;
        rst       = 1'b1;
        food_type = 1'b0;
        eat       = 1'b0;
        errors    = 0;
        fail_cnt  = 0;

        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (3) @(posedge clk);

        $display("---- 无奖励食物时分值为 0 ----");
        if (food_point !== 4'd0) begin
            $display("FAIL: 无奖励食物时 food_point 应为 0，实为 %0d", food_point);
            errors = errors + 1;
        end

        $display("---- 奖励食物出现 ----");
        @(negedge clk);
        food_type = 1'b1;
        repeat (4) @(posedge clk);
        if (food_point !== 4'd10) begin
            $display("FAIL: 奖励食物出现时应为 10 分，实为 %0d", food_point);
            errors = errors + 1;
        end else begin
            $display("  ok  : 初始分值 10");
        end

        $display("---- 经过 1 s ----");
        repeat (T_INTERVAL + 20) @(posedge clk);
        if (food_point !== 4'd9) begin
            $display("FAIL: 1 s 后应为 9 分，实为 %0d", food_point);
            errors = errors + 1;
        end else begin
            $display("  ok  : 1 s 后 9 分");
        end

        $display("---- 再经过 1 s ----");
        repeat (T_INTERVAL) @(posedge clk);
        if (food_point !== 4'd8) begin
            $display("FAIL: 2 s 后应为 8 分，实为 %0d", food_point);
            errors = errors + 1;
        end else begin
            $display("  ok  : 2 s 后 8 分");
        end

        $display("---- 吃到奖励食物 ----");
        @(negedge clk);
        eat = 1'b1;
        @(negedge clk);
        eat = 1'b0;
        repeat (T_INTERVAL + 50) @(posedge clk);
        if (food_point !== 4'd8) begin
            $display("FAIL: 吃到后分值应保持 8，实为 %0d", food_point);
            errors = errors + 1;
        end else begin
            $display("  ok  : 吃到后停止计时，分值保持 8");
        end

        $display("---- 超时未吃到 ----");
        @(negedge clk);
        food_type = 1'b0;
        repeat (5) @(posedge clk);
        @(negedge clk);
        food_type = 1'b1;
        repeat (5) @(posedge clk);
        if (food_point !== 4'd10) begin
            $display("FAIL: 重新出现时应回到 10 分，实为 %0d", food_point);
            errors = errors + 1;
        end
        fail_cnt = 0;
        repeat (T_LIMIT + 200) @(posedge clk);
        if (fail_cnt < 1) begin
            $display("FAIL: 10 s 到期未产生 fail_get");
            errors = errors + 1;
        end else if (food_point !== 4'd0) begin
            $display("FAIL: 超时后分值应清零，实为 %0d", food_point);
            errors = errors + 1;
        end else begin
            $display("  ok  : 超时回收，fail_get 触发 %0d 次", fail_cnt);
        end

        if (errors == 0)
            $display("PASS: food_point_tb 全部检查通过");
        else
            $display("FAIL: food_point_tb 共 %0d 处错误", errors);
        $finish;
    end

    initial begin
        #2000000;
        $display("FAIL: food_point_tb 超时");
        $finish;
    end

endmodule
