$LogFile = "C:\ProgramData\SCCM\Logs\GitBaseLines.txt"
if (-not (Test-Path -Path "C:\ProgramData\SCCM\Logs")) {
    New-Item -ItemType Directory -Path "C:\ProgramData\SCCM\Logs" | Out-Null
}
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "$timestamp - $Message"
}
Write-Log "################################################################################################################"
Write-Log "Start LOG"
$ResolveWingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"

    if ($ResolveWingetPath){
           $WingetPath = $ResolveWingetPath[-1].Path
    }
Write-Log "Location: $($wingetpath)"
Set-Location $wingetpath

# Set variables based on WinGet output language

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$langLine = .\winget --info | Select-String [0]
Write-Log "Value langLine: $($langLine)"
IF ($langLine -match "Package") {
$Available = 'Available'
$Version = 'Version'
$Version2 = 'Version:'
$ReleaseDate = 'Release Date:'
}
ELSE{
$Available = 'Доступно'
$Version = 'Версия'
$Version2 = 'Версия:'
$ReleaseDate = 'Дата выпуска:'
}


# Set AppID and App Location

$AppID = 'Git.Git'
$AppFolder = "$ENV:ProgramFiles\Git\git-bash.exe"

# Get App Released Date

$releaseDateStr = .\winget show --id $AppID --source winget | Select-String $ReleaseDate
Write-Log "Value releaseDateStr: $($releaseDateStr)"
$releaseDate = ($releaseDateStr -split($ReleaseDate)) -split '\s+' -match '\S'
$releaseDate = [datetime]::parseexact($releaseDate, 'yyyy-MM-dd', $null)
Write-Log "Value releaseDate: $($releaseDate)"
$Days = ([datetime](Get-Date -Format "yyyy-MM-dd") - $releaseDate).TotalDays
Write-Log "Value Days: $($Days)"
######################################## Lets try to upgrade it ################################################################################################################

######################################## Try to get local and available version rely to WinGet logic ###########################################################################

$lines = .\winget list --Id $AppID --source winget
$befoure = .\winget.exe list --Id $AppID --source winget | ForEach-Object { $_.Trim() } | Where-Object {$_ -and $_ -notmatch "^Name\s+Id\s+Version" -and $_ -notmatch "^-+$"} | Select-Object -last 1
Write-Log "Value befoure (as lines): $($befoure)"

IF ($lines -match $Available) {
Write-Log "Value Available: $($Available) --------------- 1 IF"
############################### Try to upgrade App ##################################

# Smooth Upgrade

IF ($Days -lt 10)
{
	Write-Log "Try to upgrade App -lt 5";
	Exit}
IF ($Days -gt 10)
{
	#Start-Process .\winget list --Id $AppID --source winget
	Write-Log "Try to upgrade App -gt 10"
	Start-Process .\winget -ArgumentList "upgrade --id $AppID --silent --source winget" -Wait -NoNewWindow
	$forlog = .\winget.exe list --Id $AppID --source winget | ForEach-Object { $_.Trim() } | Where-Object {$_ -and $_ -notmatch "^Name\s+Id\s+Version" -and $_ -notmatch "^-+$"} | Select-Object -last 1
	Write-Log "NOW: $($forlog)"
	Exit
	}
}


######################################## If WinGet didn't find local app will be try to get version in AppData folder ###########################################################################

Else {
Write-Log "ELSE"
    IF (Test-Path $AppFolder) { 
    $LocalVersion = (Get-ItemProperty $AppFolder).VersionInfo.ProductVersionRaw
	Write-Log "Value LocalVersion: $($LocalVersion)"
# Get App available version in WinGet

    $wingetVersion = .\winget show --id $AppID --source winget | Select-String $Version2
    [string]$wingetVersion = ($wingetVersion -split($Version2)) -split '\s+' -match '\S'
	Write-Log "Value wingetVersion: $($wingetVersion)"
# Compare LocalVersion and Available Version
 
        if ($LocalVersion -lt [version]$wingetVersion) {

####################### Try to upgrade App ###########################################  

# Smooth Upgrade

IF ($Days -lt 10)
{
	Write-Log "If WinGet didn't find local app will be try to get version in AppData folder -lt 5";
	Exit}
IF ($Days -gt 10)
{
	Write-Log "Try to upgrade App -gt 10"
	Start-Process .\winget -ArgumentList "install --id $AppID --silent --source winget" -Wait -NoNewWindow
	$forlog = .\winget.exe list --Id $AppID --source winget | ForEach-Object { $_.Trim() } | Where-Object {$_ -and $_ -notmatch "^Name\s+Id\s+Version" -and $_ -notmatch "^-+$"} | Select-Object -last 1
	Write-Log "NOW: $($forlog)"
	Exit
	}
        }
        
        else {
        Write-Log "Update Unavailable"
        Exit 0

        } 
    }
}