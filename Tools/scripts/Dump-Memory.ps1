param(
    [string]$Label = "dump",
    [string]$Command,
    [switch]$DryRun
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
$dumpsDir = Join-Path $repoRoot "Data\dumps"
$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"
if (-not (Test-Path $dumpsDir)) {
    New-Item -ItemType Directory -Path $dumpsDir | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$sanitizedLabel = ($Label -replace "[^A-Za-z0-9_-]", "_")
$dumpPath = Join-Path $dumpsDir ("${timestamp}_${sanitizedLabel}.bin")

if ($DryRun -or -not $Command) {
    "Placeholder dump generated on $timestamp" | Out-File -FilePath $dumpPath -Encoding ASCII
    Write-Host "Created placeholder dump $dumpPath" -ForegroundColor Yellow
    if (-not $Command) {
        Write-Host "No command specified; run with -Command to capture real data." -ForegroundColor Cyan
    }
    & $logScript -Category "dump" -Message "Placeholder dump created ($dumpPath)"
    return
}

Write-Host "Executing capture command:" -ForegroundColor Cyan
Write-Host $Command -ForegroundColor Gray

Invoke-Expression $Command

if (-not (Test-Path $dumpPath)) {
    New-Item -ItemType File -Path $dumpPath | Out-Null
}

Write-Host "Dump stored at $dumpPath" -ForegroundColor Green
& $logScript -Category "dump" -Message "Capture command completed ($dumpPath)"
