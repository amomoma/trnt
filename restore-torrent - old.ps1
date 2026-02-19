param(
    [string]$SourceFolder = ".",
    [string]$OutputFolder = "restored"
)

Write-Host "Starting restore process..."

# Resolve full absolute paths
$SourceFolder = (Resolve-Path $SourceFolder).Path
$OutputFolder = Join-Path $SourceFolder $OutputFolder

$manifestPath = Join-Path $SourceFolder "MANIFEST_METADATA.txt"

if (!(Test-Path $manifestPath)) {
    Write-Host "❌ MANIFEST_METADATA.txt not found in $SourceFolder"
    exit 1
}

New-Item -ItemType Directory -Force -Path $OutputFolder | Out-Null

Get-Content $manifestPath | ForEach-Object {

    if ($_ -match "^FILE\|") {

        $parts = $_ -split "\|"

        if ($parts.Count -lt 5) { return }

        $encodedPath = $parts[2]
        $safeName    = $parts[3]
        $partCount   = [int]$parts[4]

        # Safe URL decode (works in all PowerShell versions)
        $originalPath = [System.Uri]::UnescapeDataString($encodedPath)

        if ([string]::IsNullOrWhiteSpace($originalPath)) {
            Write-Host "⚠️ Skipping invalid entry"
            return
        }

        $fullOutputPath = Join-Path $OutputFolder $originalPath
        $dir = Split-Path $fullOutputPath -Parent

        if (![string]::IsNullOrWhiteSpace($dir)) {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
        }

        Write-Host "Restoring $originalPath ..."

        # Create empty file
        if (Test-Path $fullOutputPath) {
            Remove-Item $fullOutputPath -Force
        }

        for ($i = 1; $i -le $partCount; $i++) {

            $partFile = "{0}.part.{1:D4}" -f $safeName, $i
            $partPath = Join-Path $SourceFolder $partFile

            if (!(Test-Path $partPath)) {
                Write-Host "❌ Missing part: $partFile"
                exit 1
            }

            Add-Content -Path $fullOutputPath -Value ([System.IO.File]::ReadAllBytes($partPath)) -Encoding Byte
        }

        Write-Host "  ✅ Done"
    }

    elseif ($_ -match "^EMPTY_DIR\|") {

        $parts = $_ -split "\|"
        if ($parts.Count -lt 3) { return }

        $encodedPath = $parts[2]
        $originalPath = [System.Uri]::UnescapeDataString($encodedPath)

        if (![string]::IsNullOrWhiteSpace($originalPath)) {
            $dirPath = Join-Path $OutputFolder $originalPath
            New-Item -ItemType Directory -Force -Path $dirPath | Out-Null
        }
    }
}

Write-Host ""
Write-Host "🎉 Restore complete!"
