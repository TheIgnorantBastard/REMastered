param(
    [string]$ConfigPath = "game.json"
)

$here = Split-Path -Parent $PSCommandPath
Set-Location $here

$cfg = & ".\Tools\scripts\Read-GameConfig.ps1" -ConfigPath $ConfigPath

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

# Run file indexer
$indexesDir = $cfg.data.indexes_dir
$fileCsv    = Join-Path $indexesDir "files.csv"
$fileIndexMd = $cfg.docs.file_index_md

& ".\Tools\scripts\Generate_File_Index.ps1" `
    -RootPath $originalRoot `
    -MarkdownOutput $fileIndexMd `
    -CsvOutput $fileCsv

Write-Host "Start-GameProject completed." -ForegroundColor Green
