`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: uart_decode_tb
// Description: 自检式测试平台。直接向译码器送入字节，检查：
//              1) W/A/S/D 与空格、J 的映射；
//              2) 方向键的 ESC 序列（ESC [ X 与 ESC O X）；
//              3) 孤立 0x1B、非法序列与非映射字节不产生脉冲；
//              4) 所有脉冲只保持一个时钟周期，speed_ctrl 为电平翻转。
//////////////////////////////////////////////////////////////////////////////////

module uart_decode_tb;

    reg        clk;
    reg        rst;
    reg  [7:0] rx_data;
    reg        rx_valid;
    wire       up_pulse;
    wire       down_pulse;
    wire       left_pulse;
    wire       right_pulse;
    wire       start_pulse;
    wire       speed_ctrl;

    integer    errors;

    uart_decode dut (
        .clk        (clk),
        .rst        (rst),
        .rx_data    (rx_data),
        .rx_valid   (rx_valid),
        .up_pulse   (up_pulse),
        .down_pulse (down_pulse),
        .left_pulse (left_pulse),
        .right_pulse(right_pulse),
        .start_pulse(start_pulse),
        .speed_ctrl (speed_ctrl)
    );

    always #5 clk = ~clk;

    // 送入一个字节（rx_valid 只拉高一拍）
    task send_byte;
        input [7:0] b;
        begin
            @(negedge clk);
            rx_data  = b;
            rx_valid = 1'b1;
            @(negedge clk);
            rx_valid = 1'b0;
        end
    endtask

    // 检查脉冲组合，并确认下一拍全部回零
    task check_pulses;
        input e_up, e_down, e_left, e_right, e_start;
        begin
            if (up_pulse !== e_up || down_pulse !== e_down ||
                left_pulse !== e_left || right_pulse !== e_right ||
                start_pulse !== e_start) begin
                $display("FAIL: 脉冲不符 up=%b down=%b left=%b right=%b start=%b (期望 %b%b%b%b%b)",
                          up_pulse, down_pulse, left_pulse, right_pulse, start_pulse,
                          e_up, e_down, e_left, e_right, e_start);
                errors = errors + 1;
            end
            @(negedge clk);
            if (up_pulse || down_pulse || left_pulse || right_pulse || start_pulse) begin
                $display("FAIL: 脉冲宽度超过一个时钟周期");
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk      = 1'b0;
        rst      = 1'b1;
        rx_data  = 8'h00;
        rx_valid = 1'b0;
        errors   = 0;
        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (3) @(posedge clk);

        $display("---- WASD ----");
        send_byte(8'h41); check_pulses(0,0,1,0,0);   // A -> 左
        send_byte(8'h44); check_pulses(0,0,0,1,0);   // D -> 右
        send_byte(8'h57); check_pulses(1,0,0,0,0);   // W -> 上
        send_byte(8'h53); check_pulses(0,1,0,0,0);   // S -> 下
        send_byte(8'h20); check_pulses(0,0,0,0,1);   // 空格 -> 开始/暂停

        $display("---- 未映射字节 ----");
        send_byte(8'h0A); check_pulses(0,0,0,0,0);   // 换行忽略
        send_byte(8'h31); check_pulses(0,0,0,0,0);   // '1' 忽略

        $display("---- 孤立 ESC 与非法转义 ----");
        send_byte(8'h1B); check_pulses(0,0,0,0,0);   // 单独 ESC
        send_byte(8'h41); check_pulses(0,0,0,0,0);   // ESC 后面不是 [ 或 O

        $display("---- 方向键 ESC [ X ----");
        send_byte(8'h1B);
        send_byte(8'h5B);
        send_byte(8'h41); check_pulses(1,0,0,0,0);   // 上
        send_byte(8'h1B);
        send_byte(8'h5B);
        send_byte(8'h42); check_pulses(0,1,0,0,0);   // 下
        send_byte(8'h1B);
        send_byte(8'h5B);
        send_byte(8'h43); check_pulses(0,0,0,1,0);   // 右
        send_byte(8'h1B);
        send_byte(8'h5B);
        send_byte(8'h44); check_pulses(0,0,1,0,0);   // 左

        $display("---- 方向键 ESC O X（SS3） ----");
        send_byte(8'h1B);
        send_byte(8'h4F);
        send_byte(8'h41); check_pulses(1,0,0,0,0);

        $display("---- 速度切换 J ----");
        if (speed_ctrl !== 1'b0) begin
            $display("FAIL: speed_ctrl 初值应为 0");
            errors = errors + 1;
        end
        send_byte(8'h4A); check_pulses(0,0,0,0,0);
        if (speed_ctrl !== 1'b1) begin
            $display("FAIL: 第一次按 J 后 speed_ctrl 应为 1（实为 %b）", speed_ctrl);
            errors = errors + 1;
        end else begin
            $display("  ok  : J 切换到快速档");
        end
        send_byte(8'h6A); check_pulses(0,0,0,0,0);   // 小写 j
        if (speed_ctrl !== 1'b0) begin
            $display("FAIL: 第二次按 J 后 speed_ctrl 应回到 0（实为 %b）", speed_ctrl);
            errors = errors + 1;
        end else begin
            $display("  ok  : J 切回慢速档");
        end

        if (errors == 0)
            $display("PASS: uart_decode_tb 全部检查通过");
        else
            $display("FAIL: uart_decode_tb 共 %0d 处错误", errors);
        $finish;
    end

    initial begin
        #1000000;
        $display("FAIL: uart_decode_tb 超时");
        $finish;
    end

endmodule
