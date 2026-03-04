#OLD FILE HERE ---- $env:APPDATA\JetBrains#
$path = Join-Path $env:APPDATA 'JetBrains\consentOptions\accepted'
Copy-Item -Path $path -Destination $env:APPDATA\JetBrains -Force -ErrorAction SilentlyContinue
if (Test-Path $path) {
  $c = Get-Content $path -Raw -EA SilentlyContinue
  $p = '(^|;)(rsch\.send\.usage\.stat:[^:]+:)(?:1)(?=:)'
  $n = [regex]::Replace($c, $p, '$1${2}0')
  if ($n -ne $c) { Set-Content $path -Value $n -Encoding UTF8 -NoNewline }
}