param(
    [string]$Command
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"

$effective = $Command
if (-not $effective -and $env:DOSBOX_RESUME_CMD) {
    $effective = $env:DOSBOX_RESUME_CMD
}

if (-not $effective) {
    Write-Warning "No DOSBox resume command configured. Set DOSBOX_RESUME_CMD or pass -Command."
    & $logScript -Category "dosbox" -Message "Resume command skipped (not configured)"
    return
}

Write-Host "Resuming DOSBox via: $effective" -ForegroundColor Cyan
try {
    Invoke-Expression $effective
    & $logScript -Category "dosbox" -Message "Resume command executed"
}
catch {
    Write-Warning "Resume command failed: $_"
    & $logScript -Category "dosbox" -Message "Resume command failed"
}
