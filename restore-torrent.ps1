param(
    [string]$SourceFolder = ".",
    [string]$OutputFolder = "restored"
)

Write-Host "Starting restore process..."

$SourceFolder = (Resolve-Path $SourceFolder).Path
$OutputFolder = Join-Path $SourceFolder $OutputFolder

$manifestPath = Join-Path $SourceFolder "MANIFEST_METADATA.txt"

if (!(Test-Path $manifestPath)) {
    Write-Host "❌ MANIFEST_METADATA.txt not found!"
    exit 1
}

New-Item -ItemType Directory -Force -Path $OutputFolder | Out-Null

Get-Content $manifestPath | ForEach-Object {

    if ($_ -match "^FILE\|") {

        $parts = $_ -split "\|"
        if ($parts.Count -lt 5) { return }

        $hash        = $parts[1]
        $encodedPath = $parts[2]
        $partCount   = [int]$parts[4]

        $originalPath = [System.Uri]::UnescapeDataString($encodedPath)
        $fullOutputPath = Join-Path $OutputFolder $originalPath
        $dir = Split-Path $fullOutputPath -Parent

        if (![string]::IsNullOrWhiteSpace($dir)) {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
        }

        Write-Host "Restoring $originalPath ..."

        if (Test-Path $fullOutputPath) {
            Remove-Item $fullOutputPath -Force
        }

        # 🔥 Find parts by HASH prefix instead of full filename
        $partsFiles = Get-ChildItem $SourceFolder -Filter "$hash*.part.*" | Sort-Object Name

        if ($partsFiles.Count -ne $partCount) {
            Write-Host "❌ Expected $partCount parts but found $($partsFiles.Count)"
            exit 1
        }

        foreach ($part in $partsFiles) {
            Add-Content -Path $fullOutputPath -Value ([System.IO.File]::ReadAllBytes($part.FullName)) -Encoding Byte
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
