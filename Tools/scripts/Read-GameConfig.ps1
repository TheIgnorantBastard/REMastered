param(
    [string]$ConfigPath = "game.json"
)

if (-not (Test-Path $ConfigPath)) {
    throw "Config file '$ConfigPath' not found."
}

$cfgJson = Get-Content $ConfigPath -Raw
$cfg = $cfgJson | ConvertFrom-Json
return $cfg
