param(
  [Parameter(Mandatory = $true)][string]$Version,
  [string]$Bin = ""
)

$ErrorActionPreference = "Stop"
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
  throw "Version must be like 1.0.1"
}

$repo = "yzmilad/roundos-ota"
$cdn = "https://cdn.jsdelivr.net/gh/yzmilad/roundos-ota"

function Invoke-JsdelivrPurge([string]$RelPath) {
  $purgeUrl = "https://purge.jsdelivr.net/gh/yzmilad/roundos-ota@$RelPath"
  Write-Host "Purge $purgeUrl"
  try {
    Invoke-WebRequest -Uri $purgeUrl -UseBasicParsing -TimeoutSec 60 | Out-Null
  } catch {
    Write-Warning "jsDelivr purge failed for $RelPath : $($_.Exception.Message)"
  }
}

function Write-Manifest([string]$BinUrl) {
  $json = "{`"version`":`"$Version`",`"url`":`"$BinUrl`"}"
  [System.IO.File]::WriteAllText((Join-Path $PSScriptRoot "version.json"), $json)
}

Push-Location $PSScriptRoot
try {
  $assets = @((Join-Path $PSScriptRoot "version.json"))
  $binUrl = "$cdn@v$Version/firmware.bin"

  if ($Bin) {
    if (-not (Test-Path $Bin)) {
      throw "Bin not found: $Bin"
    }
    $dest = Join-Path $PSScriptRoot "firmware.bin"
    Copy-Item -Force $Bin $dest
    $assets += $dest
    git add -f firmware.bin
    $stBin = git status --porcelain -- firmware.bin
    if ($stBin) {
      git commit -m "Add firmware $Version"
      git push origin HEAD
    }
    $sha = (git rev-parse HEAD).Trim()
    if ($sha -notmatch '^[0-9a-f]{40}$') {
      throw "Could not read firmware commit SHA"
    }
    # Commit hash is immutable on jsDelivr (no 12h @main cache on the .bin).
    $binUrl = "$cdn@$sha/firmware.bin"
  }

  Write-Manifest $binUrl
  git add version.json
  $stJson = git status --porcelain -- version.json
  if ($stJson) {
    git commit -m "Point manifest at v$Version"
    git push origin HEAD
  }

  gh release create "v$Version" @assets --repo $repo --title "v$Version" --notes "RoundOS $Version"

  Start-Sleep -Seconds 12
  Invoke-JsdelivrPurge "latest/version.json"
  Invoke-JsdelivrPurge "latest/firmware.bin"
  Invoke-JsdelivrPurge "main/version.json"
  Invoke-JsdelivrPurge "main/firmware.bin"
}
finally {
  Pop-Location
}
