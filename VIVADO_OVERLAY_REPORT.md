# PYNQ-Z1 DIANSAI2 MAX5885 + LTC2208 Overlay Report

Generated: 2026-07-22 18:56:45

## Build Outputs

| File | Status | Size | Modified |
|---|---|---:|---|
| `pynq\base_add.bit` | <span style="color:#008000;font-weight:bold;">PASS</span> | 4045674 | 2026-07-22 18:55:05 |
| `pynq\base_add.hwh` | <span style="color:#008000;font-weight:bold;">PASS</span> | 394396 | 2026-07-22 18:49:22 |
| `pynq\pynqz1_diansai2_max5885_ltc2208_test.ipynb` | <span style="color:#008000;font-weight:bold;">PASS</span> | 3204 | 2026-07-22 17:26:37 |
| `pynq\pynqz1_diansai2_max5885.py` | <span style="color:#008000;font-weight:bold;">PASS</span> | 5420 | 2026-07-11 23:14:02 |
| `pynq\pynqz1_diansai2_ltc2208.py` | <span style="color:#008000;font-weight:bold;">PASS</span> | 4870 | 2026-07-22 17:28:40 |

## Address Map

| IP | Base | High | PS access |
|---|---:|---:|---|
| `led_ctrl_0` | `0x40000000` | `0x40000FFF` | direct `MMIO` |
| `ltc2208_capture_0` | `0x40002000` | `0x40002FFF` | direct `MMIO` |
| `max5885_ctrl_0` | `0x40001000` | `0x40001FFF` | direct `MMIO` |

Recommended direct bindings:

```python
led_ip = MMIO(0x40000000, 0x1000)
max5885_ip = MMIO(0x40001000, 0x1000)
ltc2208_ip = MMIO(0x40002000, 0x1000)
```

## LTC2208 Register Contract

| Offset | Register | Meaning |
|---:|---|---|
| `0x00` | CTRL | bit0 enable clocks, bit1 start toggle, bit2 clear toggle |
| `0x04` | STATUS | busy, complete, fatal error |
| `0x08` | SAMPLE_COUNT | requested dual-channel samples |
| `0x14` | DECIMATION | 1 for full 130 MSPS |
| `0x18` | CHANNEL_MASK | bit0 A, bit1 B |
| `0x1C` | CAPTURE_MODE | 1 real ADC, 2 internal fake pattern |
| `0x2C/0x30` | LATEST_A/LATEST_B | latest 16-bit offset-binary codes |
| `0x34` | SAMPLE_COUNTER | captured sample count |
| `0x3C` | ERROR_FLAGS | capture error summary |
| `0x44` | VERSION | expected `0x22081300` |
| `0x54/0x58` | AXIS_SENT/AXIS_STALL | stream diagnostics |
| `0x64` | DROPPED_SAMPLE_COUNT | must remain zero |

## MAX5885 and LTC2208 PS Coverage

| Requirement | PS/PL support |
|---|---|
| MAX5885 carrier/mode/amplitude/phase | PS helper at 200 MSPS |
| LTC2208 dual-channel samples | PS helper at 130 MSPS |
| Capture length/channel mask/decimation | direct PS register configuration |
| DDR transfer diagnostics | AXIS sent/stall/drop counters |

## LTC2208 Pins

See constraints/lemon_pynqz1_ltc2208.xdc and docs/MAX5885_LTC2208_Integration.md. P2 is a direct 2x17 data-header mapping, with no jumper or AD9226 compatibility layout.

## Timing Architecture

MAX5885 stays in its independent 200 MHz domain. LTC2208 uses 130 MHz forwarded clocks, IOB input registers, and an asynchronous 64-bit AXIS FIFO to the 125 MHz DMA domain.

125 MHz control and 130 MHz capture are explicitly asynchronous: start uses a synchronized toggle, status uses synchronizers, and sample data crosses only through the asynchronous FIFO.

## Timing

Vivado timing summary line after implementation:

```text
0.024        0.000                      0                13954        0.041        0.000                      0                13954        1.116        0.000                       0                  5606
```

The build script fails if implemented WNS is negative.

