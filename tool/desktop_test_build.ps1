# Builds KFM for Windows (release), copies it to %LOCALAPPDATA%\KFM-test
# and (re)creates the "KFM (test)" shortcut on the desktop.
# Usage: powershell -ExecutionPolicy Bypass -File tool\desktop_test_build.ps1 [-NoBuild]
param([switch]$NoBuild)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$src = Join-Path $repo 'build\windows\x64\runner\Release'
$dest = Join-Path $env:LOCALAPPDATA 'KFM-test'

if (-not $NoBuild) {
  Push-Location $repo
  try {
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw 'flutter build windows failed' }
  } finally { Pop-Location }
}
if (-not (Test-Path (Join-Path $src 'KFM.exe'))) { throw "No build at $src" }

Get-Process KFM -ErrorAction SilentlyContinue |
  Where-Object { $_.Path -like "$dest*" } | Stop-Process -Force
if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
Copy-Item -Recurse $src $dest

$exe = Join-Path $dest 'KFM.exe'
$desktop = [Environment]::GetFolderPath('Desktop')
$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut((Join-Path $desktop 'KFM (test).lnk'))
$lnk.TargetPath = $exe
$lnk.WorkingDirectory = $dest
$lnk.IconLocation = "$exe,0"
$lnk.Description = 'KFM desktop test build'
$lnk.Save()
Write-Output "Shortcut: $(Join-Path $desktop 'KFM (test).lnk') -> $exe"
