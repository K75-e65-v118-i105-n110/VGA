`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/17 14:22:57
// Design Name: 
// Module Name: uart_decode
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_decode(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] rx_data,
    input  wire       rx_valid,
    output reg        up_pulse,
    output reg        down_pulse,
    output reg        left_pulse,
    output reg        right_pulse,
    output reg        start_pulse,
    output reg speed_ctrl
);

    localparam [1:0] DIR_UP    = 2'b00;
    localparam [1:0] DIR_DOWN  = 2'b01;
    localparam [1:0] DIR_LEFT  = 2'b10;
    localparam [1:0] DIR_RIGHT = 2'b11;

    localparam [1:0] SEQ_NORMAL = 2'd0;
    localparam [1:0] SEQ_ESC    = 2'd1;
    localparam [1:0] SEQ_ARROW  = 2'd2;

    reg [1:0] seq_state;

    always @(posedge clk) begin
        if (rst) begin
            up_pulse        <= 1'b0;
            down_pulse      <= 1'b0;
            left_pulse      <= 1'b0;
            right_pulse     <= 1'b0;
            start_pulse     <= 1'b0;
            speed_ctrl      <= 1'b0;
            seq_state       <= SEQ_NORMAL;
        end else begin
            up_pulse    <= 1'b0;
            down_pulse  <= 1'b0;
            left_pulse  <= 1'b0;
            right_pulse <= 1'b0;
            start_pulse <= 1'b0;

            if (rx_valid) begin
                case (seq_state)
                    SEQ_NORMAL: begin
                        if (rx_data == 8'h1B) begin
                            seq_state <= SEQ_ESC;
                        end else begin
                            case (rx_data)
                                8'h57, 8'h77: begin // W / w
                                    up_pulse        <= 1'b1;
                                end
                                8'h53, 8'h73: begin // S / s
                                    down_pulse      <= 1'b1;
                                end
                                8'h41, 8'h61: begin // A / a
                                    left_pulse      <= 1'b1;
                                end
                                8'h44, 8'h64: begin // D / d
                                    right_pulse     <= 1'b1;
                                end
                                8'h4A, 8'h6A: begin // J / j
                                    speed_ctrl <= ~speed_ctrl;
                                end
                                8'h20, 8'h0D: begin // Space / CR
                                    start_pulse <= 1'b1;
                                end
                                default: begin
                                    // 0x0A (LF) and unknown bytes ignored.
                                end
                            endcase
                        end
                    end

                    SEQ_ESC: begin
                        if ((rx_data == 8'h5B) || (rx_data == 8'h4F)) begin
                            // '[' or 'O' (SS3)
                            seq_state <= SEQ_ARROW;
                        end else begin
                            seq_state <= SEQ_NORMAL;
                        end
                    end

                    SEQ_ARROW: begin
                        case (rx_data)
                            8'h41: begin // 'A'
                                up_pulse        <= 1'b1;
                            end
                            8'h42: begin // 'B'
                                down_pulse      <= 1'b1;
                            end
                            8'h43: begin // 'C'
                                right_pulse     <= 1'b1;
                            end
                            8'h44: begin // 'D'
                                left_pulse      <= 1'b1;
                            end
                            default: begin
                                // unsupported escape sequence
                            end
                        endcase
                        seq_state <= SEQ_NORMAL;
                    end

                    default: seq_state <= SEQ_NORMAL;
                endcase
            end
        end
    end

endmodule
