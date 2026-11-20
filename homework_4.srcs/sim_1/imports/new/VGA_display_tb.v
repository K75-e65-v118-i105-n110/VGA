`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: VGA_display_tb
// Description: 自检式测试平台。检查 VGA 时序发生器：
//              1) 像素时钟 vga_clk 为系统时钟四分频（40 ns 周期）；
//              2) 行计数 0..799、场计数 0..524 循环正确；
//              3) hsync/vsync 低有效，极性与计数值一致；
//              4) 一整帧共 525 行。
//              注意：VGA_display 没有复位端，上板时由 FPGA 寄存器初值决定；
//              仿真中在 TB 里给这些寄存器赋初值 0，模拟上电状态。
//////////////////////////////////////////////////////////////////////////////////

module VGA_display_tb;

    reg         clk;
    wire        hsync;
    wire        vsync;
    wire [9:0]  hcount;
    wire [9:0]  vcount;
    wire        vga_clk;

    integer     errors;
    integer     lines;
    integer     last_time;

    reg [9:0]   exp_h;
    reg [9:0]   exp_v;

    VGA_display dut (
        .clk    (clk),
        .hsync  (hsync),
        .vsync  (vsync),
        .hcount (hcount),
        .vcount (vcount),
        .vga_clk(vga_clk)
    );

    always #5 clk = ~clk;

    initial begin
        clk           = 1'b0;
        // 模拟上电初值：Vivado 会把无复位寄存器初始化为 0
        dut.clk_count = 1'b0;
        dut.vga_clk   = 1'b0;
        dut.hcount    = 10'd0;
        dut.vcount    = 10'd0;

        exp_h     = 10'd1;      // 第一个 vga_clk 上升沿后 hcount 变为 1
        exp_v     = 10'd0;
        lines     = 0;
        errors    = 0;
        last_time = -1;         // 第一个上升沿只记录时间，不比较周期
    end

    // 每来一个像素时钟检查一次计数与同步信号
    always @(posedge vga_clk) begin
        #1;

        if (last_time >= 0 && ($time - last_time) !== 40) begin
            $display("FAIL: vga_clk 周期应为 40 ns，实测 %0d ns", $time - last_time);
            errors = errors + 1;
        end
        last_time = $time;

        if (hcount !== exp_h || vcount !== exp_v) begin
            $display("FAIL: 计数不符，实测 (%0d,%0d)，期望 (%0d,%0d)",
                      hcount, vcount, exp_h, exp_v);
            errors = errors + 1;
        end

        if (hsync !== (hcount > 10'd95)) begin
            $display("FAIL: hsync 极性错误，hcount=%0d hsync=%b", hcount, hsync);
            errors = errors + 1;
        end
        if (vsync !== (vcount > 10'd1)) begin
            $display("FAIL: vsync 极性错误，vcount=%0d vsync=%b", vcount, vsync);
            errors = errors + 1;
        end

        // 推算下一拍的期望值
        if (hcount == 10'd799) begin
            exp_h = 10'd0;
            if (vcount == 10'd524) exp_v = 10'd0;
            else                   exp_v = vcount + 10'd1;
        end else begin
            exp_h = hcount + 10'd1;
            exp_v = vcount;
        end

        // 统计行数：hcount 回绕一次即完成一行
        if (hcount == 10'd0) begin
            lines = lines + 1;
            if (vcount == 10'd0 && lines > 1) begin
                if (lines !== 525) begin
                    $display("FAIL: 一帧应为 525 行，实测 %0d 行", lines);
                    errors = errors + 1;
                end
                if (errors == 0)
                    $display("PASS: VGA_display_tb 完成一帧扫描，共 525 行，同步与计数全部正确");
                else
                    $display("FAIL: VGA_display_tb 共 %0d 处错误", errors);
                $finish;
            end
        end
    end

    initial begin
        #40000000;
        $display("FAIL: VGA_display_tb 超时，已扫描 %0d 行", lines);
        $finish;
    end

endmodule
