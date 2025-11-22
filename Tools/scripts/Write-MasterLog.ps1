param(
    [Parameter(Mandatory)][string]$Message,
    [string]$Category = "general"
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
$logPath = Join-Path $repoRoot "Docs\Master_Log.md"

if (-not (Test-Path $logPath)) {
    "# REMastered Master Log`n" | Out-File -FilePath $logPath -Encoding UTF8
}

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$entry = "- [$timestamp] [$Category] $Message"
Add-Content -Path $logPath -Value $entry
