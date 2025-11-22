param(
    [string]$Command
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"

$effective = $Command
if (-not $effective -and $env:DOSBOX_PAUSE_CMD) {
    $effective = $env:DOSBOX_PAUSE_CMD
}

if (-not $effective) {
    Write-Warning "No DOSBox pause command configured. Set DOSBOX_PAUSE_CMD or pass -Command."
    & $logScript -Category "dosbox" -Message "Pause command skipped (not configured)"
    return
}

Write-Host "Pausing DOSBox via: $effective" -ForegroundColor Cyan
try {
    Invoke-Expression $effective
    & $logScript -Category "dosbox" -Message "Pause command executed"
}
catch {
    Write-Warning "Pause command failed: $_"
    & $logScript -Category "dosbox" -Message "Pause command failed"
}
