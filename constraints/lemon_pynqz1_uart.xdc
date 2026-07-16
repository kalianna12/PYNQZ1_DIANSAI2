## PL UART on right expansion header W9/W10.
## AXI UART 16550 v2.0, 115200 8E1 (PS runtime-adjustable).
## W9  = RX (FPGA input  <- STM32 TX)  -> uart_sin
## W10 = TX (FPGA output -> STM32 RX)  -> uart_sout

set_property PACKAGE_PIN W9  [get_ports uart_sin]
set_property PACKAGE_PIN W10 [get_ports uart_sout]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_sin uart_sout}]
set_property DRIVE 8 [get_ports uart_sout]
set_property SLEW SLOW [get_ports uart_sout]
