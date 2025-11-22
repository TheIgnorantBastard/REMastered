param(
    [Parameter(Mandatory)][string]$FormatName,
    [string]$Status = "Unknown",
    [string[]]$RelatedFiles = @(),
    [string]$Summary = "TBD"
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
$templatePath = Join-Path $repoRoot "Docs\Templates\FileFormat.template.md"
$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"

if (-not (Test-Path $templatePath)) {
    Write-Error "Template not found at $templatePath"
    exit 1
}

$targetDir = Join-Path $repoRoot "Docs\File_Formats"
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir | Out-Null
}

$slug = ($FormatName -replace "[^A-Za-z0-9_-]", "_")
$targetPath = Join-Path $targetDir ("$slug.md")

if (Test-Path $targetPath) {
    Write-Host "Format doc already exists: $targetPath" -ForegroundColor Yellow
} else {
    $template = Get-Content $templatePath -Raw
    $content = $template.Replace("{{FORMAT_NAME}}", $FormatName)
    $content = $content.Replace("{{STATUS}}", $Status)
    $content = $content.Replace("{{RELATED_FILES}}", ($RelatedFiles -join ", "))
    $content = $content.Replace("{{SUMMARY}}", $Summary)
    $content | Out-File -FilePath $targetPath -Encoding UTF8
    Write-Host "Created format doc at $targetPath" -ForegroundColor Green
}

& $logScript -Category "formats" -Message "Format doc ensured for $FormatName ($targetPath)"
