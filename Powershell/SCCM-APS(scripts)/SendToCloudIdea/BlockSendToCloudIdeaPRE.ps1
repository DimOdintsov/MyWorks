$path = Join-Path $env:APPDATA 'JetBrains\consentOptions\accepted'
if (Test-Path $path) {
  $c = Get-Content $path -Raw -EA SilentlyContinue
  $p = '(^|;)(rsch\.send\.usage\.stat:[^:]+:)(?:1)(?=:)'
  $n = [regex]::Replace($c, $p, '$1${2}0')
  if ($n -ne $c) { Write-Output 0 }else{Write-Output 1}
}