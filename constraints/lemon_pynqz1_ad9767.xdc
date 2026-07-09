## Provisional AD9767 dual-channel interface on the former ADC-side header.
##
## Goal:
## - Keep AD9102 pins unchanged on the other header.
## - Keep board LEDs/RGB/buttons unchanged.
## - Put AD9767 on the ADC-side two-column expansion area for first bring-up.
##
## This is a provisional pinout. Change only this file after real wiring is
## confirmed on the board.
##
## Odd/status column row 1..16 is used as AD9767 channel A:
##   W9 U8 U10 W6 Y8 Y6 U5 V7 W8 V10 Y13 Y11 J15 F16 F20 A20
##   -> dac_a_data[0..13], dac_a_clk, dac_a_wrt
##
## Even column row 1..16 is used as AD9767 channel B:
##   W10 U9 T9 V6 Y9 Y7 T5 U7 V8 V11 Y12 W11 V5 H15 F19 B19
##   -> dac_b_data[0..13], dac_b_clk, dac_b_wrt

set_property PACKAGE_PIN W9  [get_ports {dac_a_data[0]}]
set_property PACKAGE_PIN U8  [get_ports {dac_a_data[1]}]
set_property PACKAGE_PIN U10 [get_ports {dac_a_data[2]}]
set_property PACKAGE_PIN W6  [get_ports {dac_a_data[3]}]
set_property PACKAGE_PIN Y8  [get_ports {dac_a_data[4]}]
set_property PACKAGE_PIN Y6  [get_ports {dac_a_data[5]}]
set_property PACKAGE_PIN U5  [get_ports {dac_a_data[6]}]
set_property PACKAGE_PIN V7  [get_ports {dac_a_data[7]}]
set_property PACKAGE_PIN W8  [get_ports {dac_a_data[8]}]
set_property PACKAGE_PIN V10 [get_ports {dac_a_data[9]}]
set_property PACKAGE_PIN Y13 [get_ports {dac_a_data[10]}]
set_property PACKAGE_PIN Y11 [get_ports {dac_a_data[11]}]
set_property PACKAGE_PIN J15 [get_ports {dac_a_data[12]}]
set_property PACKAGE_PIN F16 [get_ports {dac_a_data[13]}]
set_property PACKAGE_PIN F20 [get_ports dac_a_clk]
set_property PACKAGE_PIN A20 [get_ports dac_a_wrt]

set_property PACKAGE_PIN W10 [get_ports {dac_b_data[0]}]
set_property PACKAGE_PIN U9  [get_ports {dac_b_data[1]}]
set_property PACKAGE_PIN T9  [get_ports {dac_b_data[2]}]
set_property PACKAGE_PIN V6  [get_ports {dac_b_data[3]}]
set_property PACKAGE_PIN Y9  [get_ports {dac_b_data[4]}]
set_property PACKAGE_PIN Y7  [get_ports {dac_b_data[5]}]
set_property PACKAGE_PIN T5  [get_ports {dac_b_data[6]}]
set_property PACKAGE_PIN U7  [get_ports {dac_b_data[7]}]
set_property PACKAGE_PIN V8  [get_ports {dac_b_data[8]}]
set_property PACKAGE_PIN V11 [get_ports {dac_b_data[9]}]
set_property PACKAGE_PIN Y12 [get_ports {dac_b_data[10]}]
set_property PACKAGE_PIN W11 [get_ports {dac_b_data[11]}]
set_property PACKAGE_PIN V5  [get_ports {dac_b_data[12]}]
set_property PACKAGE_PIN H15 [get_ports {dac_b_data[13]}]
set_property PACKAGE_PIN F19 [get_ports dac_b_clk]
set_property PACKAGE_PIN B19 [get_ports dac_b_wrt]

set_property IOSTANDARD LVCMOS33 [get_ports {
    dac_a_data[*]
    dac_a_clk
    dac_a_wrt
    dac_b_data[*]
    dac_b_clk
    dac_b_wrt
}]

set_property DRIVE 8 [get_ports {
    dac_a_data[*]
    dac_a_clk
    dac_a_wrt
    dac_b_data[*]
    dac_b_clk
    dac_b_wrt
}]

set_property SLEW FAST [get_ports {
    dac_a_data[*]
    dac_a_clk
    dac_a_wrt
    dac_b_data[*]
    dac_b_clk
    dac_b_wrt
}]

set_property IOB TRUE [get_ports {
    dac_a_data[*]
    dac_b_data[*]
}]

## Forwarded 125 MSPS DAC clocks. Data changes on the opposite fabric edge in
## RTL so the DAC sees a stable bus around the forwarded CLK/WRT edge.
## Output-delay constraints are intentionally left for the confirmed physical
## AD9767 wiring stage.
