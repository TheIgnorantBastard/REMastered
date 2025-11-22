param(
    [switch]$AutoDump,
    [string]$DumpLabel = "hotkey",
    [string]$PauseCommand,
    [string]$ResumeCommand,
    [string]$ConfigPath = "game.json"
)

function Invoke-HostCommand {
    param([string]$Command)
    if ([string]::IsNullOrWhiteSpace($Command)) { return }
    try {
        Write-Host "Running host command: $Command" -ForegroundColor DarkCyan
        Invoke-Expression $Command
    }
    catch {
        Write-Warning "Failed to run host command: $_"
    }
}

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
$dumpsRoot = Join-Path $repoRoot "Data\dumps"
$captureScript = Join-Path $scriptRoot "Capture-Session.ps1"
$dumpScript    = Join-Path $scriptRoot "Dump-Memory.ps1"
$pauseScript   = Join-Path $scriptRoot "Pause-DosboxSession.ps1"
$resumeScript  = Join-Path $scriptRoot "Resume-DosboxSession.ps1"
$logScript     = Join-Path $scriptRoot "Write-MasterLog.ps1"

& $logScript -Category "session-hotkey" -Message "Session prompt invoked"

if (Test-Path $pauseScript) {
    & $pauseScript -Command $PauseCommand
} else {
    Invoke-HostCommand -Command $PauseCommand
}

$actionText = $null
$dumpText   = $null

try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "REMastered Session Log"
    $form.Width = 500
    $form.Height = 320
    $form.StartPosition = 'CenterScreen'

    $labelAction = New-Object System.Windows.Forms.Label
    $labelAction.Text = "Describe the action you just performed:"
    $labelAction.AutoSize = $true
    $labelAction.Top = 10
    $labelAction.Left = 10

    $textAction = New-Object System.Windows.Forms.TextBox
    $textAction.Multiline = $true
    $textAction.Width = 460
    $textAction.Height = 100
    $textAction.Left = 10
    $textAction.Top = 35

    $labelDump = New-Object System.Windows.Forms.Label
    $labelDump.Text = "Optional dump file paths (one per line):"
    $labelDump.AutoSize = $true
    $labelDump.Top = 145
    $labelDump.Left = 10

    $textDump = New-Object System.Windows.Forms.TextBox
    $textDump.Multiline = $true
    $textDump.Width = 460
    $textDump.Height = 80
    $textDump.Left = 10
    $textDump.Top = 170

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "Save"
    $okButton.Width = 80
    $okButton.Height = 30
    $okButton.Left = 280
    $okButton.Top = 260
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Width = 80
    $cancelButton.Height = 30
    $cancelButton.Left = 370
    $cancelButton.Top = 260
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $form.Controls.AddRange(@($labelAction,$textAction,$labelDump,$textDump,$okButton,$cancelButton))
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton

    $dialogResult = $form.ShowDialog()
    if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
        $actionText = $textAction.Text.Trim()
        $dumpText = $textDump.Text.Trim()
    }
}
catch {
    Write-Warning "Falling back to console prompt: $_"
    $actionText = Read-Host "Describe the action you just performed"
    $dumpText = Read-Host "Optional dump files (comma-separated)"
}

if ([string]::IsNullOrWhiteSpace($actionText)) {
    Write-Host "No action provided. Aborting log entry." -ForegroundColor Yellow
    & $logScript -Category "session-hotkey" -Message "Prompt dismissed with no action"
    if (Test-Path $resumeScript) {
        & $resumeScript -Command $ResumeCommand
    } else {
        Invoke-HostCommand -Command $ResumeCommand
    }
    exit 0
}

$dumpList = @()
if ($dumpText) {
    $dumpList = $dumpText -split "[\r\n,;]" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() }
}

if ($AutoDump) {
    & $dumpScript -Label $DumpLabel -DryRun -Stage 'incoming'
    $labelFragment = ($DumpLabel -replace '[^A-Za-z0-9_-]','_')
    if (Test-Path $dumpsRoot) {
        $recentDump = Get-ChildItem -Path $dumpsRoot -Filter "*_${labelFragment}.bin" -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($recentDump) {
            $dumpList += $recentDump.FullName
        }
    }
}

& $captureScript -Action $actionText -Dumps $dumpList -RepoRoot $repoRoot
& $logScript -Category "session-hotkey" -Message "Action logged via prompt (autoDump=$AutoDump)"

if (Test-Path $resumeScript) {
    & $resumeScript -Command $ResumeCommand
} else {
    Invoke-HostCommand -Command $ResumeCommand
}
