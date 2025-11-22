param(
    [Parameter(Mandatory)][string]$DumpPath,
    [ValidateSet('incoming','working','archive')][string]$TargetStage = 'archive',
    [string]$RepoRoot,
    [string]$Notes,
    [string[]]$AddTags,
    [switch]$CopyOnly
)

$scriptRoot = Split-Path -Parent $PSCommandPath
if (-not $RepoRoot) {
    $RepoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
}

if (-not [System.IO.Path]::IsPathRooted($DumpPath)) {
    $DumpPath = Join-Path $RepoRoot $DumpPath
}

if (-not (Test-Path -LiteralPath $DumpPath)) {
    throw "Dump file '$DumpPath' not found."
}

$dumpFile = Get-Item -LiteralPath $DumpPath
$dumpsRoot = Join-Path $RepoRoot "Data\dumps"
$stageDirs = @{
    incoming = Join-Path $dumpsRoot "incoming"
    working  = Join-Path $dumpsRoot "working"
    archive  = Join-Path $dumpsRoot "archive"
}

foreach ($dir in $stageDirs.Values) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

$targetDir = $stageDirs[$TargetStage]
$targetPath = Join-Path $targetDir $dumpFile.Name
$metaSource = "$($dumpFile.FullName).meta.json"
$metaTarget = "$targetPath.meta.json"
$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"
$actionVerb = if ($CopyOnly) { 'copied' } else { 'moved' }

if (-not $CopyOnly -and ($dumpFile.FullName -eq $targetPath)) {
    Write-Host "Dump already in $TargetStage. Updating metadata only." -ForegroundColor Yellow
} else {
    if ($CopyOnly) {
        Copy-Item -LiteralPath $dumpFile.FullName -Destination $targetPath -Force
        if (Test-Path $metaSource) {
            Copy-Item -LiteralPath $metaSource -Destination $metaTarget -Force
        }
    } else {
        Move-Item -LiteralPath $dumpFile.FullName -Destination $targetPath -Force
        if (Test-Path $metaSource) {
            Move-Item -LiteralPath $metaSource -Destination $metaTarget -Force
        }
        $DumpPath = $targetPath
        $metaSource = $metaTarget
    }
}

Update-DumpMetadata -Path $metaTarget -FallbackDump $targetPath -RepoRoot $RepoRoot -Stage $TargetStage -Notes $Notes -AddTags $AddTags -Action $actionVerb

& $logScript -Category "dump" -Message "Dump $actionVerb to $TargetStage ($targetPath)"

function Update-DumpMetadata {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$FallbackDump,
        [Parameter(Mandatory)][string]$RepoRoot,
        [string]$Stage,
        [string]$Notes,
        [string[]]$AddTags,
        [string]$Action
    )

    $meta = $null
    if (Test-Path $Path) {
        try {
            $meta = Get-Content -Raw -Path $Path | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Warning "Failed to parse existing metadata. Recreating: $_"
            $meta = $null
        }
    }

    if (-not $meta) {
        if (-not $FallbackDump) {
            throw "Cannot create metadata without fallback dump path."
        }
        $dumpInfo = Get-Item -LiteralPath $FallbackDump
        $meta = [ordered]@{
            id = [guid]::NewGuid().Guid
            label = [System.IO.Path]::GetFileNameWithoutExtension($dumpInfo.Name)
            stage = $Stage
            filename = $dumpInfo.Name
            relative_path = [System.IO.Path]::GetRelativePath($RepoRoot, $dumpInfo.FullName)
            captured_at = $dumpInfo.CreationTime.ToString('o')
            source_command = $null
            dry_run = $false
            size_bytes = $dumpInfo.Length
            md5 = (Get-FileHash -Algorithm MD5 -Path $dumpInfo.FullName).Hash
            game_state = $null
            tags = @()
            notes = ""
            insights = @()
            history = @()
        }
    } else {
        $meta = $meta | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10
    }

    $meta.stage = $Stage
    if ($Notes) {
        if ([string]::IsNullOrWhiteSpace($meta.notes)) {
            $meta.notes = $Notes
        } else {
            $meta.notes = "$($meta.notes)`n$Notes"
        }
    }

    if (-not $meta.tags) { $meta.tags = @() }
    if ($AddTags) {
        $meta.tags = @($meta.tags + $AddTags | Select-Object -Unique)
    }

    $meta.history = @($meta.history + @([ordered]@{
            event = $Action
            stage = $Stage
            occurred_at = (Get-Date).ToString('o')
        }))

    $meta | ConvertTo-Json -Depth 6 | Out-File -FilePath $Path -Encoding UTF8
}
