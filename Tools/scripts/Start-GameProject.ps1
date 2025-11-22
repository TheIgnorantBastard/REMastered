param(
    [string]$ConfigPath = "game.json"
)

$scriptRoot = Split-Path -Parent $PSCommandPath
Set-Location $scriptRoot

$readCfgScript = Join-Path $scriptRoot "Read-GameConfig.ps1"
$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"
$cfg = & $readCfgScript -ConfigPath $ConfigPath
& $logScript -Category "bootstrap" -Message "Start-GameProject invoked (config=$ConfigPath)"

# Resolve important paths
$originalRoot = Resolve-Path $cfg.original.root -ErrorAction Stop
$entryExePath = Join-Path $originalRoot $cfg.original.entry_exe

if (-not (Test-Path $entryExePath)) {
    throw "Entry EXE not found at '$entryExePath'"
}

# Ensure standard directories
$dirs = @(
    ".\Docs",
    ".\Docs\File_Formats",
    ".\Docs\Runtime_Structs",
    ".\Docs\Sessions",
    ".\Docs\Templates",
    ".\Data",
    $cfg.data.indexes_dir,
    $cfg.data.dumps_dir,
    ".\Tools\configs",
    ".\Ghidra\projects",
    ".\Ghidra\scripts"
)

foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d | Out-Null
    }
}

# Bootstrap Master_File_Document.md from template if missing
$masterDocPath = $cfg.docs.master_file_doc
$templatePath  = ".\Docs\Templates\Master_File_Document.template.md"

if (-not (Test-Path $masterDocPath) -and (Test-Path $templatePath)) {
    $content = Get-Content $templatePath -Raw
    $content = $content.Replace("{{GAME_NAME}}", $cfg.name)
    $content = $content.Replace("{{ORIGINAL_ROOT}}", $originalRoot)
    $content | Out-File -FilePath $masterDocPath -Encoding UTF8
}

# Bootstrap planning templates (task types, onboarding tasks, difficulties log)
$difficultiesLogPath = ".\Docs\Difficulties_Log.md"
if (-not (Test-Path $difficultiesLogPath)) {
    "# Difficulties Log`n`nShort notes about issues encountered by the /replan agent and ideas to improve future runs.`n" |
        Out-File -FilePath $difficultiesLogPath -Encoding UTF8
}

$indexesDir = $cfg.data.indexes_dir
$taskTypesTemplate = ".\Tools\configs\task_types.template.json"
$onboardingTasksTemplate = ".\Tools\configs\onboarding_tasks.template.json"

if (-not (Test-Path (Join-Path $indexesDir "task_types.json")) -and (Test-Path $taskTypesTemplate)) {
    Copy-Item -Path $taskTypesTemplate -Destination (Join-Path $indexesDir "task_types.json") -Force
}

if (-not (Test-Path (Join-Path $indexesDir "onboarding_tasks.json")) -and (Test-Path $onboardingTasksTemplate)) {
    Copy-Item -Path $onboardingTasksTemplate -Destination (Join-Path $indexesDir "onboarding_tasks.json") -Force
}

# Run file indexer
$fileCsv    = Join-Path $indexesDir "files.csv"
$fileIndexMd = $cfg.docs.file_index_md

& ".\Tools\scripts\Generate_File_Index.ps1" `
    -RootPath $originalRoot `
    -MarkdownOutput $fileIndexMd `
    -CsvOutput $fileCsv

Write-Host "Start-GameProject completed." -ForegroundColor Green
& $logScript -Category "bootstrap" -Message "Start-GameProject completed (root=$originalRoot)"
