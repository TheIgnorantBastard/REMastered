param(
    [Parameter(Mandatory)][string]$File,
    [Parameter(Mandatory)][int]$Offset,
    [int]$Length = 128
)

$scriptRoot = Split-Path -Parent $PSCommandPath
$repoRoot = Resolve-Path (Join-Path $scriptRoot "..\..")
$targetPath = Join-Path $repoRoot $File
if (-not (Test-Path $targetPath)) {
    Write-Error "File not found: $targetPath"
    exit 1
}

$bytes = Get-Content -Path $targetPath -Encoding Byte -TotalCount ($Offset + $Length) -ErrorAction Stop
$snippet = $bytes[$Offset..([Math]::Min($bytes.Length - 1, $Offset + $Length - 1))]

$sb = New-Object System.Text.StringBuilder
$sb.AppendLine("# Hex snippet from $File") | Out-Null
$sb.AppendLine("Offset: 0x{0:X}" -f $Offset) | Out-Null
$sb.AppendLine("Length: $Length bytes") | Out-Null
$sb.AppendLine("") | Out-Null

for ($i = 0; $i -lt $snippet.Length; $i += 16) {
    $lineBytes = $snippet[$i..([Math]::Min($snippet.Length - 1, $i + 15))]
    $hex = ($lineBytes | ForEach-Object { "{0:X2}" -f $_ }) -join ' '
    $ascii = ($lineBytes | ForEach-Object { if ($_ -ge 32 -and $_ -le 126) { [char]$_ } else { '.' } }) -join ''
    $sb.AppendLine(('{0:X8}  {1,-47}  {2}' -f ($Offset + $i), $hex, $ascii)) | Out-Null
}

$logScript = Join-Path $scriptRoot "Write-MasterLog.ps1"
& $logScript -Category "hex" -Message "Extracted hex snippet ($File @ 0x{0:X} len={1})" -f $Offset, $Length

$sb.ToString()
