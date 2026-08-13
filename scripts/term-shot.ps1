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

# 复现脚本复制到 kali 家目录(避免 /mnt/c 痕迹), 引擎同款处理
& wsl.exe -d $distro bash -lc "mkdir -p /home/kali/edu && cp '$wslScript' /home/kali/edu/repro.sh && chmod +x /home/kali/edu/repro.sh && bash $wslEngine /home/kali/edu/repro.sh '$wslOut'"
if ($LASTEXITCODE -ne 0) {
  Write-Output "TERM_SHOT_FAILED exit=$LASTEXITCODE"
  exit 1
}
