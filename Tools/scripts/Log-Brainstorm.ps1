param(
    [Parameter(Mandatory)][string]$Idea,
    [string]$IdeasFile = "Docs\Ideas.md"
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
$ideasPath = Join-Path $repoRoot $IdeasFile
$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"

if (-not (Test-Path $ideasPath)) {
    "# Automation & Feature Ideas`n" | Out-File -FilePath $ideasPath -Encoding UTF8
}

$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$entry = "- [$timestamp] $Idea"
Add-Content -Path $ideasPath -Value $entry

& $logScript -Category "ideas" -Message "Brainstorm logged: $Idea"
