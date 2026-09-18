[CmdletBinding()]
param([string]$AssetSource, [switch]$Open)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$local = Join-Path $root '.local'
New-Item -ItemType Directory -Path $local -Force | Out-Null
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (!$vs) { throw 'No C++ toolchain found.' }
$version = (Get-Content (Join-Path $vs 'VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.txt')).Trim()
$compiler = Join-Path $vs "VC\Tools\MSVC\$version\bin\Hostx64\x86\cl.exe"
# The machine-specific compiler path stays in an ignored file.
@{ compilerPath = $compiler } | ConvertTo-Json | Set-Content (Join-Path $local 'toolchain.json') -Encoding UTF8
if ($AssetSource) {
    if (!(Test-Path -LiteralPath $AssetSource -PathType Container)) { throw "Folder not found: $AssetSource" }
    @{ assetSource = (Resolve-Path $AssetSource).Path } | ConvertTo-Json | Set-Content (Join-Path $local 'settings.json') -Encoding UTF8
}
# Generate an ignored workspace so IntelliSense uses the detected compiler.
$workspace = @{
    folders = @(@{ path = '..' })
    settings = @{ 'C_Cpp.default.compilerPath' = $compiler }
} | ConvertTo-Json -Depth 5
$workspaceFile = Join-Path $local 'DreeRally.code-workspace'
$workspace | Set-Content $workspaceFile -Encoding UTF8
Write-Host "Workspace: $workspaceFile"
if ($Open) { & code --new-window $workspaceFile }
