$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Report = Join-Path $Root "RTL_SOURCE_REPORT.md"
$files = Get-ChildItem -Path (Join-Path $Root "rtl") -Recurse -File |
    Where-Object { $_.Extension -in ".v", ".mem" } |
    Sort-Object FullName

$lines = @()
$lines += "# RTL Source Report"
$lines += ""
$lines += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$lines += ""
$lines += "| File | Size | Modified |"
$lines += "|---|---:|---|"
foreach ($f in $files) {
    $rel = $f.FullName.Substring($Root.Length + 1)
    $lines += "| ``$rel`` | $($f.Length) | $($f.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')) |"
}

Set-Content -Path $Report -Value ($lines -join "`r`n") -Encoding UTF8
Write-Host "Generated $Report"
