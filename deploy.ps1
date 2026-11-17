# Copies the addon (the ClassicOrNot folder) into WoW Forever's AddOns folder,
# after Tools\check.ps1 passes.
# Usage: powershell -ExecutionPolicy Bypass -File C:\Dev\Addons\ClassicOrNot\deploy.ps1

$AddOns = 'D:\Battle.net\World of Warcraft\_forever_\Interface\AddOns'
if (-not (Test-Path $AddOns)) { Write-Host "AddOns folder not found: $AddOns" -ForegroundColor Red; exit 1 }

& powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Tools\check.ps1') | Out-Host
if ($LASTEXITCODE -ne 0) { Write-Host "Install cancelled: fix it first." -ForegroundColor Red; exit 1 }

$Source = Join-Path $PSScriptRoot 'ClassicOrNot'
$Dest = Join-Path $AddOns 'ClassicOrNot'
robocopy $Source $Dest /MIR /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { Write-Host "ClassicOrNot: copy ERROR" -ForegroundColor Red; exit 1 }
Write-Host "ClassicOrNot: OK ($Dest)" -ForegroundColor Green
Write-Host "New addon or changed .toc: restart the game. Otherwise: /reload."
exit 0
