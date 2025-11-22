param(
    [string]$DefaultIdea = ""
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$brainstormScript = Join-Path $scriptRoot "Log-Brainstorm.ps1"
$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"

try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
}
catch {
    Write-Warning "Falling back to console prompt: $_"
}

$ideaText = $DefaultIdea
$usedGui = $false

if ([System.Windows.Forms.Form]::TypeInitializer) {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Log Automation / Feature Idea"
    $form.Width = 520
    $form.Height = 280
    $form.StartPosition = 'CenterScreen'

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Describe the idea you'd like to capture:"
    $label.AutoSize = $true
    $label.Left = 10
    $label.Top = 10

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Multiline = $true
    $textBox.Left = 10
    $textBox.Top = 35
    $textBox.Width = 480
    $textBox.Height = 150
    $textBox.Text = $DefaultIdea

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "Save"
    $okButton.Width = 80
    $okButton.Height = 30
    $okButton.Left = 310
    $okButton.Top = 200
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Width = 80
    $cancelButton.Height = 30
    $cancelButton.Left = 400
    $cancelButton.Top = 200
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel

    $form.Controls.AddRange(@($label,$textBox,$okButton,$cancelButton))
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton

    $dialogResult = $form.ShowDialog()
    if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
        & $logScript -Category "ideas" -Message "Idea prompt dismissed"
        return
    }
    $ideaText = $textBox.Text.Trim()
    $usedGui = $true
}
else {
    $ideaText = Read-Host "Describe the idea you'd like to capture"
}

if ([string]::IsNullOrWhiteSpace($ideaText)) {
    Write-Host "No idea entered. Aborting." -ForegroundColor Yellow
    & $logScript -Category "ideas" -Message "Idea prompt closed without entry"
    return
}

& $brainstormScript -Idea $ideaText
& $logScript -Category "ideas" -Message ("Idea logged via prompt (GUI={0})" -f $usedGui)
