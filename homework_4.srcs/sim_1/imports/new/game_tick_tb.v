`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: game_tick_tb
// Description: 自检式测试平台。检查节拍发生器：
//              1) 慢速档每 DIV 个时钟产生一个单周期 game_tick；
//              2) 快速档分频比减半；
//              3) 切换回慢速档后周期恢复。
//////////////////////////////////////////////////////////////////////////////////

module game_tick_tb;

    localparam integer DIV = 8;

    reg     clk;
    reg     rst;
    reg     speed_ctrl;
    wire    game_tick;

    integer errors;
    integer interval;

    game_tick #(
        .DIV(DIV)
    ) dut (
        .clk       (clk),
        .rst       (rst),
        .speed_ctrl(speed_ctrl),
        .game_tick (game_tick)
    );

    always #5 clk = ~clk;

    // 测量相邻两个 game_tick 之间相隔的时钟数
    task measure_interval;
        output integer n;
        begin
            @(posedge clk);
            while (!game_tick) @(posedge clk);   // 等到一个 tick
            n = 0;
            @(posedge clk);
            while (!game_tick) begin
                n = n + 1;
                @(posedge clk);
            end
            n = n + 1;                            // 相邻 tick 的时钟间隔
        end
    endtask

    initial begin
        clk        = 1'b0;
        rst        = 1'b1;
        speed_ctrl = 1'b0;
        errors     = 0;

        repeat (4) @(posedge clk);
        rst = 1'b0;
        repeat (3) @(posedge clk);

        $display("---- 慢速档 ----");
        measure_interval(interval);
        if (interval !== DIV) begin
            $display("FAIL: 慢速档周期应为 %0d，实测 %0d", DIV, interval);
            errors = errors + 1;
        end else begin
            $display("  ok  : 慢速档周期 = %0d 个时钟", interval);
        end

        $display("---- 切到快速档 ----");
        speed_ctrl = 1'b1;
        repeat (2 * DIV) @(posedge clk);          // 等切换生效
        measure_interval(interval);
        if (interval !== DIV / 2) begin
            $display("FAIL: 快速档周期应为 %0d，实测 %0d", DIV / 2, interval);
            errors = errors + 1;
        end else begin
            $display("  ok  : 快速档周期 = %0d 个时钟", interval);
        end

        $display("---- 切回慢速档 ----");
        speed_ctrl = 1'b0;
        repeat (2 * DIV) @(posedge clk);
        measure_interval(interval);
        if (interval !== DIV) begin
            $display("FAIL: 切回慢速档后周期应为 %0d，实测 %0d", DIV, interval);
            errors = errors + 1;
        end else begin
            $display("  ok  : 切回慢速档后周期 = %0d 个时钟", interval);
        end

        if (errors == 0)
            $display("PASS: game_tick_tb 全部检查通过");
        else
            $display("FAIL: game_tick_tb 共 %0d 处错误", errors);
        $finish;
    end

    initial begin
        #200000;
        $display("FAIL: game_tick_tb 超时");
        $finish;
    end

endmodule
