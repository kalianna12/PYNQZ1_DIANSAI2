## LTC2208 occupies the right-side P2 2x17 data header.  Mapping follows
## docs/FPGA_接线表.md exactly: module label -> PYNQ-Z1 FPGA package pin.
## Power and ground are separate; there is no AD9226 compatibility wiring.

set_property PACKAGE_PIN V7  [get_ports {ltc_a_data[0]}]
set_property PACKAGE_PIN U7  [get_ports {ltc_a_data[1]}]
set_property PACKAGE_PIN U5  [get_ports {ltc_a_data[2]}]
set_property PACKAGE_PIN T5  [get_ports {ltc_a_data[3]}]
set_property PACKAGE_PIN Y6  [get_ports {ltc_a_data[4]}]
set_property PACKAGE_PIN Y7  [get_ports {ltc_a_data[5]}]
set_property PACKAGE_PIN Y8  [get_ports {ltc_a_data[6]}]
set_property PACKAGE_PIN Y9  [get_ports {ltc_a_data[7]}]
set_property PACKAGE_PIN W6  [get_ports {ltc_a_data[8]}]
set_property PACKAGE_PIN V6  [get_ports {ltc_a_data[9]}]
set_property PACKAGE_PIN U10 [get_ports {ltc_a_data[10]}]
set_property PACKAGE_PIN T9  [get_ports {ltc_a_data[11]}]
set_property PACKAGE_PIN U8  [get_ports {ltc_a_data[12]}]
set_property PACKAGE_PIN U9  [get_ports {ltc_a_data[13]}]
set_property PACKAGE_PIN W9  [get_ports {ltc_a_data[14]}]
set_property PACKAGE_PIN W10 [get_ports {ltc_a_data[15]}]
set_property PACKAGE_PIN V8  [get_ports ltc_a_clk]

set_property PACKAGE_PIN C20 [get_ports {ltc_b_data[0]}]
set_property PACKAGE_PIN A20 [get_ports {ltc_b_data[1]}]
set_property PACKAGE_PIN B19 [get_ports {ltc_b_data[2]}]
set_property PACKAGE_PIN F20 [get_ports {ltc_b_data[3]}]
set_property PACKAGE_PIN F19 [get_ports {ltc_b_data[4]}]
set_property PACKAGE_PIN F16 [get_ports {ltc_b_data[5]}]
set_property PACKAGE_PIN H15 [get_ports {ltc_b_data[6]}]
set_property PACKAGE_PIN J15 [get_ports {ltc_b_data[7]}]
set_property PACKAGE_PIN V5  [get_ports {ltc_b_data[8]}]
set_property PACKAGE_PIN Y11 [get_ports {ltc_b_data[9]}]
set_property PACKAGE_PIN W11 [get_ports {ltc_b_data[10]}]
set_property PACKAGE_PIN Y13 [get_ports {ltc_b_data[11]}]
set_property PACKAGE_PIN Y12 [get_ports {ltc_b_data[12]}]
set_property PACKAGE_PIN V10 [get_ports {ltc_b_data[13]}]
set_property PACKAGE_PIN V11 [get_ports {ltc_b_data[14]}]
set_property PACKAGE_PIN W8  [get_ports {ltc_b_data[15]}]
set_property PACKAGE_PIN B20 [get_ports ltc_b_clk]

set_property IOSTANDARD LVCMOS33 [get_ports {ltc_a_data[*] ltc_b_data[*] ltc_a_clk ltc_b_clk}]
set_property DRIVE 8 [get_ports {ltc_a_clk ltc_b_clk}]
set_property SLEW FAST [get_ports {ltc_a_clk ltc_b_clk}]
set_property IOB TRUE [get_ports {ltc_a_data[*] ltc_b_data[*]}]

## ADC data are captured by the companion 130 MHz, 10-degree phase-shifted
## clock. Apply the vendor-derived board delay window directly to that capture
## clock; XDC files do not support Tcl control-flow such as `if`.
set_input_delay -clock [get_clocks clk_out3_system_dac_clk_wiz_0_0] -min 3.1 [get_ports {ltc_a_data[*] ltc_b_data[*]}]
set_input_delay -clock [get_clocks clk_out3_system_dac_clk_wiz_0_0] -max 4.5 [get_ports {ltc_a_data[*] ltc_b_data[*]}]

# AXI-Lite runs at 125 MHz while the LTC engine uses independent 130 MHz
# launch/capture clocks. Configuration is held stable before the request
# toggle crosses domains; returned status is synchronized and samples pass
# through an asynchronous AXIS FIFO. There is no synchronous relationship.
set_clock_groups -asynchronous \
    -group [get_clocks {clk_fpga_0}] \
    -group [get_clocks {clk_out2_system_dac_clk_wiz_0_0 clk_out3_system_dac_clk_wiz_0_0}]
