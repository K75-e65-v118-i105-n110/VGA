`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: uart_dirctrl_tb
// Description: 自检式测试平台。从串口引脚逐位送入按键字节，检查“接收 + 译码”
//              整条输入通道是否能产生正确的方向脉冲与开始脉冲。
//              位周期缩短为 10 个时钟以加快仿真。
//              脉冲出现在一帧结束之前，因此用计数器统计脉冲个数，避免漏采。
//////////////////////////////////////////////////////////////////////////////////

module uart_dirctrl_tb;

    localparam integer CLK_HZ     = 100_000_000;
    localparam integer BAUD       = 10_000_000;
    localparam integer BIT_CYCLES = 10;

    reg        clk;
    reg        rst;
    reg        rx;
    wire       up_pulse;
    wire       down_pulse;
    wire       left_pulse;
    wire       right_pulse;
    wire       start_pulse;
    wire       speed_ctrl;

    integer    errors;
    integer    cnt_up, cnt_down, cnt_left, cnt_right, cnt_start;

    uart_dirctrl #(
        .CLK_HZ(CLK_HZ),
        .BAUD  (BAUD)
    ) dut (
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

    always #5 clk = ~clk;

    // 统计脉冲个数
    always @(posedge clk) begin
        if (rst) begin
            cnt_up = 0; cnt_down = 0; cnt_left = 0; cnt_right = 0; cnt_start = 0;
        end else begin
            if (up_pulse)    cnt_up    = cnt_up + 1;
            if (down_pulse)  cnt_down  = cnt_down + 1;
            if (left_pulse)  cnt_left  = cnt_left + 1;
            if (right_pulse) cnt_right = cnt_right + 1;
            if (start_pulse) cnt_start = cnt_start + 1;
        end
    end

    task clear_counts;
        begin
            cnt_up = 0; cnt_down = 0; cnt_left = 0; cnt_right = 0; cnt_start = 0;
        end
    endtask

    task send_byte;
        input [7:0] data;
        integer     i;
        begin
            rx = 1'b0;
            repeat (BIT_CYCLES) @(posedge clk);
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                repeat (BIT_CYCLES) @(posedge clk);
            end
            rx = 1'b1;
            repeat (BIT_CYCLES) @(posedge clk);
        end
    endtask

    // 检查这一帧产生的脉冲组合
    task check_after_send;
        input e_up, e_down, e_left, e_right, e_start;
        input integer tag;
        begin
            repeat (10) @(posedge clk);
            #1;
            if (cnt_up !== e_up || cnt_down !== e_down || cnt_left !== e_left ||
                cnt_right !== e_right || cnt_start !== e_start) begin
                $display("FAIL[%0d]: 脉冲计数 up=%0d down=%0d left=%0d right=%0d start=%0d (期望 %0d%0d%0d%0d%0d)",
                          tag, cnt_up, cnt_down, cnt_left, cnt_right, cnt_start,
                          e_up, e_down, e_left, e_right, e_start);
                errors = errors + 1;
            end else begin
                $display("  ok[%0d]: 脉冲正确", tag);
            end
            clear_counts;
        end
    endtask

    initial begin
        clk    = 1'b0;
        rst    = 1'b1;
        rx     = 1'b1;
        errors = 0;

        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (3) @(posedge clk);
        clear_counts;

        $display("---- 串口送 'A'（左） ----");
        send_byte(8'h41); check_after_send(0,0,1,0,0, 0);

        $display("---- 串口送 'W'（上） ----");
        send_byte(8'h57); check_after_send(1,0,0,0,0, 1);

        $display("---- 串口送空格（开始） ----");
        send_byte(8'h20); check_after_send(0,0,0,0,1, 2);

        $display("---- 串口送 ESC [ C（右） ----");
        send_byte(8'h1B);
        send_byte(8'h5B);
        send_byte(8'h43); check_after_send(0,0,0,1,0, 3);

        $display("---- 串口送 'S'（下） ----");
        send_byte(8'h53); check_after_send(0,1,0,0,0, 4);

        $display("---- 串口送 'J'（速度切换） ----");
        send_byte(8'h4A);
        repeat (5) @(posedge clk);
        if (speed_ctrl !== 1'b1) begin
            $display("FAIL: J 未使 speed_ctrl 翻转（实为 %b）", speed_ctrl);
            errors = errors + 1;
        end else begin
            $display("  ok  : speed_ctrl 已翻转");
        end

        if (errors == 0)
            $display("PASS: uart_dirctrl_tb 全部检查通过");
        else
            $display("FAIL: uart_dirctrl_tb 共 %0d 处错误", errors);
        $finish;
    end

    initial begin
        #2000000;
        $display("FAIL: uart_dirctrl_tb 超时");
        $finish;
    end

endmodule
