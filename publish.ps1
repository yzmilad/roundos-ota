param(
  [Parameter(Mandatory = $true)][string]$Version,
  [string]$Bin = ""
)

$ErrorActionPreference = "Stop"
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
  throw "Version must be like 1.0.1"
}

$repo = "yzmilad/roundos-ota"
$url = "https://github.com/$repo/releases/download/v$Version/firmware.bin"
$json = "{`"version`":`"$Version`",`"url`":`"$url`"}"
[System.IO.File]::WriteAllText((Join-Path $PSScriptRoot "version.json"), $json)

$assets = @((Join-Path $PSScriptRoot "version.json"))
if ($Bin) {
  if (-not (Test-Path $Bin)) {
    throw "Bin not found: $Bin"
  }
  $dest = Join-Path $PSScriptRoot "firmware.bin"
  Copy-Item -Force $Bin $dest
  $assets += $dest
}

Push-Location $PSScriptRoot
try {
  git add version.json
  $st = git status --porcelain -- version.json
  if ($st) {
    git commit -m "Point manifest at v$Version"
    git push origin HEAD
  }
  gh release create "v$Version" @assets --repo $repo --title "v$Version" --notes "RoundOS $Version"
}
finally {
  Pop-Location
}
