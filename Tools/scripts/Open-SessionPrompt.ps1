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
$captureScript = Join-Path $scriptRoot "Capture-Session.ps1"
$dumpScript    = Join-Path $scriptRoot "Dump-Memory.ps1"
$logScript     = Join-Path $scriptRoot "Write-MasterLog.ps1"

& $logScript -Category "session-hotkey" -Message "Session prompt invoked"

Invoke-HostCommand -Command $PauseCommand

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
    Invoke-HostCommand -Command $ResumeCommand
    exit 0
}

$dumpList = @()
if ($dumpText) {
    $dumpList = $dumpText -split "[\r\n,;]" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() }
}

if ($AutoDump) {
    & $dumpScript -Label $DumpLabel -DryRun
    $recentDump = Get-ChildItem (Join-Path (Split-Path -Parent $dumpScript) "..\..\Data\dumps") -Filter "*_$(($DumpLabel -replace '[^A-Za-z0-9_-]','_')).bin" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($recentDump) {
        $dumpList += $recentDump.FullName
    }
}

& $captureScript -Action $actionText -Dumps $dumpList
& $logScript -Category "session-hotkey" -Message "Action logged via prompt (autoDump=$AutoDump)"

Invoke-HostCommand -Command $ResumeCommand
