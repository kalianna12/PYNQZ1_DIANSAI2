# PYNQZ1_DIANSAI2

Clean PYNQ-Z1 Vivado 2022.1 project for the C-problem wireless transmission
signal simulator bring-up.

This project is derived from the current known-good PYNQ-Z1 AD9102/board-IO
overlay, then replaces the AD9226 ADC/DMA path with a PS-controlled AD9767
waveform-output path.

## Hardware Blocks

- `led_ctrl_0`
  - PS-controlled LD0..LD3, LD4/LD5 RGB, BTN0..BTN3.
  - Address target: `0x40000000`.
- `ad9102_ctrl_0`
  - Existing known-good AD9102 SPI/control interface.
  - AD9102 pins and Python helper are kept unchanged.
  - Address target: `0x40001000`.
- `ad9767_ctrl_0`
  - New AD9767 dual-output signal generator.
  - Fixed output sample clock: 125 MSPS.
  - PS writes all user-facing parameters.
  - Address target: `0x40002000`.

## C-Problem Control Targets

The AD9767 helper exposes these problem parameters from Python:

- Carrier frequency `fc`: 30 MHz to 40 MHz, intended 1 MHz steps.
- Mode: CW or AM.
- AM modulation frequency: fixed default 2 MHz.
- AM depth: 30% to 90%.
- Direct signal `SD` amplitude and phase.
- Multipath signal `SM` relative delay, phase, and attenuation.
- Output selection for each physical DAC channel: `SD`, `SM`, `SOUT`, or `DC`.

The PL keeps the fast 125 MSPS waveform path running. The PS converts physical
parameters to phase words and Q14 gains, so calibration changes can happen in
Python without rebuilding the bitstream.

## AD9767 Timing Architecture

The current AD9767 block is built as a clean migration version, not yet the
final DDS-Compiler-based version.

Already applied in this build:

- AXI-Lite control and the 125 MSPS DAC waveform path are separated.
- PS writes shadow registers; the DAC clock domain commits a coherent parameter
  set through a synchronized toggle.
- The carrier/modulation phase path is split before the sine LUT address input,
  so the former `phase_acc -> phase offset -> BRAM address` critical path is no
  longer a 32-bit carry-chain path.
- The waveform path is pipelined across LUT read, multiply, envelope, add, and
  output stages instead of doing one long LUT/multiply/add/DAC path.
- AM envelope/signals use narrowed 18-bit internal multiply operands where the
  numeric range allows it, reducing DSP48 cascade pressure.
- The sine table is implemented as BRAM ROM.
- DAC data outputs are registered at the IO boundary with IOB placement
  constraints.
- The build script rejects negative implemented WNS.

Latest implemented timing result:

```text
WNS = 1.191 ns, TNS = 0.000 ns, WHS = 0.040 ns
```

The original post-route bottleneck was the AD9767 phase accumulator to BRAM LUT
address path. After the phase-address pipeline and multiplier-width cleanup, the
design still has margin at 125 MHz. A tested attempt to pre-register the final
DAC output select mux did not improve routed WNS, so it was not kept.

Recommended next performance revision:

- Replace the local phase-accumulator + sine LUT path with Vivado DDS Compiler
  IP.
- Use Xilinx Multiplier IP/DSP48 blocks explicitly for gain and AM envelope
  scaling.
- Keep AXI out of the high-speed datapath; preserve the same PS register
  contract so the current Python notebook remains usable.

## Important Files

- `vivado/build.tcl`: builds the overlay and copies `base_add.bit/.hwh`.
- `scripts/Build-VivadoOverlayWithReport.ps1`: Vivado 2022.1 build entry.
- `scripts/Generate-VivadoOverlayReport.ps1`: build/address/register report.
- `rtl/src/ad9767_signal_axi.v`: AD9767 AXI-Lite controlled signal generator.
- `rtl/src/sine_lut_1024.v`: shared sine ROM.
- `constraints/lemon_pynqz1_ad9767.xdc`: provisional AD9767 pinout.
- `pynq/pynqz1_diansai2_ad9767.py`: PS-side AD9767 parameter helper.
- `pynq/pynqz1_diansai2_ad9767_test.ipynb`: board, AD9102, AD9767 tests.
- `legacy_reference/`: old AD9767 files that produced normal waveforms before.

## Provisional AD9767 Pinout

The first migration reuses the ADC-side right expansion header area. The actual
AD9767 board wiring is expected to change after real hardware insertion, so keep
pin edits isolated to:

```text
constraints/lemon_pynqz1_ad9767.xdc
```

AD9102 and board IO constraints should not be changed unless the wiring changes.

## Build

From this folder:

```powershell
.\scripts\Build-VivadoOverlayWithReport.ps1
```

The script uses:

```text
G:\VIVADO2022\Vivado\2022.1\bin\vivado.bat
```

The build script fails if implemented WNS is negative. On success it generates:

- `pynq/base_add.bit`
- `pynq/base_add.hwh`
- `VIVADO_OVERLAY_REPORT.md`

## PYNQ Use

Copy the files in `pynq/` to one folder on the PYNQ-Z1 board, then open:

```text
pynqz1_diansai2_ad9767_test.ipynb
```

Run cells in order:

1. Load overlay and bind fixed MMIO addresses.
2. Test LD0..LD3, RGB LEDs, and BTN0..BTN3.
3. Smoke-test the unchanged AD9102 path.
4. Configure AD9767 C-problem waveform parameters.
5. Use the preset cell for manual oscilloscope tuning.

## Notes For Next Hardware Pass

- If Vivado assigns different addresses, update the report and Python constants
  after checking `base_add.hwh`.
- If AD9767 data order is reversed on the real module, fix only the XDC bit
  mapping first.
- If amplitude is not calibrated in mV/Vrms, adjust `full_scale_vrms` or add a
  calibration table in `pynqz1_diansai2_ad9767.py`.
- If three simultaneous analog test points are required, add another DAC/output
  path or use an external analog switching/combining strategy. This first PL
  version lets the two AD9767 channels independently select `SD`, `SM`, or
  `SOUT` for bring-up.
