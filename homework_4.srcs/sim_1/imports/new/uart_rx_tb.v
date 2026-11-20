`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: uart_rx_tb
// Description: 自检式测试平台。按 8N1 时序逐位翻转 uart_rx，检查：
//              1) 正常字节的接收与还原；
//              2) 短毛刺不会被误当成起始位；
//              3) 停止位错误时整帧丢弃；
//              4) 错误帧之后仍能正常接收。
//              仿真时把位周期缩短为 10 个时钟，仅为加快仿真，逻辑与上板一致。
//              注意：data_valid 出现在停止位中途，早于一帧发完的时刻，
//              所以每帧都在发送前记录计数快照，发送后比对新增的接收次数。
//////////////////////////////////////////////////////////////////////////////////

module uart_rx_tb;

    localparam integer CLK_HZ     = 100_000_000;
    localparam integer BAUD       = 10_000_000;   // 10 个时钟一位
    localparam integer BIT_CYCLES = 10;

    reg         clk;
    reg         rst;
    reg         rx;
    wire [7:0]  data_out;
    wire        data_valid;

    integer     errors;
    integer     rx_count;
    integer     base_g;
    reg  [7:0]  rx_last;

    uart_rx #(
        .CLK_HZ(CLK_HZ),
        .BAUD  (BAUD)
    ) dut (
        .clk       (clk),
        .rst       (rst),
        .uart_rx   (rx),
        .data_out  (data_out),
        .data_valid(data_valid)
    );

    always #5 clk = ~clk;

    // 常驻采样：记录每一次有效接收，供后续比对
    always @(posedge clk) begin
        if (rst) begin
            rx_count = 0;
            rx_last  = 8'h00;
        end else if (data_valid) begin
            rx_count = rx_count + 1;
            rx_last  = data_out;
        end
    end

    // 发送一帧：起始位 + 8 位数据（LSB 在前）+ 停止位
    task send_byte;
        input [7:0] data;
        input       stop_bit;
        integer     i;
        begin
            rx = 1'b0;                              // 起始位
            repeat (BIT_CYCLES) @(posedge clk);
            for (i = 0; i < 8; i = i + 1) begin     // 数据位
                rx = data[i];
                repeat (BIT_CYCLES) @(posedge clk);
            end
            rx = stop_bit;                          // 停止位
            repeat (BIT_CYCLES) @(posedge clk);
            rx = 1'b1;
        end
    endtask

    // 发送一帧并核对：应恰好收到一次 exp
    task send_check;
        input [7:0] data;
        input [7:0] exp;
        integer base;
        begin
            base = rx_count;
            send_byte(data, 1'b1);
            #1;
            if (rx_count !== base + 1) begin
                $display("FAIL: 发送 %02h 后新增接收 %0d 次（应为 1 次）",
                          data, rx_count - base);
                errors = errors + 1;
            end else if (rx_last !== exp) begin
                $display("FAIL: 发送 %02h，期望收到 %02h，实收 %02h", data, exp, rx_last);
                errors = errors + 1;
            end else begin
                $display("  ok  : 正确接收 %02h", rx_last);
            end
            repeat (3) @(posedge clk);
        end
    endtask

    // 发送一帧并核对：不应产生任何接收（例如停止位错误）
    task send_check_none;
        input [7:0] data;
        input       stop_bit;
        integer base;
        begin
            base = rx_count;
            send_byte(data, stop_bit);
            repeat (10) @(posedge clk);
            #1;
            if (rx_count !== base) begin
                $display("FAIL: 发送 %02h 后不应收到数据，却新增 %0d 次（%02h）",
                          data, rx_count - base, rx_last);
                errors = errors + 1;
            end else begin
                $display("  ok  : 已丢弃该帧");
            end
            repeat (3) @(posedge clk);
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

        $display("---- 正常字节 ----");
        send_check(8'h41, 8'h41);
        send_check(8'h00, 8'h00);
        send_check(8'hFF, 8'hFF);
        send_check(8'h55, 8'h55);
        send_check(8'hA5, 8'hA5);

        $display("---- 短毛刺（3 个时钟） ----");
        base_g = rx_count;
        rx = 1'b0;
        repeat (3) @(posedge clk);
        rx = 1'b1;
        repeat (80) @(posedge clk);
        #1;
        if (rx_count !== base_g) begin
            $display("FAIL: 毛刺后出现了接收（%02h）", rx_last);
            errors = errors + 1;
        end else begin
            $display("  ok  : 毛刺被丢弃");
        end

        $display("---- 停止位错误 ----");
        send_check_none(8'h5A, 1'b0);

        $display("---- 错误帧之后应能恢复 ----");
        send_check(8'h3C, 8'h3C);

        if (errors == 0)
            $display("PASS: uart_rx_tb 全部检查通过");
        else
            $display("FAIL: uart_rx_tb 共 %0d 处错误", errors);
        $finish;
    end

    initial begin
        #2000000;
        $display("FAIL: uart_rx_tb 超时");
        $finish;
    end

endmodule
