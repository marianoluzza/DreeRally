[CmdletBinding()]
param([string]$Source, [switch]$ReportOnly)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
if (!$Source) {
    $settings = Join-Path $root '.local\settings.json'
    if (Test-Path $settings) { $Source = (Get-Content $settings -Raw | ConvertFrom-Json).assetSource }
}
if (!$Source) { $Source = Join-Path $root 'runtime' }
if (!(Test-Path -LiteralPath $Source -PathType Container)) { throw "Asset folder not found: $Source" }
$required = @('ENGINE.BPA','IBFILES.BPA','MENU.BPA','MUSICS.BPA','TRX.BPA','ENDANI.haf','SANIM.haf','SDL.dll','fmod.dll')
$missing = @()
Write-Host "Checking: $Source"
foreach ($name in $required) {
    if (Test-Path -LiteralPath (Join-Path $Source $name) -PathType Leaf) { Write-Host "[OK]      $name" }
    else { Write-Host "[MISSING] $name"; $missing += $name }
}
# The upstream README lists this legacy dependency; it may be needed by its DLLs.
if (!(Test-Path -LiteralPath (Join-Path $Source 'msvcr71.dll'))) { Write-Warning 'msvcr71.dll is absent; validate the dependencies of the original Windows DLLs.' }
if ($missing.Count -and !$ReportOnly) { throw "Missing runtime files: $($missing -join ', '). See doc/ASSETS.md." }
if (!$missing.Count) { Write-Host 'Required filenames are present. Format/architecture and gameplay still need validation.' }
