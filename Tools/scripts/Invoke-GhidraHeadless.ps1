param(
    [Parameter(Mandatory)][string]$ProjectDir,
    [Parameter(Mandatory)][string]$ProjectName,
    [Parameter(Mandatory)][string]$BinaryPath,
    [Parameter(Mandatory)][string]$GhidraHome,
    [string]$ScriptPath,
    [string]$PostScript,
    [string[]]$PostScriptArgs = @(),
    [string[]]$AdditionalOptions = @("-overwrite")
)

if (-not (Test-Path $BinaryPath)) {
    throw "Binary not found: $BinaryPath"
}

if (-not (Test-Path $ProjectDir)) {
    New-Item -ItemType Directory -Path $ProjectDir | Out-Null
}

if (-not (Test-Path $GhidraHome)) {
    throw "GHIDRA_HOME path does not exist: $GhidraHome"
}

$analyzeHeadless = $null
if ($IsWindows) {
    $analyzeHeadless = Join-Path $GhidraHome "support\analyzeHeadless.bat"
} else {
    $analyzeHeadless = Join-Path $GhidraHome "support/analyzeHeadless"
}

if (-not (Test-Path $analyzeHeadless)) {
    throw "Ghidra headless launcher not found: $analyzeHeadless"
}

$arguments = @(
    $ProjectDir,
    $ProjectName,
    "-import", $BinaryPath
)

if ($AdditionalOptions) {
    $arguments += $AdditionalOptions
}

if ($ScriptPath) {
    $arguments += @("-scriptPath", $ScriptPath)
}

if ($PostScript) {
    $arguments += @("-postScript", $PostScript)
    if ($PostScriptArgs) {
        $arguments += $PostScriptArgs
    }
}

Write-Host "Running analyzeHeadless:" -ForegroundColor Cyan
Write-Host "`"$analyzeHeadless`" $($arguments -join ' ')" -ForegroundColor DarkGray

$process = Start-Process -FilePath $analyzeHeadless -ArgumentList $arguments -Wait -NoNewWindow -PassThru

if ($process.ExitCode -ne 0) {
    throw "analyzeHeadless exited with code $($process.ExitCode)"
}
