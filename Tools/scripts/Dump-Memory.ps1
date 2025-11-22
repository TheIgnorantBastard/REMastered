param(
    [string]$Label = "dump",
    [string]$Command,
    [switch]$DryRun,
    [ValidateSet('incoming','working','archive')][string]$Stage = 'incoming',
    [string]$GameState,
    [string[]]$Tags,
    [string]$Notes
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
$dumpsDir = Join-Path $repoRoot "Data\dumps"
$incomingDir = Join-Path $dumpsDir "incoming"
$workingDir = Join-Path $dumpsDir "working"
$archiveDir = Join-Path $dumpsDir "archive"
$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"
foreach ($dir in @($dumpsDir, $incomingDir, $workingDir, $archiveDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

switch ($Stage) {
    'incoming' { $targetDir = $incomingDir }
    'working' { $targetDir = $workingDir }
    'archive' { $targetDir = $archiveDir }
    default   { $targetDir = $incomingDir }
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$sanitizedLabel = ($Label -replace "[^A-Za-z0-9_-]", "_")
$dumpFileName = "${timestamp}_${sanitizedLabel}.bin"
$dumpPath = Join-Path $targetDir $dumpFileName

if ($DryRun -or -not $Command) {
    "Placeholder dump generated on $timestamp" | Out-File -FilePath $dumpPath -Encoding ASCII
    Write-Host "Created placeholder dump $dumpPath" -ForegroundColor Yellow
    if (-not $Command) {
        Write-Host "No command specified; run with -Command to capture real data." -ForegroundColor Cyan
    }
    Write-Host "Writing metadata sidecar" -ForegroundColor Gray
    Write-DumpMetadata -DumpPath $dumpPath -Label $Label -Stage $Stage -Command $Command -DryRun:$DryRun -GameState $GameState -Tags $Tags -Notes $Notes
    & $logScript -Category "dump" -Message "Placeholder dump created ($dumpPath) [stage=$Stage]"
    return
}

Write-Host "Executing capture command:" -ForegroundColor Cyan
Write-Host $Command -ForegroundColor Gray

Invoke-Expression $Command

if (-not (Test-Path $dumpPath)) {
    New-Item -ItemType File -Path $dumpPath | Out-Null
}

Write-Host "Dump stored at $dumpPath" -ForegroundColor Green
Write-Host "Writing metadata sidecar" -ForegroundColor Gray
Write-DumpMetadata -DumpPath $dumpPath -Label $Label -Stage $Stage -Command $Command -DryRun:$DryRun -GameState $GameState -Tags $Tags -Notes $Notes
& $logScript -Category "dump" -Message "Capture command completed ($dumpPath) [stage=$Stage]"

function Write-DumpMetadata {
    param(
        [Parameter(Mandatory)][string]$DumpPath,
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string]$Stage,
        [string]$Command,
        [switch]$DryRun,
        [string]$GameState,
        [string[]]$Tags,
        [string]$Notes
    )

    $repoRoot = Resolve-Path (Join-Path (Split-Path -Parent $PSCommandPath) "..\..")
    $metaPath = "$DumpPath.meta.json"
    $now = Get-Date
    $relativePath = try {
        [System.IO.Path]::GetRelativePath($repoRoot, $DumpPath)
    } catch {
        $DumpPath
    }

    $fileInfo = Get-Item $DumpPath
    $hash = Get-FileHash -Algorithm MD5 -Path $DumpPath

    $meta = [ordered]@{
        id = [guid]::NewGuid().Guid
        label = $Label
        stage = $Stage
        filename = $fileInfo.Name
        relative_path = $relativePath
        captured_at = $now.ToString('o')
        source_command = $Command
        dry_run = [bool]$DryRun
        size_bytes = $fileInfo.Length
        md5 = $hash.Hash
        game_state = $GameState
        tags = $Tags
        notes = $Notes
        insights = @()
        history = @(
            [ordered]@{
                event = 'captured'
                stage = $Stage
                occurred_at = $now.ToString('o')
            }
        )
    }

    if (-not $Tags) { $meta.tags = @() }
    if (-not $Notes) { $meta.notes = "" }

    $meta | ConvertTo-Json -Depth 6 | Out-File -FilePath $metaPath -Encoding UTF8
}
