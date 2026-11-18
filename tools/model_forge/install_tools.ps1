# install_tools.ps1 — install the model_forge toolchain (idempotent).
# Requires: winget, PowerShell 5+ / 7+, internet access for the first run.

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$zip = Join-Path $here 'Sollumz.zip'
$venv = Join-Path $here '.venv'
$blender = 'C:\Program Files\Blender Foundation\Blender 5.3\blender.exe'

function Write-Step($msg) { Write-Host "[model_forge] $msg" -ForegroundColor Cyan }

# 1) Blender 5.3
if (-not (Test-Path -LiteralPath $blender)) {
    Write-Step 'Installing Blender 5.3.0 via winget...'
    winget install --id BlenderFoundation.Blender --version 5.3.0 -e `
        --accept-package-agreements --accept-source-agreements --disable-interactivity
} else {
    Write-Step "Blender already installed: $blender"
}

# 2) Sollumz 2.9.1 extension ZIP
if (-not (Test-Path -LiteralPath $zip)) {
    Write-Step 'Downloading Sollumz 2.9.1...'
    $tmp = Join-Path $env:TEMP 'Sollumz_dl.zip'
    curl.exe -L --fail --silent --show-error -o $tmp 'https://github.com/Sollumz/Sollumz/releases/download/v2.9.1/Sollumz.zip'
    Copy-Item -LiteralPath $tmp -Destination $zip
} else {
    Write-Step "Sollumz ZIP already present: $zip"
}

# 3) Install Sollumz as a Blender extension and its Python dependencies
Write-Step 'Installing/enabling Sollumz in Blender...'
& $blender --background --command extension install-file -r user_default -e $zip 2>&1 | Out-Null
Write-Step 'Installing szio + PyMateria inside Blender...'
& $blender --background --python-expr 'import bpy; bpy.ops.sollumz.install_dependencies()' 2>&1 | Out-Null

# 4) Standalone venv for forge.py (reading RPFs without Blender)
if (-not (Test-Path -LiteralPath (Join-Path $venv 'Scripts\python.exe'))) {
    Write-Step 'Creating Python venv...'
    & (Get-Command python).Source -m venv $venv
}
$py = Join-Path $venv 'Scripts\python.exe'
Write-Step 'Installing szio + PyMateria in venv...'
& $py -m pip install --upgrade pip 2>&1 | Out-Null
& $py -m pip install --quiet 'szio==1.4.0' 2>&1 | Out-Null
& $py -m pip install --quiet --extra-index-url https://static.cfx.re/whl/ 'pymateria==0.2.1' 2>&1 | Out-Null

Write-Step 'Done. Next: run forge.py --reindex to index your GTA V Legacy RPFs.'
