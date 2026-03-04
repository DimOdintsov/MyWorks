param(
  [string]$AppName
)

function Get-InteractiveUserSID {
  try {
    $p = Get-Process explorer -IncludeUserName -ErrorAction Stop | Select-Object -First 1
    (New-Object System.Security.Principal.NTAccount($p.UserName)).Translate([System.Security.Principal.SecurityIdentifier]).Value
  } catch {
    Write-Error "Error for detection users: $_"
    $null
  }
}
if (-not (Get-PSDrive HKU -ErrorAction SilentlyContinue)) {New-PSDrive -PSProvider Registry -Root HKEY_USERS -Name HKU | Out-Null}
$roots = @(
  "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
  "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
if ($sid = Get-InteractiveUserSID) {
  $roots += @(
    "HKU:\$sid\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKU:\$sid\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
  )
}
$pattern = [regex]::Escape($AppName)
$items = Get-ItemProperty -Path $roots -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -and $_.DisplayName -imatch $pattern }

foreach ($u in $items) {
  $line = if ($u.QuietUninstallString) { $u.QuietUninstallString } else { $u.UninstallString }
  if (-not $line) { continue }
  if ($line -match '^\s*"([^"]+)"\s*(.*)$') {
    $exe  = $matches[1]
    $args = $matches[2].Trim()
  } else {
    $parts = $line -split '\s+', 2
    $exe   = $parts[0]
    $args  = if ($parts.Count -gt 1) { $parts[1] } else { '' }
  }
  if ([IO.Path]::GetFileName($exe) -imatch '^msiexec(\.exe)?$') {
    $args = $args -replace '(^|\s)/i(\s|$)',' /x$2'
    if ($args -notmatch '(/qn|/quiet)') { $args += ' /qn /norestart' }
    $wd = $null
  } else {
    if ($args -match '--uninstall' -and $args -notmatch '(^| )(-s|--silent)\b') {
      $args += ' -s'
    }
    $wd = Split-Path -Path $exe -Parent
  }
  Write-Host "RUN: $exe $args"
  if (Test-Path -LiteralPath $exe) {
    $p = Start-Process -FilePath $exe -ArgumentList $args -WorkingDirectory $wd -Wait -PassThru -ErrorAction Continue
    $exit = $p.ExitCode
  } else {
    $p = Start-Process -FilePath cmd.exe -ArgumentList "/c $line" -Wait -PassThru -ErrorAction Continue
    $exit = $p.ExitCode
  }
  Write-Host "ExitCode: $exit"
  $paths = @()
  if ($u.PSObject.Properties.Match('InstallLocation').Count -gt 0 -and $u.InstallLocation) { $paths += $u.InstallLocation }
  if ($exe) { $paths += (Split-Path $exe -Parent) }
  $paths = $paths | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique
  foreach ($p in $paths) {
    if ($p -match '\\AppData\\(Local|Roaming)\\' -and $p -imatch [regex]::Escape($AppName)) {
      try {
        Write-Host "Delete dir: $p"
        Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction Stop
      } catch {
        Write-Warning "Can't delete $p $($_.Exception.Message)"
      }
    } else {
      Write-Host "Skip dir (safety rule): $p"
    }
  }
  try {
    if (Test-Path -LiteralPath $u.PSPath) {
      Write-Host "Delete reg: $($u.PSPath)"
      Remove-Item -LiteralPath $u.PSPath -Recurse -Force -ErrorAction Stop
    }
  } catch {
    Write-Warning "Can't delete reg $($u.PSPath): $($_.Exception.Message)"
  }
}