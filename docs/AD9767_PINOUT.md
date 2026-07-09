# AD9767 Pinout

This document records the current AD9767 digital-bus wiring for the
PYNQ-Z1 DIANSAI2 overlay.

## Naming

- AD9767 P1 channel is connected to RTL channel A:
  - `P1_DB[13:0]` -> `dac_a_data[13:0]`
  - `CLK1` -> `dac_a_clk`
  - `WRT1` -> `dac_a_wrt`
- AD9767 P2 channel is connected to RTL channel B:
  - `P2_DB[13:0]` -> `dac_b_data[13:0]`
  - `CLK2` -> `dac_b_clk`
  - `WRT2` -> `dac_b_wrt`

The XDC source of truth is:

```text
constraints/lemon_pynqz1_ad9767.xdc
```

## P1 Channel

| FPGA PACKAGE_PIN | AD9767 signal | RTL port |
|---|---|---|
| `V16` | `P1_DB0`  | `dac_a_data[0]` |
| `W16` | `P1_DB1`  | `dac_a_data[1]` |
| `T11` | `P1_DB2`  | `dac_a_data[2]` |
| `T10` | `P1_DB3`  | `dac_a_data[3]` |
| `W14` | `P1_DB4`  | `dac_a_data[4]` |
| `Y14` | `P1_DB5`  | `dac_a_data[5]` |
| `W18` | `P1_DB6`  | `dac_a_data[6]` |
| `W19` | `P1_DB7`  | `dac_a_data[7]` |
| `U18` | `P1_DB8`  | `dac_a_data[8]` |
| `U19` | `P1_DB9`  | `dac_a_data[9]` |
| `Y16` | `P1_DB10` | `dac_a_data[10]` |
| `Y17` | `P1_DB11` | `dac_a_data[11]` |
| `Y18` | `P1_DB12` | `dac_a_data[12]` |
| `Y19` | `P1_DB13` | `dac_a_data[13]` |
| `V12` | `CLK1`    | `dac_a_clk` |
| `W13` | `WRT1`    | `dac_a_wrt` |

## P2 Channel

| FPGA PACKAGE_PIN | AD9767 signal | RTL port |
|---|---|---|
| `U13` | `P2_DB0`  | `dac_b_data[0]` |
| `V13` | `P2_DB1`  | `dac_b_data[1]` |
| `T14` | `P2_DB2`  | `dac_b_data[2]` |
| `T15` | `P2_DB3`  | `dac_b_data[3]` |
| `T16` | `P2_DB4`  | `dac_b_data[4]` |
| `U17` | `P2_DB5`  | `dac_b_data[5]` |
| `V15` | `P2_DB6`  | `dac_b_data[6]` |
| `W15` | `P2_DB7`  | `dac_b_data[7]` |
| `V17` | `P2_DB8`  | `dac_b_data[8]` |
| `V18` | `P2_DB9`  | `dac_b_data[9]` |
| `R16` | `P2_DB10` | `dac_b_data[10]` |
| `R17` | `P2_DB11` | `dac_b_data[11]` |
| `N17` | `P2_DB12` | `dac_b_data[12]` |
| `P18` | `P2_DB13` | `dac_b_data[13]` |
| `P16` | `CLK2`    | `dac_b_clk` |
| `P15` | `WRT2`    | `dac_b_wrt` |

## Electrical Constraints

The current constraints use:

```xdc
set_property IOSTANDARD LVCMOS33 [get_ports {...}]
set_property DRIVE 8 [get_ports {...}]
set_property SLEW FAST [get_ports {...}]
set_property IOB TRUE [get_ports {dac_a_data[*] dac_b_data[*]}]
```

The forwarded DAC clocks and WRT signals are generated from the 125 MHz DAC
fabric clock. Data is registered on the opposite fabric edge in RTL so the DAC
sees a stable parallel bus around the forwarded clock/write edge.
