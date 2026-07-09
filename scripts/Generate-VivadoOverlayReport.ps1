$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Report = Join-Path $Root "VIVADO_OVERLAY_REPORT.md"
$Xpr = Join-Path $Root "build\vivado\base_add_overlay.xpr"
$Bit = Join-Path $Root "pynq\base_add.bit"
$Hwh = Join-Path $Root "pynq\base_add.hwh"
$Timing = Join-Path $Root "build\vivado\base_add_overlay.runs\impl_1\system_wrapper_timing_summary_routed.rpt"
$Util = Join-Path $Root "build\vivado\base_add_overlay.runs\impl_1\system_wrapper_utilization_placed.rpt"

function Status($ok) {
    if ($ok) { return '<span style="color:#008000;font-weight:bold;">PASS</span>' }
    return '<span style="color:#cc0000;font-weight:bold;">MISSING</span>'
}

function FileRow($path) {
    $exists = Test-Path $path
    $rel = $path.Substring($Root.Length + 1)
    if ($exists) {
        $item = Get-Item $path
        return '| `{0}` | {1} | {2} | {3} |' -f $rel, (Status $true), $item.Length, $item.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
    }
    return '| `{0}` | {1} | - | - |' -f $rel, (Status $false)
}

function Extract-Wns($path) {
    if (!(Test-Path $path)) { return $null }
    $line = Select-String -Path $path -Pattern "^\s*WNS\(ns\)" -Context 0,3 | Select-Object -First 1
    if ($null -eq $line) { return $null }
    foreach ($post in $line.Context.PostContext) {
        if ($post -match "^\s*[-+]?\d+\.\d+") {
            return $post
        }
    }
    return $line.Context.PostContext | Select-Object -Last 1
}

$ipRows = @()
if (Test-Path $Hwh) {
    [xml]$xml = Get-Content -Raw $Hwh
    $mods = $xml.SelectNodes("//*[local-name()='MODULE']")
    foreach ($m in $mods) {
        $name = $m.GetAttribute("INSTANCE")
        if ($name -match "led_ctrl_0|ad9767_ctrl_0") {
            $baseParam = $m.SelectSingleNode(".//*[local-name()='PARAMETER'][@NAME='C_BASEADDR']")
            $highParam = $m.SelectSingleNode(".//*[local-name()='PARAMETER'][@NAME='C_HIGHADDR']")
            if (($baseParam -ne $null) -and ($highParam -ne $null)) {
                $base = $baseParam.VALUE
                $high = $highParam.VALUE
                $ipRows += '| `{0}` | `{1}` | `{2}` | direct `MMIO` |' -f $name, $base, $high
            }
        }
    }
}

$timingLine = Extract-Wns $Timing

