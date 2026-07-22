# PYNQ-Z1 扩展排针：FPGA 封装引脚分配表

> 本表用于 Vivado/XDC 和给 AI 生成约束。  
> `T12`、`U12`、`W9` 等是 Zynq-7020 的 \\\\\\\*\\\\\\\*FPGA 封装管脚（PACKAGE\\\\\\\_PIN）\\\\\\\*\\\\\\\*，不是 HDL 信号名。  
> 你需要把自己的端口名，例如 `led\\\\\\\[0]`、`uart\\\\\\\_tx`、`gpio\\\\\\\_in\\\\\\\[0]`，分配到下面某一根 FPGA IO。

## 重要规则

* `VCC`、`3V3`、`GND` 不是 FPGA 信号，**不能写进 XDC**。
* `VN`、`VP` 是模拟输入相关管脚，**不要按普通 LVCMOS33 GPIO 使用**。
* 普通 3.3V 数字 IO 的常用 XDC 写法：

```xdc
set\\\\\\\_property PACKAGE\\\\\\\_PIN <封装脚> \\\\\\\[get\\\\\\\_ports {<端口名>}]
set\\\\\\\_property IOSTANDARD LVCMOS33 \\\\\\\[get\\\\\\\_ports {<端口名>}]
```

* 每个 HDL 顶层端口只能分配到一个唯一引脚；同一个封装脚不能给两个端口。
* `LVCMOS33` 只适合确认对应 Bank 为 3.3V 的普通 GPIO。ADC、差分信号、外部时钟等要单独确认。

\---

## 左侧扩展排针：2 × 20

|行号|左脚|类型|右脚|类型|
|-:|-|-|-|-|
|1|VCC|电源，禁止分配|VCC|电源，禁止分配|
|2|3V3|电源，禁止分配|3V3|电源，禁止分配|
|3|GND|地，禁止分配|GND|地，禁止分配|
|4|T12|FPGA IO|U12|FPGA IO|
|5|U13|FPGA IO|V13|FPGA IO|
|6|T14|FPGA IO|T15|FPGA IO|
|7|T16|FPGA IO|U17|FPGA IO|
|8|V15|FPGA IO|W15|FPGA IO|
|9|V17|FPGA IO|V18|FPGA IO|
|10|R16|FPGA IO|R17|FPGA IO|
|11|N17|FPGA IO|P18|FPGA IO|
|12|P15|FPGA IO|P16|FPGA IO|
|13|V12|FPGA IO|W13|FPGA IO|
|14|V16|FPGA IO|W16|FPGA IO|
|15|T11|FPGA IO|T10|FPGA IO|
|16|W14|FPGA IO|Y14|FPGA IO|
|17|W18|FPGA IO|W19|FPGA IO|
|18|U18|FPGA IO|U19|FPGA IO|
|19|Y16|FPGA IO|Y17|FPGA IO|
|20|Y18|FPGA IO|Y19|FPGA IO|

\---

## 中间短排针：1 × 10

|序号|标记|类型|说明|
|-:|-|-|-|
|1|VN|模拟输入|不作为普通 GPIO；通常与 XADC 相关|
|2|VP|模拟输入|不作为普通 GPIO；通常与 XADC 相关|
|3|A5|FPGA IO|可用于数字 IO，需确认 I/O 标准|
|4|A4|FPGA IO|可用于数字 IO，需确认 I/O 标准|
|5|A3|FPGA IO|可用于数字 IO，需确认 I/O 标准|
|6|A2|FPGA IO|可用于数字 IO，需确认 I/O 标准|
|7|A1|FPGA IO|可用于数字 IO，需确认 I/O 标准|
|8|A0|FPGA IO|可用于数字 IO，需确认 I/O 标准|
|9|GND|地|禁止分配|
|10|3V3|电源|禁止分配|

\---

## 右侧扩展排针：2 × 20

