param([string]$OutputDirectory = (Join-Path $PSScriptRoot 'dist'))

$ErrorActionPreference = 'Stop'
$source = $PSScriptRoot
$toc = Get-Content -LiteralPath (Join-Path $source 'ForeverVendetta.toc')
$version = (($toc | Where-Object { $_ -match '^## Version:' }) -replace '^## Version:\s*', '').Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid version in TOC' }

# CurseForge / Install zip. Tests and tooling stay out of the package.
$files = @('ForeverVendetta.toc', 'Core.lua', 'Comms.lua', 'UI.lua', 'Main.lua', 'README.md', 'CHANGELOG.md', 'LICENSE')
foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath (Join-Path $source $file) -PathType Leaf)) { throw "Missing $file" }
}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$destination = Join-Path (Resolve-Path -LiteralPath $OutputDirectory).Path "ForeverVendetta-$version.zip"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$stream = [System.IO.File]::Open($destination, [System.IO.FileMode]::Create)
$zip = [System.IO.Compression.ZipArchive]::new($stream, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in $files) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, (Join-Path $source $file), "ForeverVendetta/$file") | Out-Null
    }
} finally { $zip.Dispose(); $stream.Dispose() }
Write-Output $destination
