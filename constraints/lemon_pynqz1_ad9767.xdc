## AD9767 dual-channel interface.
##
## Goal:
## - Keep board LEDs/RGB/buttons unchanged.
## - Route AD9767 P1/P2 digital buses directly to the confirmed FPGA pins.
## - AD9102 and AD9226 are intentionally not present in this overlay, so their
##   former pins are available for AD9767.
##
## Mapping:
## - P1 channel -> dac_a_data[13:0], dac_a_clk, dac_a_wrt
## - P2 channel -> dac_b_data[13:0], dac_b_clk, dac_b_wrt
##
## P1 channel:
##   V16 W16 T11 T10 W14 Y14 W18 W19 U18 U19 Y16 Y17 Y18 Y19 V12 W13
##   -> P1_DB0..P1_DB13, CLK1, WRT1
##
## P2 channel:
##   U13 V13 T14 T15 T16 U17 V15 W15 V17 V18 R16 R17 N17 P18 P16 P15
##   -> P2_DB0..P2_DB13, CLK2, WRT2

set_property PACKAGE_PIN V16 [get_ports {dac_a_data[0]}]
set_property PACKAGE_PIN W16 [get_ports {dac_a_data[1]}]
set_property PACKAGE_PIN T11 [get_ports {dac_a_data[2]}]
set_property PACKAGE_PIN T10 [get_ports {dac_a_data[3]}]
set_property PACKAGE_PIN W14 [get_ports {dac_a_data[4]}]
set_property PACKAGE_PIN Y14 [get_ports {dac_a_data[5]}]
set_property PACKAGE_PIN W18 [get_ports {dac_a_data[6]}]
set_property PACKAGE_PIN W19 [get_ports {dac_a_data[7]}]
set_property PACKAGE_PIN U18 [get_ports {dac_a_data[8]}]
set_property PACKAGE_PIN U19 [get_ports {dac_a_data[9]}]
set_property PACKAGE_PIN Y16 [get_ports {dac_a_data[10]}]
set_property PACKAGE_PIN Y17 [get_ports {dac_a_data[11]}]
set_property PACKAGE_PIN Y18 [get_ports {dac_a_data[12]}]
set_property PACKAGE_PIN Y19 [get_ports {dac_a_data[13]}]
set_property PACKAGE_PIN V12 [get_ports dac_a_clk]
set_property PACKAGE_PIN W13 [get_ports dac_a_wrt]

set_property PACKAGE_PIN U13 [get_ports {dac_b_data[0]}]
set_property PACKAGE_PIN V13 [get_ports {dac_b_data[1]}]
set_property PACKAGE_PIN T14 [get_ports {dac_b_data[2]}]
set_property PACKAGE_PIN T15 [get_ports {dac_b_data[3]}]
set_property PACKAGE_PIN T16 [get_ports {dac_b_data[4]}]
set_property PACKAGE_PIN U17 [get_ports {dac_b_data[5]}]
set_property PACKAGE_PIN V15 [get_ports {dac_b_data[6]}]
set_property PACKAGE_PIN W15 [get_ports {dac_b_data[7]}]
set_property PACKAGE_PIN V17 [get_ports {dac_b_data[8]}]
set_property PACKAGE_PIN V18 [get_ports {dac_b_data[9]}]
set_property PACKAGE_PIN R16 [get_ports {dac_b_data[10]}]
set_property PACKAGE_PIN R17 [get_ports {dac_b_data[11]}]
set_property PACKAGE_PIN N17 [get_ports {dac_b_data[12]}]
set_property PACKAGE_PIN P18 [get_ports {dac_b_data[13]}]
set_property PACKAGE_PIN P16 [get_ports dac_b_clk]
set_property PACKAGE_PIN P15 [get_ports dac_b_wrt]

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
