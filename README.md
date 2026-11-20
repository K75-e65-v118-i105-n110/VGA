# VGA Snake · 基于 FPGA 的 VGA 贪吃蛇

用纯 Verilog 在 Xilinx Artix-7 上实现的一款 VGA 贪吃蛇游戏。FPGA 自己产生 `640×480@60Hz` 的 VGA 时序，画面全部由片内 ROM 里的位图拼出来；操作则通过板载 USB-UART 接收 PC 键盘的按键。整个设计不依赖 CPU 或软核，从上板、开始、暂停、计分到结算都跑在硬件状态机里。

## 项目简介

工程围绕"用 FPGA 直接画出一台游戏机"展开：

- **显示**：`VGA_display` 把 100 MHz 系统时钟 4 分频得到 25 MHz 像素时钟，输出 640×480 的行场同步与像素坐标；`RGB_gen` 在像素级把墙体、蛇、食物、分数、文字和进度条合成为 12 bit RGB444。
- **逻辑**：棋盘按 32×24 个格子划分（每格 20×20 像素），第 0 行留给分数、第 23 行留给进度条，蛇可活动范围是 `x ∈ [0, 31]`、`y ∈ [1, 22]`。`game_rule` 负责蛇身移位与增长、撞墙／撞自己判定；`food_gen` 用 LFSR 生成食物；`point_count` 累计得分并拆成 BCD 三位数字显示。
- **输入**：`uart_rx` 以 115200 8N1 接收串口字节，`uart_decode` 解析 WASD、ANSI 方向键、空格/回车与变速键，`input_ctrl` 锁存方向并拦截 180° 掉头。
- **素材**：所有图形（蛇头／蛇身／蛇尾／拐角／墙／食物／0-9 数字／文字界面）都是 20×20 或整屏 PNG，由 `photo_process/` 里的 Python 脚本转成 `.coe`，再由 `create_sprite_roms.tcl` 批量建成 `blk_mem_gen` ROM IP。

## 功能特性

- 640×480@60Hz VGA 输出，行场同步低有效，`800×525` 的扫描周期内为 640×480 有效显示区。
- 32×24 方格棋盘（每格 20×20 像素），蛇头、蛇身、蛇尾、四种拐角、墙体、食物均使用独立位图，转弯方向由相邻格子关系自动选择贴图。
- 90 格预置迷宫墙，蛇与食物都不会刷到墙里；棋盘左右与上下边界可穿透环绕。
- 串口操作：WASD 或方向键控制方向，空格／回车 开始、暂停、重开，`J` 键在 5 Hz / 10 Hz 两档速度间切换。
- 计分：普通食物 +2 分；累计吃满 8 个食物后会刷出一枚**限时计分食物**，10 秒内吃掉最多再 +10 分（得分随时间递减），超时则消失并刷新新食物。
- 屏幕底部红色进度条实时显示限时食物的剩余时间；限时食物本身以"呼吸式"缩放闪烁提示。
- 左上角三位十进制分数显示（百／十／个位，各自一张数字位图 ROM）。
- 四个状态的状态机：开始界面 → 游戏中 ⇄ 暂停 → 结算界面（`GAME OVER` + `press [space] to restart`）。
- 结束条件：撞墙、撞到自己、蛇长达到上限（32 节）。
- 11 个自检测试平台，覆盖串口收发／解码、方向控制、游戏节拍、规则、食物、计分与 VGA 时序。

## 操作说明

| 输入 | 功能 |
| --- | --- |
| `W` / `S` / `A` / `D`（大小写均可） | 上 / 下 / 左 / 右 |
| `↑` `↓` `←` `→`（ANSI 转义序列 `ESC [ A/B/C/D`） | 上 / 下 / 左 / 右 |
| `空格` 或 `回车`（CR） | 开始 / 暂停 / 继续 / 结算后重开 |
| `J` | 切换游戏速度（5 Hz ⇄ 10 Hz） |
| `rst`（`U18`，高有效） | 复位整个游戏 |

方向输入有优先级：上 > 下 > 左 > 右；同一个移动周期内不允许 180° 反向（防止自杀式掉头）。

## 硬件与环境

| 项目 | 说明 |
| --- | --- |
| 目标器件 | Xilinx Artix-7 `xc7a35tcpg236-1` |
| 开发工具 | Vivado 2019.1（工程由 2019.1 创建） |
| 系统时钟 | 100 MHz，`W5` |
| 显示接口 | 12 bit RGB444 VGA，`hsync = P19`，`vsync = R19` |
| 串口 | `uart_rx = B18`（板载 USB-UART），115200 8N1 |
| 复位 | `rst = U18`，高有效 |
| 仿真 | Vivado Simulator（xsim） |

