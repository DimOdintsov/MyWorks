$LogFile = "C:\Windows\Temp\ReinstallSCCM.txt"
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "$timestamp - $Message"
}
Write-Log "Start of the script..."
# Uninstalling the SCCM Client
Write-Log "Uninstalling the SCCM Client.."
try {
    Start-Process -FilePath "C:\Windows\ccmsetup\ccmsetup.exe" -ArgumentList "/uninstall" -Wait
    Write-Log "SCCM client was successfully removed."
} catch {
    Write-Log "!!!!!!!!!!!!!Error during SCCM client uninstallation: $_"
}
# Removing residual directories
Write-Log "Removing residual directories..."
$directories = @(
    "$env:windir\CCM",
    "$env:windir\ccmcache",
    "$env:windir\ccmsetup"
)
foreach ($dir in $directories) {
    try {
        if (Test-Path $dir) {
            Remove-Item -Path $dir -Recurse -Force
            Write-Log "Remote directories: $dir"
        }
    } catch {
        Write-Log "Error while deleting directories $dir : $_"
    }
}
#Remove-Item "HKLM:\SOFTWARE\Microsoft\CCMSETUP"  -Recurse -Force
# Deleting the registry branch responsible for the config, it’s good to delete both, but I’m afraid to delete the first one
#HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\CCM
#HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\CCMSETUP
Write-Log "Deleting a registry key..."
    try {
        Remove-Item "HKLM:\SOFTWARE\Microsoft\CCMSETUP"  -Recurse -Force
        Write-Log "The registry key was successfully deleted: CCMSETUP"
        }
     catch {
        Write-Log "!!!!!!!!!!!!!Error during deletion in the registry $_"
    }

