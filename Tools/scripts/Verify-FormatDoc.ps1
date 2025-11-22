param(
    [string]$FormatsDir = "Docs\File_Formats"
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
$dir = Join-Path $repoRoot $FormatsDir
$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"

if (-not (Test-Path $dir)) {
    Write-Error "Formats directory not found: $dir"
    exit 1
}

$files = Get-ChildItem -Path $dir -Filter *.md -File
if (-not $files) {
    Write-Warning "No format docs found in $FormatsDir"
    exit 0
}

$results = @()
foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $missingSections = @()
    foreach ($section in @("#", "## Header Layout", "## Data Blocks", "## Notes & Open Questions")) {
        if ($content -notmatch [regex]::Escape($section)) {
            $missingSections += $section
        }
    }
    $hasTODO = $content -match "TODO"
    $results += [PSCustomObject]@{
        File = $file.Name
        MissingSections = if ($missingSections) { $missingSections -join ", " } else { "" }
        HasTODO = $hasTODO
    }
}

$results | Format-Table File,MissingSections,HasTODO -AutoSize

& $logScript -Category "formats" -Message "Verified format docs ($($results.Count) files)"