约束文件：`homework_4.srcs/constrs_1/new/homework_4.xdc`（含 `create_clock`、`create_generated_clock` 与 `uart_rx` 的异步 `set_false_path`）。

## 系统架构

```
                    ┌──────────────┐
 clk ───────────────┤ VGA_display  ├──► hsync / vsync / hcount / vcount / vga_clk
                    └──────────────┘
 uart_rx ──► uart_rx ──► uart_decode ──► uart_dirctrl ──► direc_in / start_pause / speed_ctrl
                                                              │
                    ┌──────────────┐    ┌───────────┐         │
                    │  start_end   ├───►│ input_ctrl│◄────────┘
                    │ (开始/暂停/   │    │ (方向锁存) │
                    │  结束状态机)  │    └─────┬─────┘
                    └──────┬───────┘          │ direc_state
                           │ start/pause      ▼
        ┌──────────┐   ┌───┴──────────┐   ┌────────────┐
        │ game_tick├──►│  game_rule   ├──►│  snake_x/y │
        │ (节拍分频)│   │ (移位/判定)   │   │  food_x/y  │
        └──────────┘   └──────┬───────┘   │  snake_len │
                              │           └─────┬──────┘
                     ┌────────┴────────┐        │
                     │ food_gen (LFSR) │        │
                     │ food_point (计时)│        │
                     └─────────────────┘        ▼
                                        ┌───────────────┐
                               RGB ◄────┤    RGB_gen    │◄── 位图 ROM（墙/蛇/食物/数字/文字）
                                        └───────────────┘
```

| 模块 | 职责 |
| --- | --- |
| `top_module` | 顶层，例化全部子模块并给出 90 格墙体坐标 |
| `VGA_display` | 25 MHz 像素时钟生成、640×480 行场扫描与同步信号 |
| `uart_rx` | UART 接收：起始位检测、中点采样、8 bit 数据、停止位校验 |
| `uart_decode` | 按键解码：WASD、方向键转义序列、空格/回车、`J` |
| `uart_dirctrl` | 把接收 + 解码两级串起来，输出方向/开始/变速脉冲 |
| `start_end` | 开始、游戏中、暂停、结束 四状态机 |
| `input_ctrl` | 方向锁存、优先级仲裁与反向保护 |
| `game_tick` | 游戏移动节拍分频（`DIV = 2e7`，可减半） |
| `game_rule` | 蛇身移位与增长、撞墙／撞自己／长度上限判定、食物与计分调度 |
| `food_gen` | 16 bit LFSR + 拒绝采样生成食物坐标，每 8 个食物插入限时食物 |
| `food_point` | 限时食物 10 秒倒计时、得分 10→0 递减、超时失效 |
| `point_count` | 得分累加（`+2 + food_point`）与百／十／个位 BCD 拆分 |
| `RGB_gen` | 像素级合成与优先级：结算文字 > 重开提示 > 开始提示 > 分数 > 墙 > 进度条 > 蛇 > 食物 |
| `point_rgb` | 按行扫描位置选择对应数字 ROM 的像素 |
| `point_food_rgb` | 限时食物的三档尺寸循环（呼吸效果） |
| `bound_down_rgb` | 底部剩余时间进度条 |

## 目录结构

```
homework_4/
├─ homework_4.xpr                      # Vivado 工程文件（顶层 top_module）
├─ create_sprite_roms.tcl              # 用 photo_process/*.coe 批量创建 ROM IP 并 OOC 综合
├─ homework_4.srcs/
│  ├─ sources_1/new/                   # 16 个 Verilog RTL 源文件
│  ├─ sources_1/ip/                    # 每位图一个 blk_mem_gen ROM（12 bit 宽，深度 400 等）
│  ├─ constrs_1/new/homework_4.xdc     # 引脚与时序约束
│  └─ sim_1/imports/new/               # 11 个自检 testbench
└─ photo_process/                      # PNG 素材、.coe 初始化文件、素材生成脚本
   ├─ snake_sprites_to_coe.py          # 20×20 精灵 → .coe（含旋转派生方向）
   ├─ generate_text_screens.py         # 生成开始／结算文字界面 PNG + .coe
   └─ photo_to_coe.py                  # 任意图片 → 4 bit 索引 + RGB444 调色板 .coe（备用）
```

