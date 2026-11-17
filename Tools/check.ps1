# Every check before an install, in one command:
#   powershell -ExecutionPolicy Bypass -File Tools\check.ps1
# 1. Lua 5.1 syntax of every file (luac -p) and image paths with two backslashes;
# 2. text files in valid UTF-8 without a BOM; Lua files in ASCII, except
#    Locales.lua (the EllesmereUI rule);
# 3. the offline tests.
# Exit code 0: all good; 1: at least one problem (deploy.ps1 then refuses to install).

$Root = Split-Path $PSScriptRoot -Parent
# Lua 5.1 (luac5.1.exe, lua5.1.exe): $env:LUA51, else Documents\Git\LUA 51.
$Lua = if ($env:LUA51) { $env:LUA51 } else { Join-Path $env:USERPROFILE 'Documents\Git\LUA 51' }
$Luac = Join-Path $Lua 'luac5.1.exe'
$Interp = Join-Path $Lua 'lua5.1.exe'
$Problems = 0
Push-Location $Root

$Files = Get-ChildItem $Root -Recurse -File -Include *.lua, *.toc, *.md |
    Where-Object { $_.FullName -notmatch '\\(\.git|\.cache)\\' }

# 1. Syntax.
foreach ($File in ($Files | Where-Object { $_.Extension -eq '.lua' })) {
    & $Luac -p $File.FullName 2>&1 | ForEach-Object { Write-Host $_ -ForegroundColor Red; $script:Problems++ }
    # "Interface\Icons..." with one backslash loads without a word but shows nothing.
    Select-String -Path $File.FullName -Pattern '"Interface\\[A-Za-z]' -CaseSensitive | ForEach-Object {
        Write-Host "Image path with one backslash: $($_.Path):$($_.LineNumber)" -ForegroundColor Red
        $script:Problems++
    }
}
if (Test-Path (Join-Path $Root 'luac.out')) { Remove-Item (Join-Path $Root 'luac.out') }
Write-Host "Syntax: checked" -ForegroundColor Green

# 2. Encoding.
$Strict = New-Object System.Text.UTF8Encoding $false, $true
foreach ($File in $Files) {
    $Bytes = [System.IO.File]::ReadAllBytes($File.FullName)
    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) {
        Write-Host "BOM: $($File.FullName)" -ForegroundColor Red; $Problems++
    }
    try { [void]$Strict.GetString($Bytes) }
    catch { Write-Host "Broken UTF-8: $($File.FullName)" -ForegroundColor Red; $Problems++; continue }
    if ($File.Extension -eq '.lua' -and $File.Name -ne 'Locales.lua' -and ($Bytes | Where-Object { $_ -gt 127 } | Select-Object -First 1)) {
        Write-Host "Not ASCII: $($File.FullName)" -ForegroundColor Red; $Problems++
    }
}
Write-Host "Encoding: checked" -ForegroundColor Green

# 3. Tests.
& $Interp 'Tests/test_data.lua' 2>&1 | ForEach-Object {
    if ($_ -match 'OK$') { Write-Host $_ -ForegroundColor Green } else { Write-Host $_ -ForegroundColor Red; $script:Problems++ }
}
if ($LASTEXITCODE -ne 0) { $Problems++ }

Pop-Location
if ($Problems -gt 0) { Write-Host "$Problems problem(s)" -ForegroundColor Red; exit 1 }
Write-Host "All good" -ForegroundColor Green
exit 0
