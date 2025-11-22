param(
    [Parameter(Mandatory)][string]$Action,
    [string[]]$Dumps = @(),
    [string]$SessionFile
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
$sessionsDir = Join-Path $repoRoot "Docs\Sessions"
if (-not (Test-Path $sessionsDir)) {
    New-Item -ItemType Directory -Path $sessionsDir | Out-Null
}

if (-not $SessionFile) {
    $SessionFile = Join-Path $sessionsDir ("session-" + (Get-Date -Format 'yyyy-MM-dd') + ".md")
} elseif (-not [System.IO.Path]::IsPathRooted($SessionFile)) {
    $SessionFile = Join-Path $sessionsDir $SessionFile
}

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

$entry = @()
$entry += "## $timestamp"
$entry += ""
$entry += "**Action:** $Action"
if ($Dumps -and $Dumps.Count -gt 0) {
    $entry += "**Dumps:**"
    foreach ($dump in $Dumps) {
        $entry += "- $dump"
    }
} else {
    $entry += "**Dumps:** _none recorded_
"
}
$entry += ""

Add-Content -Path $SessionFile -Value ($entry -join [Environment]::NewLine)
Write-Host "Logged session entry to $SessionFile" -ForegroundColor Green

$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"
& $logScript -Category "session" -Message "Logged action '$Action' (dumps=$($Dumps -join ', '))"