> 说明：仓库里同时保留了 Vivado 的 `*.cache / *.runs / *.sim / *.ip_user_files` 等构建目录和
> `photo_process/.venv` 虚拟环境等历史提交，它们并非源码，见文末"已知限制"。

## 快速开始

1. 用 **Vivado 2019.1** 打开 `homework_4.xpr`（工程记录的是创建时的绝对路径，换目录后按提示重新定位）。
2. `Flow Navigator → Generate Bitstream`，等待综合、实现、生成比特流完成。
3. `Open Hardware Manager → Auto Connect → Program Device` 下载到板卡。
4. PC 端用串口终端（波特率 115200、8 数据位、无校验、1 停止位）连接板载 USB-UART，按空格开始游戏。

若在其他机器上打开时报 ROM IP 找不到 `.coe`：在 `IP Sources` 中为对应 IP 重新指定
`photo_process/<name>.coe`，或直接执行下面的重建脚本。

## 素材与 ROM 生成流程

```
PNG 素材 ──(Python + Pillow)──► .coe ──(create_sprite_roms.tcl)──► blk_mem_gen ROM ──► RGB_gen
```

```powershell
python -m pip install -r photo_process/requirements.txt   # 仅依赖 Pillow
python photo_process/snake_sprites_to_coe.py              # 精灵：20×20 → 400 个 12 bit 字
python photo_process/generate_text_screens.py             # 文字界面：整屏位图
```

然后在 Vivado 的 Tcl Console 中：

```tcl
source create_sprite_roms.tcl
```

脚本会为 `photo_process/` 下每个 `.coe` 建一个 `Single_Port_ROM`（12 bit 宽、深度 400、开启输出寄存），
并启动缺失的 out-of-context 综合。

`*.coe` 中的坐标原点在左上角，按行优先排列；像素值直接就是 `R[3:0]G[3:0]B[3:0]`，因此 Python 里把 8 bit 颜色右移 4 位即可。
`generate_text_screens.py` 里硬编码了 Windows 的 `arialbd.ttf` 字体路径，换平台时需要修改 `FONT_PATH`。

## 仿真验证

`homework_4.srcs/sim_1/imports/new/` 下有 11 个带自检（`errors` 计数 + `$display` 汇总）的 testbench：

```
VGA_display_tb   uart_rx_tb      uart_decode_tb   uart_dirctrl_tb
input_ctrl_tb    game_tick_tb    game_rule_tb     food_gen_tb
food_point_tb    point_count_tb  game_core_tb
```

其中 `game_core_tb` 是端到端集成测试：从串口引脚按位送入按键，把"串口输入 + 状态机 + 方向控制 + 节拍 + 规则 + 计分"按顶层的方式连起来（不含 VGA 渲染，因此不需要 ROM 模型），依次检查开局、转向、暂停/恢复与初始分数。

仿真时工程默认顶层是 `input_ctrl_tb`，其余 testbench 需在 `Simulation Settings` 里切换顶层后单独运行。

## 设计要点

- **单周期节拍驱动全局**：`game_tick` 只产生一拍的脉冲，蛇的移位、增长、计分判定都在这一拍上完成，避免了跨模块的握手。
- **跨时钟域处理**：游戏逻辑跑在 100 MHz，绘图跑在 25 MHz 的 `vga_clk`（同源分频）。`RGB_gen` 中的 `point_food_rgb` 用两级寄存器把像素域与游戏域的信号对齐。
- **随机食物**：16 bit LFSR（抽头 16/14/13/11）产生候选坐标，落在蛇身、墙或边界上就丢弃，下一拍继续尝试，直到找到合法格子。
- **方向贴图**：蛇身不存方向，而是用"前一节 / 后一节"的相对位置在每一帧实时判断直行、四种拐角或尾部方向，再选对应 ROM。
- **反向保护**：`input_ctrl` 记录"上一次真正移动的方向"，本周期内禁止输入其反方向，因此快速连按也不会让蛇掉头撞自己。

## 已知限制

- 只支持 640×480@60Hz 这一种显示模式，像素时钟固定为 25 MHz。
- 蛇身长度上限 32 节，棋盘只有 32×24，玩法以课程作业规模为主。
- 串口需要 PC 端自己起一个终端或串口助手；用串口助手时请逐字符发送（勾选"发送新行"会额外发出 CR/LF，其中 CR 会被当作开始键）。
- 工程与仓库中保留了 Vivado 构建目录、Python 虚拟环境、Vivado 日志等非源码文件（见 `.gitignore` 的说明），克隆体积偏大。
