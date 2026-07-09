$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Vivado = "G:\VIVADO2022\Vivado\2022.1\bin\vivado.bat"

if (!(Test-Path $Vivado)) {
    throw "Vivado 2022.1 not found: $Vivado"
}

Push-Location $Root
try {
    & $Vivado -mode batch -source "$Root\vivado\build.tcl"
    if ($LASTEXITCODE -ne 0) {
        throw "Vivado build failed with exit code $LASTEXITCODE"
    }
    & "$Root\scripts\Generate-VivadoOverlayReport.ps1"
} finally {
    Pop-Location
}
