$ResolveWingetPath = Resolve-Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
    if ($ResolveWingetPath){
           $WingetPath = $ResolveWingetPath[-1].Path
    }

Set-Location $wingetpath

# Set variables based on WinGet output language

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$langline = .\winget --info | Select-String [0]
IF ($langline -match "Package") {
$Available = 'Available'
$Version = 'Version'
$Version2 = 'Version:'
}
ELSE{
$Available = 'Доступно'
$Version = 'Версия'
$Version2 = 'Версия:'
}


# Set AppID and App Location

$AppID = 'Git.Git'
$AppFolder = "$ENV:ProgramFiles\Git\git-bash.exe"

# Try to get local and available version rely to WinGet logic

$lines = .\winget list --Id $AppID --source winget

IF ($lines -match $Available) {
$Result = [int]1 }
ELSE {
$Result = [int]0 }

# Compair version in WinGet and Folder

    IF (Test-Path $AppFolder) { 
    $LocalVersion = (Get-ItemProperty $AppFolder).VersionInfo.ProductVersionRaw

# Get App available version in WinGet

    $wingetVersion = .\winget show --id $AppID --source winget | Select-String $Version2
    [string]$wingetVersion = ($wingetVersion -split($Version2)) -split '\s+' -match '\S'
   
# Compare LocalVersion and Available Version
 
        if ($LocalVersion -lt [version]$wingetVersion) {    
        $Result = [int]1
        }
        else {
        $Result = [int]0
        } 
    }

$Result