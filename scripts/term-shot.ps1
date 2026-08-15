param(
  [Parameter(Mandatory = $true)][string]$Script,
  [Parameter(Mandatory = $true)][string]$OutFile
)

$ErrorActionPreference = "Stop"
$ENGINE = Join-Path $PSScriptRoot "term-shot.sh"

function Get-WslDistro {
  try {
    $r = & wsl.exe -d kali-linux -- echo ok 2>$null
    if ($LASTEXITCODE -eq 0 -and $r -eq "ok") { return "kali-linux" }
  } catch { }
  return $null
}

function Convert-WinToWslPath([string]$p) {
  if ($p -match '^([A-Za-z]):\\(.*)$') {
    $drive = $matches[1].ToLower()
    $rest = $matches[2].Replace('\', '/')
    return "/mnt/$drive/$rest"
  }
  return $p
}

$distro = Get-WslDistro
if (-not $distro) {
  $distro = "kali-linux"
}

$wslScript = Convert-WinToWslPath $Script
$wslOut = Convert-WinToWslPath $OutFile
$wslEngine = Convert-WinToWslPath $ENGINE
$tok = [guid]::NewGuid().ToString('N').Substring(0, 8)
$wslRepro = "/home/kali/edu/repro_$tok.sh"

# NOTE: keep this file ASCII-only. PowerShell 5.1 parses BOM-less UTF-8 files as GBK,
# and non-ASCII bytes can silently break script parsing (exit 0, no output, no PNG).
# Copy repro script to kali home dir (avoid /mnt/c traces); unique name per render.
& wsl.exe -d $distro bash -lc "mkdir -p /home/kali/edu && cp '$wslScript' '$wslRepro' && chmod +x '$wslRepro' && bash '$wslEngine' '$wslRepro' '$wslOut'; rm -f '$wslRepro'"
if ($LASTEXITCODE -ne 0) {
  Write-Output "TERM_SHOT_FAILED exit=$LASTEXITCODE"
  exit 1
}
