$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Report = Join-Path $Root "VIVADO_OVERLAY_REPORT.md"
$Xpr = Join-Path $Root "build\vivado_ltc2208\base_add_overlay.xpr"
$Bit = Join-Path $Root "pynq\base_add.bit"
$Hwh = Join-Path $Root "pynq\base_add.hwh"
$Timing = Join-Path $Root "build\vivado_ltc2208\base_add_overlay.runs\impl_1\system_wrapper_timing_summary_routed.rpt"
$Util = Join-Path $Root "build\vivado_ltc2208\base_add_overlay.runs\impl_1\system_wrapper_utilization_placed.rpt"

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
        if ($name -match "led_ctrl_0|max5885_ctrl_0|ltc2208_capture_0") {
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
$lines += "# PYNQ-Z1 DIANSAI2 MAX5885 + LTC2208 Overlay Report"
$lines += ""
$lines += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$lines += ""
$lines += "## Build Outputs"
$lines += ""
$lines += "| File | Status | Size | Modified |"
$lines += "|---|---|---:|---|"
$lines += FileRow $Bit
$lines += FileRow $Hwh
$lines += FileRow (Join-Path $Root "pynq\pynqz1_diansai2_max5885_ltc2208_test.ipynb")
$lines += FileRow (Join-Path $Root "pynq\pynqz1_diansai2_max5885.py")
$lines += FileRow (Join-Path $Root "pynq\pynqz1_diansai2_ltc2208.py")
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
    $lines += '| `max5885_ctrl_0` | `0x40001000` | `0x1000` |'
    $lines += '| `ltc2208_capture_0` | `0x40002000` | `0x1000` |'
}
$lines += ""
$lines += "Recommended direct bindings:"
$lines += ""
$lines += '```python'
$lines += "led_ip = MMIO(0x40000000, 0x1000)"
$lines += "max5885_ip = MMIO(0x40001000, 0x1000)"
$lines += "ltc2208_ip = MMIO(0x40002000, 0x1000)"
$lines += '```'
$lines += ""
$lines += "## LTC2208 Register Contract"
$lines += ""
$lines += "| Offset | Register | Meaning |"
$lines += "|---:|---|---|"
$lines += '| `0x00` | CTRL | bit0 enable clocks, bit1 start toggle, bit2 clear toggle |'
$lines += '| `0x04` | STATUS | busy, complete, fatal error |'
$lines += '| `0x08` | SAMPLE_COUNT | requested dual-channel samples |'
$lines += '| `0x14` | DECIMATION | 1 for full 130 MSPS |'
$lines += '| `0x18` | CHANNEL_MASK | bit0 A, bit1 B |'
$lines += '| `0x1C` | CAPTURE_MODE | 1 real ADC, 2 internal fake pattern |'
$lines += '| `0x2C/0x30` | LATEST_A/LATEST_B | latest 16-bit offset-binary codes |'
$lines += '| `0x34` | SAMPLE_COUNTER | captured sample count |'
$lines += '| `0x3C` | ERROR_FLAGS | capture error summary |'
$lines += '| `0x44` | VERSION | expected `0x22081300` |'
$lines += '| `0x54/0x58` | AXIS_SENT/AXIS_STALL | stream diagnostics |'
$lines += '| `0x64` | DROPPED_SAMPLE_COUNT | must remain zero |'
$lines += ""
$lines += "## MAX5885 and LTC2208 PS Coverage"
$lines += ""
$lines += "| Requirement | PS/PL support |"
$lines += "|---|---|"
$lines += "| MAX5885 carrier/mode/amplitude/phase | PS helper at 200 MSPS |"
$lines += "| LTC2208 dual-channel samples | PS helper at 130 MSPS |"
$lines += "| Capture length/channel mask/decimation | direct PS register configuration |"
$lines += "| DDR transfer diagnostics | AXIS sent/stall/drop counters |"
$lines += ""
$lines += "## LTC2208 Pins"
$lines += ""
$lines += "See `constraints/lemon_pynqz1_ltc2208.xdc` and `docs/MAX5885_LTC2208_Integration.md`. P2 is a direct 2x17 data-header mapping, with no jumper or AD9226 compatibility layout."
$lines += ""
$lines += "## Timing Architecture"
$lines += ""
$lines += "MAX5885 stays in its independent 200 MHz domain. LTC2208 uses 130 MHz forwarded clocks, IOB input registers, and an asynchronous 64-bit AXIS FIFO to the 125 MHz DMA domain."
$lines += ""
$lines += "125 MHz control and 130 MHz capture are explicitly asynchronous: start uses a synchronized toggle, status uses synchronizers, and sample data crosses only through the asynchronous FIFO."
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