Write-Log "Checking WMI Status..."
try {
    $wmiStatus = Get-WmiObject Win32_OperatingSystem -ErrorAction Stop
    Write-Log "WMI works correctly.`nSystemDirectory: $($($wmiStatus).SystemDirectory)`nVersion: $($($wmiStatus).Version)"
} catch {
    # Disabling and stopping WMI
    Write-Log "Disabling and stopping WMI services..."
    try {
        Set-Service -Name winmgmt -StartupType Disabled
        Stop-Service -Name winmgmt -Force
        Write-Log "WMI сервис остановлен и отключен."
    } catch {
        Write-Log "!!!!!!!!!!!!!Error while stopping WMI service: $_"
    }
    # WMI repair
    Write-Log "WMI recovery..."
    try {
        Set-Location -Path "$env:windir\system32\wbem"
        Get-ChildItem -Filter *.dll | ForEach-Object { & regsvr32 /s $_.FullName }
        & wmiprvse /regserver
        Get-ChildItem -Path . | Where-Object {$_.Extension -in @(".mof", ".mfl")} | ForEach-Object { & mofcomp $_.FullName }
        Start-Service -Name winmgmt
        Write-Log "WMI is restored and the service is running."
    } catch {
        Write-Log "!!!!!!!!!!!!!Error during WMI restore: $_"
    }
    # Waiting for WMI restore to complete
    Write-Log "Wait 90 seconds WMI has finished restoring..."
    Start-Sleep -Seconds 90
}
Write-Log "Checking WinRM Status..."
try {
    $hosts = (Get-WmiObject -Class Win32_OperatingSystem).CSName
    $trashh = Test-WSMan -ComputerName $($hosts)
    Write-Log "WinRM works correctly.`nwsmid: $($($trashh).wsmid)`nProtocolVersion: $($($trashh).ProtocolVersion)`nProductVendor: $($($trashh).ProductVendor)`nProductVersion: $($($trashh).ProductVersion)"
} catch {
    Write-Log "!!!!!!!!!!!!!WinRM is not working, we are trying to restore it $_....."
    try{
        winrm quickconfig -q
        Write-Log "WinRM successfully restored restored $_....."
    }
    catch{Write-Log "!!!!!!!!!!!!!WinRM could not be restored $_....."}
}
# Stopping services
Write-Log "Stopping services for graceful shutdown..."
$services = @("bits", "wuauserv", "appidsvc", "cryptsvc")
foreach ($service in $services) {
    try {
        if ((Get-Service -Name $service).Status -eq "Running") {
            Stop-Service -Name $service -Force -Verbose
            Write-Log "Stopped service: $service"
        }
    } catch {
        Write-Log "!!!!!!!!!!!!!Error while stopping the service $service : $_"
    }
}
# Removing old .OLD directories
Write-Log "Removing old directories..."
$oldDirs = @(
    "C:\Windows\SoftwareDistribution.old",
    "C:\Windows\ccmcache.old",
    "C:\Windows\System32\catroot2.old"
)
foreach ($dir in $oldDirs) {
    try {
        Remove-Item -Path $dir -Force -Recurse -Verbose -ErrorAction SilentlyContinue
        Write-Log "old directories removed: $dir"
    } catch {
        Write-Log "!!!!!!!!!!!!!Error in deleting old directories $dir : $_"
    }
}
# Renaming current directories to .OLD
Write-Log "Переименование текущих каталогов в OLD..."
$renameDirs = @{
    "C:\Windows\SoftwareDistribution" = "SoftwareDistribution.old"
    "C:\Windows\ccmcache" = "ccmcache.old"
    "C:\Windows\System32\catroot2" = "catroot2.old"
}
foreach ($dir in $renameDirs.Keys) {
    try {
        if (Test-Path $dir) {
            Rename-Item -Path $dir -NewName $renameDirs[$dir] -Verbose
            Write-Log "Renamed directory $dir в $($renameDirs[$dir])"
        }
    } catch {
        Write-Log "!!!!!!!!!!!!!error while renaming directory $dir : $_"
    }
}
# Starting services
Write-Log "Let's restart the services..."
foreach ($service in $services) {
    try {
        Start-Service -Name $service -Verbose
        Write-Log "Service launched: $service"
    } catch {
        Write-Log "!!!!!!!!!!!!!Error starting service $service : $_"
    }
}
Write-Log "We update the policies, because I advise this on the forums........."
try{
    Start-Process gpupdate /force -Wait
    Write-Log "Policies updated"
    }
catch{
    Write-Log "!!!!!!!!!!!!!Errors during policy update: $_"
}
#Get-WmiObject -Namespace "ROOT\CCM" -Class CCM_Client
Write-Log "We wait 60 seconds after starting the service..."
Start-Sleep -Seconds 60
Write-Log "Запускаем Uninstall-SCCM, из sccm.exe..."
try{
    Start-Process -FilePath "C:\Windows\Temp\Client\ccmsetup.exe" -ArgumentList "/uninstall" -Wait
    Write-Log "sccm.exe uninstall completed successfully."
    }
catch{
    Write-Log "!!!!!!!!!!!!!Runtime errors Uninstall sccm: $_"
}

# Запуск ClientHealth.ps1
Write-Log "Run ClientHealth.ps1 to restore SCCM (so that the client is updated correctly and all parameters are registered)..."
#https://github.com/AndersRodland/ConfigMgrClientHealth/blob/master/ConfigMgrClientHealth.ps1
try {
    
    $psArgs = @(
        "-ExecutionPolicy Bypass","-Noninteractive",
        "-File \\yourshare\ClientHealth$\ConfigMgrClientHealth_new.ps1",
        "-Config \\yourshare\ClientHealth$\Config_new.xml",
        "-Webservice https://cmdb.domain.com:4443/ConfigMgrClientHealth"
    )
    Start-Process -FilePath "PowerShell.exe" -ArgumentList $psArgs -Wait
    Write-Log "ClientHealth.ps1 job completed successfully."
} catch {
    Write-Log "!!!!!!!!!!!!!Errors while running ClientHealth.ps1: $_"
}
# Completing the script

Write-Log "Script execution completed."