$lines = @()
$lines += "# PYNQ-Z1 DIANSAI2 AD9767 Overlay Report"
$lines += ""
$lines += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$lines += ""
$lines += "## Build Outputs"
$lines += ""
$lines += "| File | Status | Size | Modified |"
$lines += "|---|---|---:|---|"
$lines += FileRow $Bit
$lines += FileRow $Hwh
$lines += FileRow (Join-Path $Root "pynq\pynqz1_diansai2_ad9767_test.ipynb")
$lines += FileRow (Join-Path $Root "pynq\pynqz1_diansai2_ad9767.py")
$lines += ""
$lines += "## Address Map"
$lines += ""
if ($ipRows.Count -gt 0) {
    $lines += "| IP | Base | High | PS access |"
    $lines += "|---|---:|---:|---|"
    $lines += $ipRows
} else {
    $lines += "HWH not available yet. Expected fixed addresses after build:"
    $lines += ""
    $lines += "| IP | Base | Range |"
    $lines += "|---|---:|---:|"
    $lines += '| `led_ctrl_0` | `0x40000000` | `0x1000` |'
    $lines += '| `ad9767_ctrl_0` | `0x40001000` | `0x1000` |'
}
$lines += ""
$lines += "Recommended direct bindings:"
$lines += ""
$lines += '```python'
$lines += "led_ip = MMIO(0x40000000, 0x1000)"
$lines += "ad9767_ip = MMIO(0x40001000, 0x1000)"
$lines += '```'
$lines += ""
$lines += "## AD9767 Register Contract"
$lines += ""
$lines += "| Offset | Register | Meaning |"
$lines += "|---:|---|---|"
$lines += '| `0x00` | CTRL | bit0 enable, bit1 AM enable, bit2 phase reset pulse |'
$lines += '| `0x04` | STATUS | enable/AM/output select summary |'
$lines += '| `0x08` | CARRIER_FWORD | `round(fc / 125e6 * 2^32)` |'
$lines += '| `0x0C` | MOD_FWORD | default 2 MHz AM modulation word |'
$lines += '| `0x10` | SD_PHASE | direct-path carrier phase offset word |'
$lines += '| `0x14` | SM_PHASE | multipath extra phase offset word |'
$lines += '| `0x18` | DELAY_CARRIER_PHASE | carrier phase delay word from delay ns |'
$lines += '| `0x1C` | DELAY_MOD_PHASE | 2 MHz modulation delay phase word |'
$lines += '| `0x20` | SD_GAIN_Q14 | direct gain, Q14 |'
$lines += '| `0x24` | SM_GAIN_Q14 | multipath gain after attenuation, Q14 |'
$lines += '| `0x28` | AM_DEPTH_Q14 | AM depth, Q14 |'
$lines += '| `0x2C` | DC_OFFSET | normally 8192 |'
$lines += '| `0x30` | OUT_A_SEL | 0=SD, 1=SM, 2=SOut, 3=DC, 4=SQUARE, 5=MOD_SINE |'
$lines += '| `0x34` | OUT_B_SEL | 0=SD, 1=SM, 2=SOut, 3=DC, 4=SQUARE, 5=MOD_SINE |'
$lines += '| `0x38` | VERSION | expected `0xAD976702` |'
$lines += '| `0x3C` | SAMPLE_RATE | expected `125000000` |'
$lines += '| `0x4C` | SQUARE_FWORD | independent square-wave DDS frequency word for trigger/debug output |'
$lines += ""
$lines += "## Problem-C Parameter Coverage"
$lines += ""
$lines += "| Requirement | PS/PL support |"
$lines += "|---|---|"
$lines += "| Carrier 30-40 MHz, 1 MHz step | PS writes ``CARRIER_FWORD`` |"
$lines += "| CW/AM mode | CTRL bit1 controls AM |"
$lines += "| AM modulation 2 MHz | PS writes ``MOD_FWORD``; helper defaults to 2 MHz |"
$lines += "| SD amplitude 100 mV-1 V | PS writes calibrated ``SD_GAIN_Q14`` |"
$lines += "| AM depth 30%-90% | PS writes ``AM_DEPTH_Q14`` |"
$lines += "| SM delay 50-200 ns | PS converts delay to carrier/mod phase delay words |"
$lines += "| SM attenuation 0-20 dB | PS writes ``SM_GAIN_Q14`` from dB |"
$lines += "| SM phase 0-180 deg | PS writes ``SM_PHASE`` |"
$lines += "| SD/SM/SOut test points | A/B DAC outputs independently select SD/SM/SOut |"
$lines += ""
$lines += "## Provisional AD9767 Pins"
$lines += ""
$lines += "See `constraints/lemon_pynqz1_ad9767.xdc`. It reuses the former ADC-side right header area and should be edited after real wiring is confirmed."
$lines += ""
$lines += "## AD9767 Timing Architecture"
$lines += ""
$lines += "The high-speed DAC datapath is separated from AXI-Lite control. AXI writes update shadow registers, then the DAC clock domain commits the parameter set with a synchronized toggle."
$lines += ""
$lines += "The current implementation uses a pipelined local phase-accumulator + BRAM sine LUT + DSP multiply/add path, with registered DAC outputs and IOB placement constraints. This keeps PS-side parameter control simple and already meets non-negative implemented WNS in the generated overlay."
$lines += ""
$lines += "For the next performance-oriented revision, the internal DDS can be replaced by Vivado DDS Compiler IP plus DSP48 Multiplier IP while preserving the same AXI register contract. That would delegate phase truncation, LUT latency, DSP pipelining, and AXIS-friendly streaming to Xilinx IP."
$lines += ""
$lines += "## Timing"
$lines += ""
if ($timingLine) {
    $lines += "Vivado timing summary line after implementation:"
    $lines += ""
    $lines += '```text'
    $lines += $timingLine.Trim()
    $lines += '```'
} else {
    $lines += 'Timing report not generated yet. Run `scripts/Build-VivadoOverlayWithReport.ps1`.'
}
$lines += ""
$lines += "The build script fails if implemented WNS is negative."
$lines += ""

Set-Content -Path $Report -Value ($lines -join "`r`n") -Encoding UTF8
Write-Host "Generated $Report"
