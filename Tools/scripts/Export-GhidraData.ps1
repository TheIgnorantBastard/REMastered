param(
    [string]$Binary = "RUN.EXE",
    [string]$Filter = "",
    [string]$ConfigPath = "game.json"
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"
& $logScript -Category "ghidra" -Message "Export stub invoked (binary=$Binary, filter=$Filter)"

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

$placeholder = [ordered]@{
    binary   = $Binary
    filter   = $Filter
    generated_at = $timestamp
    status   = if ($ghidraProjDir) { "pending-export" } else { "ghidra-project-missing" }
    notes    = "Replace the body of Export-GhidraData.ps1 with actual headless export logic."
    results  = @()
}

$placeholder | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputFile -Encoding UTF8

Write-Host "Wrote placeholder export to $outputFile" -ForegroundColor Green
& $logScript -Category "ghidra" -Message "Placeholder export written to $outputFile"
