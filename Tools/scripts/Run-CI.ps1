param(
    [switch]$SkipLint,
    [switch]$SkipFormats,
    [switch]$SkipSummary
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"

$errors = @()

if (-not $SkipLint) {
    Write-Host "Running PSScriptAnalyzer..." -ForegroundColor Cyan
    if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
        try {
            Invoke-ScriptAnalyzer -Path (Join-Path $repoRoot "Tools\scripts") -Recurse -EnableExit
        }
        catch {
            Write-Warning "PSScriptAnalyzer reported issues: $_"
            $errors += "PSScriptAnalyzer"
        }
    } else {
        Write-Warning "PSScriptAnalyzer not available. Install PSScriptAnalyzer or rerun with -SkipLint."
    }
}

if (-not $SkipFormats) {
    Write-Host "Verifying format docs..." -ForegroundColor Cyan
    $verifyScript = Join-Path $scriptRoot "Verify-FormatDoc.ps1"
    if (Test-Path $verifyScript) {
        try {
            & $verifyScript
        }
        catch {
            Write-Warning "Verify-FormatDoc.ps1 failed: $_"
            $errors += "Verify-FormatDoc"
        }
    }
}

if (-not $SkipSummary) {
    Write-Host "Master log summary (last 10 entries)..." -ForegroundColor Cyan
    $summaryScript = Join-Path $scriptRoot "Summarize-MasterLog.ps1"
    if (Test-Path $summaryScript) {
        try {
            & $summaryScript | Select-Object -Last 10
        }
        catch {
            Write-Warning "Summarize-MasterLog.ps1 failed: $_"
            $errors += "Summarize-MasterLog"
        }
    }
}

if ($errors.Count -eq 0) {
    Write-Host "Run-CI completed successfully." -ForegroundColor Green
    & $logScript -Category "ci" -Message "Run-CI completed"
} else {
    Write-Warning "Run-CI completed with issues: $($errors -join ', ')"
    & $logScript -Category "ci" -Message "Run-CI completed with issues ($($errors -join ', '))"
}
