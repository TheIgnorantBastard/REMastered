param(
    [Parameter(Mandatory)][string]$RootPath,
    [Parameter(Mandatory)][string]$MarkdownOutput,
    [Parameter(Mandatory)][string]$CsvOutput
)

Write-Host "Scanning files in $RootPath..." -ForegroundColor Cyan

$OutputTable = @()

Get-ChildItem -Path $RootPath -Recurse -File | ForEach-Object {
    $SizeKB = "{0:N2}" -f ($_.Length / 1KB)
    $Extension = $_.Extension
    $RelativePath = $_.FullName.Replace((Resolve-Path $RootPath), "").TrimStart("\\")

    try {
        $SignatureBytes = Get-Content $_.FullName -Encoding Byte -TotalCount 16
        $HexSignature = ($SignatureBytes | ForEach-Object { '{0:X2}' -f $_ }) -join ' '
    }
    catch {
        $HexSignature = "N/A (Too Small or Error)"
    }

    if ($Extension -eq ".EXE") {
        $InferredType = "Executable Program Code"
    } elseif ($Extension -eq ".COM") {
        $InferredType = "COM Program Code"
    } elseif ($Extension -eq ".FLI") {
        $InferredType = "Autodesk FLIC Animation"
    } elseif ($Extension -eq ".FCB") {
        $InferredType = "Graphics / Panel Data (Custom)"
    } elseif ($Extension -eq ".DAT") {
        $InferredType = "Data File (Custom)"
    } else {
        $InferredType = "Unknown Data File"
    }

    $OutputTable += [PSCustomObject]@{
        "RelativePath"  = $RelativePath
        "FileName"      = $_.Name
        "SizeKB"        = $SizeKB
        "Extension"     = $Extension
        "LastWriteTime" = $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
        "Attributes"    = $_.Attributes.ToString()
        "HexSignature"  = $HexSignature
        "InferredType"  = $InferredType
        "StatusRECheck" = "Untouched"
        "AnalysisNotes" = ""
    }
}

Write-Host "Generating CSV index..." -ForegroundColor Cyan
$OutputTable | Export-Csv -Path $CsvOutput -NoTypeInformation -Encoding UTF8

Write-Host "Generating Markdown index..." -ForegroundColor Cyan

$mdLines = @()
$mdLines += "# Game File Index (Raw Data)"
$mdLines += ""
$mdLines += "Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$mdLines += "Root path: `$RootPath = `$($RootPath)"
$mdLines += ""
$mdLines += "| Relative Path | File Name | Size (KB) | Extension | Last Write Time | Attributes | Hex Signature | Inferred Type | Status (R.E. Check) | Analysis Notes |"
$mdLines += "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"

foreach ($row in $OutputTable) {
    $mdLines += "| $($row.RelativePath) | $($row.FileName) | $($row.SizeKB) | $($row.Extension) | $($row.LastWriteTime) | $($row.Attributes) | $($row.HexSignature) | $($row.InferredType) | $($row.StatusRECheck) | $($row.AnalysisNotes) |"
}

$mdLines | Out-File -FilePath $MarkdownOutput -Encoding UTF8

Write-Host "Done. Created:" -ForegroundColor Green
Write-Host " - $MarkdownOutput" -ForegroundColor Green
Write-Host " - $CsvOutput" -ForegroundColor Green
