param([string]$OutputDirectory = (Join-Path $PSScriptRoot 'dist'))

$ErrorActionPreference = 'Stop'
$source = $PSScriptRoot
$tocPath = Join-Path $source 'ForeverVendetta.toc'
$toc = Get-Content -LiteralPath $tocPath
$version = (($toc | Where-Object { $_ -match '^## Version:' }) -replace '^## Version:\s*', '').Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'Invalid version in TOC' }

# Lua load order comes from the TOC. Docs for humans ship beside them.
$files = @('ForeverVendetta.toc')
foreach ($line in $toc) {
    $path = $line.Trim()
    if ($path -eq '' -or $path.StartsWith('#')) { continue }
    $files += ($path -replace '\\', '/')
}
$files += @('README.md', 'CHANGELOG.md', 'LICENSE')
$files = $files | Select-Object -Unique

foreach ($file in $files) {
    $full = Join-Path $source ($file -replace '/', '\')
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "Missing $file" }
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$destination = Join-Path (Resolve-Path -LiteralPath $OutputDirectory).Path "ForeverVendetta-$version.zip"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$stream = [System.IO.File]::Open($destination, [System.IO.FileMode]::Create)
$zip = [System.IO.Compression.ZipArchive]::new($stream, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in $files) {
        $full = Join-Path $source ($file -replace '/', '\')
        $entry = "ForeverVendetta/" + ($file -replace '\\', '/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $full, $entry) | Out-Null
    }
} finally { $zip.Dispose(); $stream.Dispose() }
Write-Output $destination
