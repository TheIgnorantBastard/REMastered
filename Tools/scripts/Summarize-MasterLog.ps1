param(
    [string]$LogPath = "Docs\Master_Log.md",
    [switch]$ByCategory,
    [switch]$ByDate
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
$fullLogPath = Join-Path $repoRoot $LogPath

if (-not (Test-Path $fullLogPath)) {
    Write-Error "Master log not found: $fullLogPath"
    exit 1
}

$entries = Get-Content $fullLogPath | Where-Object { $_ -match "^-" }

$parsed = $entries | ForEach-Object {
    if ($_ -match "^- \[(?<ts>[^\]]+)\] \[(?<cat>[^\]]+)\] (?<msg>.+)$") {
        [PSCustomObject]@{
            Timestamp = [datetime]::ParseExact($matches.ts, 'yyyy-MM-dd HH:mm:ss', $null)
            Category  = $matches.cat
            Message   = $matches.msg
        }
    }
}

if ($ByCategory) {
    $parsed | Group-Object Category | ForEach-Object {
        Write-Host "`n## $($_.Name) ($($_.Count))" -ForegroundColor Cyan
        $_.Group | Sort-Object Timestamp | Format-Table Timestamp,Message -AutoSize
    }
} elseif ($ByDate) {
    $parsed | Group-Object { $_.Timestamp.ToString('yyyy-MM-dd') } | ForEach-Object {
        Write-Host "`n## $($_.Name) ($($_.Count))" -ForegroundColor Cyan
        $_.Group | Sort-Object Timestamp | Format-Table Timestamp,Category,Message -AutoSize
    }
} else {
    $parsed | Sort-Object Timestamp | Format-Table Timestamp,Category,Message -AutoSize
}
