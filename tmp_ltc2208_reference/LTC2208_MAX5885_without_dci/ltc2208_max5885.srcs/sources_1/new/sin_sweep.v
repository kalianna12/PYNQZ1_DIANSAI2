`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/25 19:07:57
// Design Name: 
// Module Name: sin_sweep
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
module sin_sweep(
    input               dac_dco                  ,//200MHz DAC时钟
    input               rst_n                    ,//复位        
    //参数定义
    input       [47:0]  F_word_start             ,//起始频率控制字                             
    input       [47:0]  F_word_stop              ,//终止频率控制字   
    input       [47:0]  F_word_change            ,//变化步进                     
    input       [31:0]  F_word_keep              ,//频率保持时间
    input               sweep_mode               ,//扫频模式,0:单次扫频,1:连续扫频       
    //扫频控制
    input               sweep_start              ,//扫频开始信号
    input  wire         sweep_stop_n             ,//扫频结束信号 
    output reg          sweep_start_ack          ,//扫频开始确认
    output reg          fre_change_tri           ,//跳频触发信号
    output reg  [15:0]  m_data_sin               ,//波形数据   
    output wire         sweep_wave_valid          //扫频信号有效 

    );
// 状态定义（采用二进制编码）
localparam IDLE              = 4'b0001        ;// 空闲状态
localparam ACK               = 4'b0010        ;// 确认启动
localparam SWEEPING          = 4'b0100        ;// 单次扫频
localparam SWEEPING_CONTINUE = 4'b0110        ;// 连续扫频
localparam DONE              = 4'b1000        ;// 完成状态
//信号定义
wire          s_phase_tvalid             ;//输入相位有效
wire [31:0]   s_phase_tdata              ;//输入相位
wire          s_config_tvalid            ;//输入频率有效
wire [47:0]   s_config_tdata             ;//输入频率

wire          m_data_tvalid              ;//输出数据有效
wire [31:0]   m_data_tdata               ;//输出数据
wire          m_phase_tvalid             ;//输出相位有效
wire [31:0]   m_phase_tdata              ;//输出相位

reg  [15:0]   m_data_cos      = 0        ;
reg           sweep_en        = 0        ;//扫频使能
reg  [31:0]   F_word_cnt      = 0        ;
reg  [47:0]   config_data_reg = 0        ;//频率控制字寄存器
reg           max_flag        = 0        ;//当频率控制字最大时拉高
// 状态寄存器
reg [3:0] STATE;

always @(posedge dac_dco or negedge rst_n) begin
    if(!rst_n) begin        // 异步复位
        sweep_start_ack <= 1'b0;
        sweep_en        <= 1'b0;
    end
    else begin
        case(STATE)
            IDLE: begin
                sweep_start_ack  <= 1'b0;
                if(sweep_start) begin
                    STATE <= ACK;  
                end 
                else begin
                    STATE <= IDLE;  
                end
            end

            ACK: begin//确认扫频
                if(sweep_start) begin
                    if (sweep_mode) begin//扫频模式跳转
                        STATE <= SWEEPING_CONTINUE;
                    end
                    else begin
                        STATE <= SWEEPING;
                    end
                    sweep_start_ack <= 1'b1;
                    sweep_en        <= 1'b1;
                end 
                else begin
                    STATE <= IDLE;  
                end
            end
            // 单次扫频
            SWEEPING: begin//扫频中，等待扫频结束
                if(config_data_reg >= F_word_stop) begin
                    STATE    <= DONE;
                    sweep_start_ack <= 1'b0;
                    sweep_en <= 1'b0;
                end
                else begin
                    sweep_start_ack <= 1'b0;
                    STATE    <= SWEEPING;
                    sweep_en <= 1'b1;
                end
            end
            //连续扫频
            SWEEPING_CONTINUE: begin//扫频中，等待扫频结束
                if (!sweep_stop_n) begin
                    STATE    <= DONE;
                    sweep_start_ack <= 1'b0;
                    sweep_en <= 1'b0;                    
                end
                else begin
                    sweep_start_ack <= 1'b0;
                    STATE    <= SWEEPING_CONTINUE;
                    sweep_en <= 1'b1;
                end
            end

            DONE: begin
                STATE <= IDLE;               // 返回初始状态
            end
            default: STATE <= IDLE;         // 默认处理
        endcase
    end
end

//控制频率控制字均匀变化
always @(posedge dac_dco or negedge rst_n) begin
    if(!rst_n) begin
        F_word_cnt <= 32'd0;
        fre_change_tri <= 1'd0;
        config_data_reg <= F_word_start;
    end
    else if((!sweep_en)||(config_data_reg >= F_word_stop)) begin
        F_word_cnt <= 32'd0;
        fre_change_tri <= 1'd0;
        config_data_reg <= F_word_start;
    end
    else if(F_word_cnt >= F_word_keep) begin
        F_word_cnt <= 32'd0;
        fre_change_tri <= 1'd1;
        config_data_reg <= config_data_reg + F_word_change;
    end
    else begin
        fre_change_tri <= 1'd0;
        F_word_cnt <= F_word_cnt + 32'd1;
    end
end

//输出
assign s_phase_tvalid  = 1'b1            ;
assign s_phase_tdata   = 32'h0           ;//设置相位控制字为0
assign s_config_tvalid = 1'b1            ;
assign s_config_tdata  = config_data_reg ;

dds_compiler_0 U_dds_compiler_0_for_sweep (
  .aclk                 (dac_dco        ),  // input  wire aclk
  .s_axis_phase_tvalid  (s_phase_tvalid ),  // input  wire s_axis_phase_tvalid
  .s_axis_phase_tdata   (s_phase_tdata  ),  // input  wire [47 : 0] s_axis_phase_tdata
  .s_axis_config_tvalid (s_config_tvalid),  // input  wire s_axis_config_tvalid
  .s_axis_config_tdata  (s_config_tdata ),  // input  wire [47 : 0] s_axis_config_tdata
  .m_axis_data_tvalid   (m_data_tvalid  ),  // output wire m_axis_data_tvalid
  .m_axis_data_tdata    (m_data_tdata   ),  // output wire [31 : 0] m_axis_data_tdata
  .m_axis_phase_tvalid  (m_phase_tvalid ),  // output wire m_axis_phase_tvalid
  .m_axis_phase_tdata   (m_phase_tdata  )   // output wire [47 : 0] m_axis_phase_tdata
);

assign sweep_wave_valid = m_data_tvalid & s_config_tvalid & sweep_en;

always @(posedge dac_dco ) begin
    m_data_sin <= (m_data_tdata[31:16] + 16'd32768) & {16{sweep_wave_valid}};
    m_data_cos <= (m_data_tdata[15:0 ] + 16'd32768) & {16{sweep_wave_valid}};
end
endmodule
