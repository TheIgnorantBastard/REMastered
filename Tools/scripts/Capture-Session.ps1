param(
    [Parameter(Mandatory)][string]$Action,
    [string[]]$Dumps = @(),
    [string]$SessionFile,
    [string]$RepoRoot
)

$scriptRoot = Split-Path -Parent $PSCommandPath
if (-not $RepoRoot) {
    $RepoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
}

$sessionsDir = Join-Path $RepoRoot "Docs\Sessions"
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
        $dumpInfo = Get-Item -LiteralPath $dump
        $line = "- $($dumpInfo.Name) ($($dumpInfo.Length) bytes, $($dumpInfo.CreationTime))"

        $metaPath = "$dump.meta.json"
        if (Test-Path $metaPath) {
            try {
                $meta = Get-Content -Raw -Path $metaPath | ConvertFrom-Json
                $stageInfo = if ($meta.stage) { $meta.stage } else { "unknown" }
                $tagInfo = if ($meta.tags -and $meta.tags.Count -gt 0) { $meta.tags -join ', ' } else { $null }
                $noteInfo = if ($meta.notes) { $meta.notes } else { $null }
                $line += " | stage: $stageInfo"
                if ($tagInfo) { $line += " | tags: $tagInfo" }
                if ($noteInfo) { $line += " | notes: $noteInfo" }
            }
            catch {
                Write-Warning "Failed to parse metadata for $($dump): $_"
            }
        }

        $entry += $line
    }
} else {
    $entry += "**Dumps:** _none recorded_"
}

$entry += ""
Add-Content -Path $SessionFile -Value ($entry -join [Environment]::NewLine)
Write-Host "Logged session entry to $SessionFile" -ForegroundColor Green

$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"
& $logScript -Category "session" -Message "Logged action '$Action' (dumps=$($Dumps -join ', '))"
