`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/04 20:10:35
// Design Name: 
// Module Name: top
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


module top(
input                 sys_clk_50M ,//系统时钟,晶振50MHz
// input   wire          sys_rst_n   ,//系统复位信号，低电平有效

output  wire          adc_clk     ,//ADC输入给FPGA的参考时钟
input         [15:0]  adc_dai     ,//ADC输入给FPGA的数据

output  wire          dac_dco     ,//DAC输出给FPGA的时钟
output  wire  [15:0]  dac_data    ,//DAC输出给FPGA的数据

input   wire          key_start   ,//按键扫频开始
input   wire          key_stop     //按键扫频停止          
    );
wire        sys_rst_n   ; 

wire [15:0] m_data_wave ;
wire [15:0] adc_data    ;
wire [47:0] fre_word    ;
wire [15:0] m_data_sin  ;
wire [31:0] B_div       ;
wire [ 3:0] sel         ;
wire [15:0] duty_word   ;
wire [15:0] clk_ADC_R   ;

//pll 产生给DAC的时钟200MHz，该时钟作为max5885 dds数据链上的时钟
clk_wiz_0 U_clk_wiz_0 (
    // Clock out 
    .clk_DAC        (dac_dco            ),// output clk_DAC 200MHz
    .clk_ADC        (adc_clk            ),// output clk_ADC
    .clk_ADC_R      (clk_ADC_R          ),// output clk_ADC_R
    // Status and control signals       
    .reset          (~sys_rst_n         ),// input reset
    .locked         (                   ),// output locked
   // Clock in ports        
    .clk_in1        (sys_clk_50M        ) // input clk_in1
);


//LTC_2208驱动
LTC_2208 U_LTC_2208 (
    .sys_rst_n      (sys_rst_n          ), // input  系统复位
    .adc_dci        (clk_ADC_R          ), // input  ADC输入给FPGA的参考时钟
    .adc_dai        (adc_dai            ), // input  ADC输入给FPGA的数据
    .adc_data       (adc_data           )  // output ADC采样的数据
); 


wire  [47:0 ]   F_word_start ;
wire  [47:0 ]   F_word_stop  ;
wire  [47:0 ]   F_word_change;
wire  [31:0 ]   F_word_keep  ;
wire            sweep_mode   ;
//max5885驱动，包含dds设计
max5885 U_max5885 (
    .dac_dco        (dac_dco            ),//fpga输出给max5885的时钟
    .reset          (sys_rst_n          ),

    .sel            (sel                ),//波形选择 4'b0000-sin 4'b0001-cos 4'b0010-tri 4'b0011-squ 4'b0100-DC 4'b0101-sweep 
    .duty_word      (duty_word          ),//占空比控制字，0-65535 对应 0-100的占空比，具体计算可以参考matlab代码
    .fre_word       (fre_word           ),//频率控制字，0-2^48-1 对应 0-200MHz的频率(输出波形带宽50M，超过50M后波形失真)，具体计算可以参考matlab代码
    .Pha_word       (16'd0              ),//相位控制字，0-65535 对应 0-360度的相位，具体计算可以参考matlab代码

    .F_word_start   (F_word_start       ),//input [47:0] 起始频率控制字
    .F_word_stop    (F_word_stop        ),//input [47:0] 终止频率控制字
    .F_word_change  (F_word_change      ),//input [47:0] 变化步进
    .F_word_keep    (F_word_keep        ),//input [31:0] 频率保持时间 1--->(1/200000000)s
    .sweep_start    (~key_start         ),//input 扫频开始信号         
    .sweep_start_ack(                   ),//output 扫频开始确认             
    .sweep_stop_n   (key_stop           ),//input 扫频结束信号
    .sweep_mode     (sweep_mode         ),//input 扫频模式,0:单次扫频,1:连续扫频
    .fre_change_tri (                   ),//output 跳频触发信号            
    

    .m_data_wave    (m_data_wave        ),//波形数据输出
    .rom_addr       (                   ) //rom地址输出，可以作为调试信号
);
//浮点数调幅模块 A/B
tiaofu u_tiaofu ( 
    .sysclk         (dac_dco            ), // 输入数据时钟
    .rst_n          (sys_rst_n          ), // 输入低电平复位信号
    .data_in        (m_data_wave        ), // 输入 16 位数据，作为被除数A
    .chushu_in      (B_div              ), // 输入 32 位除数数据B,遵循IEEE 754浮点数标准，这里规定整数位8位，小数位 24 位
    .data_out       (dac_data           )  // 输出 16 位数据
);
////////////////////////////////////////////////////////////调试//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

vio_0 u_vio_0 ( 
  .clk              (dac_dco            ), // input wire clk
  .probe_out0       (fre_word           ), // output wire [47 : 0] probe_out0
  .probe_out1       (B_div              ), // output wire [31 : 0] probe_out0
  .probe_out2       (duty_word          ), // output wire [15 : 0] probe_out2
  .probe_out3       (sel                ), // output wire [3 : 0] probe_out3
  .probe_out4       (F_word_start       ), // output wire [47 : 0] probe_out4
  .probe_out5       (F_word_stop        ), // output wire [47 : 0] probe_out5
  .probe_out6       (F_word_change      ), // output wire [47 : 0] probe_out6
  .probe_out7       (F_word_keep        ), // output wire [31 : 0] probe_out7
  .probe_out8       (sweep_mode         ), // output wire [0 : 0] probe_out8 
  .probe_out9       (sys_rst_n          )  // output wire [0 : 0] probe_out9 
  
); 

//ADC采样数据，偏移二进制转换为有符号数 
reg signed [15:0] m_data_adc_signed;
always @(posedge clk_ADC_R) begin
    m_data_adc_signed <= adc_data - 16'h8000;
end

ila_0 adc_ila_0 ( 
	.clk            (clk_ADC_R          ), // input wire clk
	.probe0         (m_data_adc_signed  ), // input wire [15:0] probe0
    .probe1         (adc_data           )  // input wire [15:0] probe1
); 
endmodule
