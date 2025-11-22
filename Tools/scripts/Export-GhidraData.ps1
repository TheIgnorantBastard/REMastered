param(
    [string]$Binary = "RUN.EXE",
    [string]$Filter = "",
    [string]$ConfigPath = "game.json"
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"
& $logScript -Category "ghidra" -Message "Export invoked (binary=$Binary, filter=$Filter)"

try {
    $cfg = & (Join-Path $scriptRoot "Read-GameConfig.ps1") -ConfigPath $ConfigPath
} catch {
    Write-Host "Unable to load game config ($ConfigPath): $_" -ForegroundColor Red
    exit 1
}

$ghidraProjDir = Resolve-Path (Join-Path $repoRoot $cfg.tools.ghidra_project_dir) -ErrorAction SilentlyContinue
if (-not $ghidraProjDir) {
    Write-Host "Ghidra project directory not found. Expected at $($cfg.tools.ghidra_project_dir)." -ForegroundColor Yellow
    Write-Host "This is a stub runner; populate a project and update the script when ready." -ForegroundColor Yellow
}

$indexesDir = Join-Path $repoRoot "Data\indexes\ghidra"
if (-not (Test-Path $indexesDir)) {
    New-Item -ItemType Directory -Path $indexesDir | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outputFile = Join-Path $indexesDir ("${Binary.Replace('.', '_')}-${timestamp}.json")

$ghidraHome = $env:GHIDRA_HOME
$invokeHeadless = Join-Path $scriptRoot "Invoke-GhidraHeadless.ps1"
$scriptPath = Join-Path $repoRoot "Ghidra\scripts"
$projectDir = Join-Path $repoRoot $cfg.tools.ghidra_project_dir
$projectName = [System.IO.Path]::GetFileName($projectDir)

if ($ghidraHome -and (Test-Path $invokeHeadless)) {
    try {
        & $invokeHeadless `
            -ProjectDir $projectDir `
            -ProjectName $projectName `
            -BinaryPath $BinaryPath `
            -GhidraHome $ghidraHome `
            -ScriptPath $scriptPath `
            -PostScript $PostScript `
            -PostScriptArgs $PostScriptArgs | Out-Null

        & $logScript -Category "ghidra" -Message "Headless export completed via Ghidra"
    }
    catch {
        Write-Warning "Ghidra headless export failed: $_"
        & $logScript -Category "ghidra" -Message "Headless export failed; writing placeholder ($outputFile)"
        $ghidraHome = $null
    }
}

if (-not $ghidraHome) {
    $placeholder = [ordered]@{
        binary   = $Binary
        filter   = $Filter
        generated_at = $timestamp
        status   = if ($ghidraProjDir) { "pending-export" } else { "ghidra-project-missing" }
        notes    = "Set GHIDRA_HOME and add a post-script to generate real data."
        results  = @()
    }

    $placeholder | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Host "Wrote placeholder export to $outputFile" -ForegroundColor Yellow
    & $logScript -Category "ghidra" -Message "Placeholder export written to $outputFile"
}
Write-Host "Export artifacts stored under Data/indexes/ghidra/" -ForegroundColor Green
