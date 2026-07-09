# PYNQ-Z1 DIANSAI2 AD9767 Overlay Report

Generated: 2026-07-09 20:12:50

## Build Outputs

| File | Status | Size | Modified |
|---|---|---:|---|
| `pynq\base_add.bit` | <span style="color:#008000;font-weight:bold;">PASS</span> | 4045674 | 2026-07-09 20:12:36 |
| `pynq\base_add.hwh` | <span style="color:#008000;font-weight:bold;">PASS</span> | 168431 | 2026-07-09 20:09:01 |
| `pynq\pynqz1_diansai2_ad9767_test.ipynb` | <span style="color:#008000;font-weight:bold;">PASS</span> | 6947 | 2026-07-09 19:53:16 |
| `pynq\pynqz1_diansai2_ad9767.py` | <span style="color:#008000;font-weight:bold;">PASS</span> | 5726 | 2026-07-09 19:53:06 |

## Address Map

| IP | Base | High | PS access |
|---|---:|---:|---|
| `ad9767_ctrl_0` | `0x40001000` | `0x40001FFF` | direct `MMIO` |
| `led_ctrl_0` | `0x40000000` | `0x40000FFF` | direct `MMIO` |

Recommended direct bindings:

```python
led_ip = MMIO(0x40000000, 0x1000)
ad9767_ip = MMIO(0x40001000, 0x1000)
```

## AD9767 Register Contract

| Offset | Register | Meaning |
|---:|---|---|
| `0x00` | CTRL | bit0 enable, bit1 AM enable, bit2 phase reset pulse |
| `0x04` | STATUS | enable/AM/output select summary |
| `0x08` | CARRIER_FWORD | `round(fc / 125e6 * 2^32)` |
| `0x0C` | MOD_FWORD | default 2 MHz AM modulation word |
| `0x10` | SD_PHASE | direct-path carrier phase offset word |
| `0x14` | SM_PHASE | multipath extra phase offset word |
| `0x18` | DELAY_CARRIER_PHASE | carrier phase delay word from delay ns |
| `0x1C` | DELAY_MOD_PHASE | 2 MHz modulation delay phase word |
| `0x20` | SD_GAIN_Q14 | direct gain, Q14 |
| `0x24` | SM_GAIN_Q14 | multipath gain after attenuation, Q14 |
| `0x28` | AM_DEPTH_Q14 | AM depth, Q14 |
| `0x2C` | DC_OFFSET | normally 8192 |
| `0x30` | OUT_A_SEL | 0=SD, 1=SM, 2=SOut, 3=DC |
| `0x34` | OUT_B_SEL | 0=SD, 1=SM, 2=SOut, 3=DC |
| `0x38` | VERSION | expected `0xAD976701` |
| `0x3C` | SAMPLE_RATE | expected `125000000` |

## Problem-C Parameter Coverage

| Requirement | PS/PL support |
|---|---|
| Carrier 30-40 MHz, 1 MHz step | PS writes `CARRIER_FWORD` |
| CW/AM mode | CTRL bit1 controls AM |
| AM modulation 2 MHz | PS writes `MOD_FWORD`; helper defaults to 2 MHz |
| SD amplitude 100 mV-1 V | PS writes calibrated `SD_GAIN_Q14` |
| AM depth 30%-90% | PS writes `AM_DEPTH_Q14` |
| SM delay 50-200 ns | PS converts delay to carrier/mod phase delay words |
| SM attenuation 0-20 dB | PS writes `SM_GAIN_Q14` from dB |
| SM phase 0-180 deg | PS writes `SM_PHASE` |
| SD/SM/SOut test points | A/B DAC outputs independently select SD/SM/SOut |

## Provisional AD9767 Pins

See constraints/lemon_pynqz1_ad9767.xdc. It reuses the former ADC-side right header area and should be edited after real wiring is confirmed.

## AD9767 Timing Architecture

The high-speed DAC datapath is separated from AXI-Lite control. AXI writes update shadow registers, then the DAC clock domain commits the parameter set with a synchronized toggle.

The current implementation uses a pipelined local phase-accumulator + BRAM sine LUT + DSP multiply/add path, with registered DAC outputs and IOB placement constraints. This keeps PS-side parameter control simple and already meets non-negative implemented WNS in the generated overlay.

For the next performance-oriented revision, the internal DDS can be replaced by Vivado DDS Compiler IP plus DSP48 Multiplier IP while preserving the same AXI register contract. That would delegate phase truncation, LUT latency, DSP pipelining, and AXIS-friendly streaming to Xilinx IP.

## Timing

Vivado timing summary line after implementation:

```text
1.049        0.000                      0                 4692        0.052        0.000                      0                 4692        3.020        0.000                       0                  1859
```

The build script fails if implemented WNS is negative.

