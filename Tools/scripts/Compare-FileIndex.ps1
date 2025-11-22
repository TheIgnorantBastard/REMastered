param(
    [string]$Current = "Data\indexes\files.csv",
    [string]$Previous
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"

$currPath = Join-Path $repoRoot $Current
if (-not (Test-Path $currPath)) {
    Write-Error "Current index not found: $currPath"
    exit 1
}

if (-not $Previous) {
    $gitCmd = "git -C `"$repoRoot`" show HEAD~1:$Current"
    try {
        $prevContent = Invoke-Expression $gitCmd
    } catch {
        Write-Error "Unable to retrieve previous index. Provide -Previous or ensure git history exists."
        exit 1
    }
    $tempFile = [System.IO.Path]::GetTempFileName()
    $prevContent | Out-File -FilePath $tempFile -Encoding UTF8
    $prevPath = $tempFile
} else {
    $prevPath = Join-Path $repoRoot $Previous
    if (-not (Test-Path $prevPath)) {
        Write-Error "Previous index not found: $prevPath"
        exit 1
    }
}

$currRows = Import-Csv -Path $currPath
$prevRows = Import-Csv -Path $prevPath

$currSet = $currRows | Group-Object -Property RelativePath -AsHashTable -AsString
$prevSet = $prevRows | Group-Object -Property RelativePath -AsHashTable -AsString

$added = @()
$removed = @()
$changed = @()

foreach ($path in $currSet.Keys) {
    if (-not $prevSet.ContainsKey($path)) {
        $added += $currSet[$path]
    } elseif ($currSet[$path].HexSignature -ne $prevSet[$path].HexSignature -or $currSet[$path].SizeKB -ne $prevSet[$path].SizeKB) {
        $changed += [PSCustomObject]@{
            RelativePath = $path
            PreviousSize = $prevSet[$path].SizeKB
            CurrentSize = $currSet[$path].SizeKB
            PreviousSig = $prevSet[$path].HexSignature
            CurrentSig = $currSet[$path].HexSignature
        }
    }
}

foreach ($path in $prevSet.Keys) {
    if (-not $currSet.ContainsKey($path)) {
        $removed += $prevSet[$path]
    }
}

Write-Host "Added: $($added.Count)
Removed: $($removed.Count)
Changed: $($changed.Count)" -ForegroundColor Cyan

if ($added) {
    Write-Host "\n### Added" -ForegroundColor Green
    $added | Format-Table RelativePath,SizeKB,HexSignature -AutoSize
}
if ($removed) {
    Write-Host "\n### Removed" -ForegroundColor Red
    $removed | Format-Table RelativePath,SizeKB,HexSignature -AutoSize
}
if ($changed) {
    Write-Host "\n### Changed" -ForegroundColor Yellow
    $changed | Format-Table RelativePath,PreviousSize,CurrentSize,PreviousSig,CurrentSig -AutoSize
}

if ($tempFile) { Remove-Item $tempFile -ErrorAction SilentlyContinue }
& $logScript -Category "index" -Message "Compared file index (added=$($added.Count), removed=$($removed.Count), changed=$($changed.Count))"