|行号|左脚|类型|右脚|类型|
|-:|-|-|-|-|
|1|W9|FPGA IO|W10|FPGA IO|
|2|U8|FPGA IO|U9|FPGA IO|
|3|U10|FPGA IO|T9|FPGA IO|
|4|W6|FPGA IO|V6|FPGA IO|
|5|Y8|FPGA IO|Y9|FPGA IO|
|6|Y6|FPGA IO|Y7|FPGA IO|
|7|U5|FPGA IO|T5|FPGA IO|
|8|V7|FPGA IO|U7|FPGA IO|
|9|W8|FPGA IO|V8|FPGA IO|
|10|V10|FPGA IO|V11|FPGA IO|
|11|Y13|FPGA IO|Y12|FPGA IO|
|12|Y11|FPGA IO|W11|FPGA IO|
|13|J15|FPGA IO|V5|FPGA IO|
|14|F16|FPGA IO|H15|FPGA IO|
|15|F20|FPGA IO|F19|FPGA IO|
|16|A20|FPGA IO|B19|FPGA IO|
|17|B20|FPGA IO|C20|FPGA IO|
|18|GND|地，禁止分配|GND|地，禁止分配|
|19|3V3|电源，禁止分配|3V3|电源，禁止分配|
|20|VCC|电源，禁止分配|VCC|电源，禁止分配|

\---

## XDC 示例

### 一个输出：`led\\\\\\\_out` 接到 `T12`

```xdc
set\\\\\\\_property PACKAGE\\\\\\\_PIN T12 \\\\\\\[get\\\\\\\_ports {led\\\\\\\_out}]
set\\\\\\\_property IOSTANDARD LVCMOS33 \\\\\\\[get\\\\\\\_ports {led\\\\\\\_out}]
```

### 8 路 GPIO 输出示例

```xdc
set\\\\\\\_property PACKAGE\\\\\\\_PIN T12 \\\\\\\[get\\\\\\\_ports {gpio\\\\\\\_out\\\\\\\[0]}]
set\\\\\\\_property PACKAGE\\\\\\\_PIN U12 \\\\\\\[get\\\\\\\_ports {gpio\\\\\\\_out\\\\\\\[1]}]
set\\\\\\\_property PACKAGE\\\\\\\_PIN U13 \\\\\\\[get\\\\\\\_ports {gpio\\\\\\\_out\\\\\\\[2]}]
set\\\\\\\_property PACKAGE\\\\\\\_PIN V13 \\\\\\\[get\\\\\\\_ports {gpio\\\\\\\_out\\\\\\\[3]}]
set\\\\\\\_property PACKAGE\\\\\\\_PIN T14 \\\\\\\[get\\\\\\\_ports {gpio\\\\\\\_out\\\\\\\[4]}]
set\\\\\\\_property PACKAGE\\\\\\\_PIN T15 \\\\\\\[get\\\\\\\_ports {gpio\\\\\\\_out\\\\\\\[5]}]
set\\\\\\\_property PACKAGE\\\\\\\_PIN T16 \\\\\\\[get\\\\\\\_ports {gpio\\\\\\\_out\\\\\\\[6]}]
set\\\\\\\_property PACKAGE\\\\\\\_PIN U17 \\\\\\\[get\\\\\\\_ports {gpio\\\\\\\_out\\\\\\\[7]}]

set\\\\\\\_property IOSTANDARD LVCMOS33 \\\\\\\[get\\\\\\\_ports {gpio\\\\\\\_out\\\\\\\[\\\\\\\*]}]
```

### 一个输入：`button\\\\\\\_in` 接到 `W9`

```xdc
set\\\\\\\_property PACKAGE\\\\\\\_PIN W9 \\\\\\\[get\\\\\\\_ports {button\\\\\\\_in}]
set\\\\\\\_property IOSTANDARD LVCMOS33 \\\\\\\[get\\\\\\\_ports {button\\\\\\\_in}]
set\\\\\\\_property PULLUP true \\\\\\\[get\\\\\\\_ports {button\\\\\\\_in}]
```

\---

## 给 AI 的提示词模板

```text
我的 FPGA 是 PYNQ-Z1 / XC7Z020。请基于下面的扩展排针封装脚表，
为我的顶层 HDL 端口生成 XDC。

要求：
1. 仅使用标记为 FPGA IO 的封装脚。
2. 不得使用 VCC、3V3、GND、VN、VP。
3. 普通 3.3V GPIO 使用 IOSTANDARD LVCMOS33。
4. 输出端口默认 DRIVE 8、SLEW SLOW，除非我明确要求高速。
5. 所有端口不得重复使用 FPGA 引脚。
6. 最后给出完整 .xdc 文件，以及“端口名—封装脚”的对应表。

\\\\\\\[在这里粘贴你的 HDL 顶层端口定义]
```

