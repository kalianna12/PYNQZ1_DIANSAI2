## Dual MAX5885, 200 MSPS.  Pin assignments follow
## docs/MAX5885_210M_DAC_新接线表.md exactly.
## A0..A15: Y19 Y16 Y17 U18 U19 W18 W19 W14 Y14 T11 T10 V16 W16 V12 W13 P15
## B0..B15: N17 P18 R16 R17 V17 V18 V15 W15 T16 U17 T14 T15 U13 V13 T12 U12
## CLKA: Y18, CLKB: P16

set_property PACKAGE_PIN Y19 [get_ports {dac_a_data[0]}]
set_property PACKAGE_PIN Y16 [get_ports {dac_a_data[1]}]
set_property PACKAGE_PIN Y17 [get_ports {dac_a_data[2]}]
set_property PACKAGE_PIN U18 [get_ports {dac_a_data[3]}]
set_property PACKAGE_PIN U19 [get_ports {dac_a_data[4]}]
set_property PACKAGE_PIN W18 [get_ports {dac_a_data[5]}]
set_property PACKAGE_PIN W19 [get_ports {dac_a_data[6]}]
set_property PACKAGE_PIN W14 [get_ports {dac_a_data[7]}]
set_property PACKAGE_PIN Y14 [get_ports {dac_a_data[8]}]
set_property PACKAGE_PIN T11 [get_ports {dac_a_data[9]}]
set_property PACKAGE_PIN T10 [get_ports {dac_a_data[10]}]
set_property PACKAGE_PIN V16 [get_ports {dac_a_data[11]}]
set_property PACKAGE_PIN W16 [get_ports {dac_a_data[12]}]
set_property PACKAGE_PIN V12 [get_ports {dac_a_data[13]}]
set_property PACKAGE_PIN W13 [get_ports {dac_a_data[14]}]
set_property PACKAGE_PIN P15 [get_ports {dac_a_data[15]}]
set_property PACKAGE_PIN Y18 [get_ports dac_a_clk]

set_property PACKAGE_PIN N17 [get_ports {dac_b_data[0]}]
set_property PACKAGE_PIN P18 [get_ports {dac_b_data[1]}]
set_property PACKAGE_PIN R16 [get_ports {dac_b_data[2]}]
set_property PACKAGE_PIN R17 [get_ports {dac_b_data[3]}]
set_property PACKAGE_PIN V17 [get_ports {dac_b_data[4]}]
set_property PACKAGE_PIN V18 [get_ports {dac_b_data[5]}]
set_property PACKAGE_PIN V15 [get_ports {dac_b_data[6]}]
set_property PACKAGE_PIN W15 [get_ports {dac_b_data[7]}]
set_property PACKAGE_PIN T16 [get_ports {dac_b_data[8]}]
set_property PACKAGE_PIN U17 [get_ports {dac_b_data[9]}]
set_property PACKAGE_PIN T14 [get_ports {dac_b_data[10]}]
set_property PACKAGE_PIN T15 [get_ports {dac_b_data[11]}]
set_property PACKAGE_PIN U13 [get_ports {dac_b_data[12]}]
set_property PACKAGE_PIN V13 [get_ports {dac_b_data[13]}]
set_property PACKAGE_PIN T12 [get_ports {dac_b_data[14]}]
set_property PACKAGE_PIN U12 [get_ports {dac_b_data[15]}]
set_property PACKAGE_PIN P16 [get_ports dac_b_clk]

set_property IOSTANDARD LVCMOS33 [get_ports {dac_a_data[*] dac_a_clk dac_b_data[*] dac_b_clk}]
set_property DRIVE 8 [get_ports {dac_a_data[*] dac_a_clk dac_b_data[*] dac_b_clk}]
set_property SLEW FAST [get_ports {dac_a_data[*] dac_a_clk dac_b_data[*] dac_b_clk}]
set_property IOB TRUE [get_ports {dac_a_data[*] dac_b_data[*]}]

## AXI-Lite configuration is committed into the 200 MHz DAC domain through a
## synchronized toggle. The data bus is held stable by PS software around that
## commit, so the two domains must not be analyzed as a synchronous data path.
set_clock_groups -asynchronous \
    -group [get_clocks {clk_fpga_0}] \
    -group [get_clocks {clk_out1_system_dac_clk_wiz_0_0}]

## The local DAC reset synchronizer asserts asynchronously and releases only
## through its two 200 MHz stages. Recovery/removal from the unrelated PS reset
## source is intentionally excluded.
set_false_path -to [get_pins -hier -filter {NAME =~ *dac_reset_sync_reg*/CLR}]
