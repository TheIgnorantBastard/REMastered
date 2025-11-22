param(
    [ValidateSet('all','incoming','working','archive')][string]$Stage = 'all',
    [string[]]$Tags,
    [string]$OutputPath,
    [switch]$IncludeHistory
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
$dumpsRoot = Join-Path $repoRoot "Data\dumps"
$defaultOutput = Join-Path $repoRoot "Docs\Dump_Summary.md"
if (-not $OutputPath) { $OutputPath = $defaultOutput }
$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"

if (-not (Test-Path $dumpsRoot)) {
    Write-Warning "No Data/dumps directory found. Run Dump-Memory.ps1 first."
    return
}

$metaFiles = Get-ChildItem -Path $dumpsRoot -Filter '*.meta.json' -File -Recurse -ErrorAction SilentlyContinue
if (-not $metaFiles) {
    Write-Warning "No dump metadata files were found under $dumpsRoot."
    return
}

$records = @()
foreach ($file in $metaFiles) {
    try {
        $meta = Get-Content -Raw -Path $file.FullName | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Warning "Skipping malformed metadata: $($file.FullName) ($_ )"
        continue
    }

    if ($Stage -ne 'all' -and $meta.stage -ne $Stage) { continue }
    if ($Tags -and -not ($Tags | Where-Object { $meta.tags -contains $_ })) { continue }

    $capturedAt = $null
    [void][DateTime]::TryParse($meta.captured_at, [ref]$capturedAt)
    $sizeBytes = $meta.size_bytes
    if (-not $sizeBytes -and (Test-Path (Join-Path $file.DirectoryName $meta.filename))) {
        $sizeBytes = (Get-Item (Join-Path $file.DirectoryName $meta.filename)).Length
    }

    $records += [pscustomobject]@{
        Stage       = $meta.stage
        Label       = $meta.label
        CapturedAt  = if ($capturedAt) { $capturedAt } else { $null }
        SizeBytes   = $sizeBytes
        Tags        = $meta.tags
        Notes       = $meta.notes
        Relative    = $meta.relative_path
        History     = $meta.history
    }
}

if (-not $records) {
    Write-Warning "No dumps matched the provided filters."
    return
}

$stageOrder = @('incoming','working','archive')
$records = $records | Sort-Object {
    $stageIndex = $stageOrder.IndexOf($_.Stage)
    if ($stageIndex -lt 0) { $stageIndex = 99 }
    [Tuple]::Create($stageIndex, $_.CapturedAt)
}

$summary = $records | Group-Object Stage | ForEach-Object {
    [pscustomobject]@{
        Stage = $_.Name
        Count = $_.Count
        SizeMB = [math]::Round(($_.Group | Measure-Object -Property SizeBytes -Sum).Sum / 1MB, 2)
    }
}

$sb = [System.Text.StringBuilder]::new()
$null = $sb.AppendLine("# Dump Summary")
$null = $sb.AppendLine("")
$null = $sb.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')")
$null = $sb.AppendLine("Stage filter: $Stage")
if ($Tags) { $null = $sb.AppendLine("Tag filter: $($Tags -join ', ')") }
$null = $sb.AppendLine("")
$null = $sb.AppendLine("## Stage totals")
$null = $sb.AppendLine("| Stage | Count | Size (MB) |")
$null = $sb.AppendLine("| --- | ---: | ---: |")
foreach ($row in $summary) {
    $null = $sb.AppendLine("| $($row.Stage) | $($row.Count) | $($row.SizeMB) |")
}

$null = $sb.AppendLine("")
$null = $sb.AppendLine("## Details")
$null = $sb.AppendLine("| Stage | Label | Captured | Size (KB) | Tags | Notes |")
$null = $sb.AppendLine("| --- | --- | --- | ---: | --- | --- |")
foreach ($rec in $records) {
    $capturedStr = if ($rec.CapturedAt) { $rec.CapturedAt.ToString('yyyy-MM-dd HH:mm') } else { '' }
    $sizeKb = if ($rec.SizeBytes) { [math]::Round($rec.SizeBytes / 1KB, 1) } else { '' }
    $tagStr = if ($rec.Tags) { $rec.Tags -join ', ' } else { '' }
    $notesStr = if ($rec.Notes) { $rec.Notes -replace "\|", "&#124;" } else { '' }
    $null = $sb.AppendLine("| $($rec.Stage) | $($rec.Label) | $capturedStr | $sizeKb | $tagStr | $notesStr |")
}

if ($IncludeHistory) {
    $null = $sb.AppendLine("")
    $null = $sb.AppendLine("## History snippets")
    foreach ($rec in $records) {
        if (-not $rec.History) { continue }
        $null = $sb.AppendLine("### $($rec.Label) ($($rec.Stage))")
        foreach ($event in $rec.History) {
            $null = $sb.AppendLine("- [$($event.occurred_at)] $($event.event) -> $($event.stage)")
        }
        $null = $sb.AppendLine("")
    }
}

$summaryDir = Split-Path -Parent $OutputPath
if (-not (Test-Path $summaryDir)) {
    New-Item -ItemType Directory -Path $summaryDir | Out-Null
}
$sb.ToString() | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "Dump summary written to $OutputPath" -ForegroundColor Green
& $logScript -Category "dump-summary" -Message "Summarized $($records.Count) dumps (stage=$Stage, tags=$($Tags -join ';'))"

return $records
