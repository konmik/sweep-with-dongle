$ErrorActionPreference = "Stop"

$board = "nice_nano/nrf52840/zmk"
$appDir = "$PSScriptRoot\zmk\zmk\app"
$outDir = $PSScriptRoot
$shieldsDir = "$PSScriptRoot\shields\cradio"
$targetDir = "$appDir\boards\shields\cradio"

Copy-Item "$shieldsDir\*" $targetDir -Force
Write-Host "Copied tracked shield files to ZMK tree" -ForegroundColor Yellow

function Build($name, $extraArgs) {
    Write-Host "`n=== Building $name ===" -ForegroundColor Cyan
    Set-Location $appDir
    if (Test-Path build) { Remove-Item -Recurse -Force build }
    $cmd = "west build -b $board $extraArgs"
    Write-Host $cmd
    Invoke-Expression $cmd
    if ($LASTEXITCODE -ne 0) { throw "Build failed: $name" }
    Copy-Item "$appDir\build\zephyr\zmk.uf2" "$outDir\$name.uf2" -Force
    Write-Host "  -> $outDir\$name.uf2" -ForegroundColor Green
}

Build "settings_reset" "-- -DSHIELD=settings_reset"
Build "cradio_dongle" "-- -DSHIELD=cradio_dongle"
Build "cradio_left"   "-- -DSHIELD=cradio_left -DCONFIG_ZMK_SPLIT_ROLE_CENTRAL=n"
Build "cradio_right"  "-- -DSHIELD=cradio_right"

Write-Host "`n=== All builds complete ===" -ForegroundColor Green
Write-Host "Flash order for each nice!nano:"
Write-Host "  1. settings_reset.uf2"
Write-Host "  2. cradio_dongle.uf2 / cradio_left.uf2 / cradio_right.uf2"
Write-Host "Then power all three simultaneously to auto-pair."
