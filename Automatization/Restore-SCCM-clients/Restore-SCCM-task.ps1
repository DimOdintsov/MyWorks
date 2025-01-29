Import-Module -Name "F:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
Set-Location "199:"

#location where keep local log, function for log
$LogFile = "C:\Windows\Temp\ReinstallSCCM.txt"
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "$timestamp - $Message"
}
Write-Log "Getting started with the recovery procedure for SCCM clients"
Write-Log "-------------Important info - each host have a personal log file. C:\Windows\Temp\ReinstallSCCM"

#Get hosts from collection
$hostsContent = (Get-CMDevice -CollectionId ****).Name

#It is important to do Set-Location C because when he is in the module he cannot look into the balls normally
Set-Location C:

#a sheet in which I will place a list of hosts after checking the filter in AD + add domain.com
$hostslist = @()
Write-Log "list of hosts"
foreach ($in in $hostsContent){
    $a = (Get-ADComputer -Filter "Name -eq '$in'" -SearchBase "OU=servers,DC=domain,DC=com").Name
    Write-Log "$a"
    $hostslist += $a + ".domain.com"
    }
Write-Log "We run the logic for transferring files, etc."
#main logic, take a list, copy files to it locally at tempo, main script with logic + xml task for scheduler which will be created locally
foreach($in in $hostslist){
    try{
        Copy-Item -Path "\\yourshare.domain.com\Folder\ForSCCM\RestoreSCCM.ps1" -Destination "\\$($in)\C$\Windows\Temp\" -force
        Start-Sleep 1
        Copy-Item "\\yourshare.domain.com\Folder\ForSCCM\SCCMTaskFullRepair.xml" "\\$($in)\C$\Windows\Temp\" -force
        Start-Sleep 1
        Write-Log "data was copied successfully to $in"
        }
        catch{Write-Log "Something went wrong on $in"}
try{
Write-Log "The file transfer was completed successfully on all hosts, we begin to create remote tasks to restore the config on clients"
Invoke-Command -ComputerName $in -ScriptBlock {
    $FilePath = "C:\Windows\Temp\SCCMTaskFullRepair.xml"
    $xml = Get-Content $FilePath -Raw
    [xml]$xmlObject = $xml
    $TaskName = $xmlObject.Task.RegistrationInfo.URI
    if($a=Get-ScheduledTask -TaskName $($TaskName.Split("\") | Select-Object -Last 1) -ErrorAction SilentlyContinue){$a | Unregister-ScheduledTask -Confirm:$false}
    $a = Register-ScheduledTask -Xml $xml -TaskName $TaskName
    Start-Sleep 3
    Start-ScheduledTask -TaskName $TaskName
    }
Write-Log "All jobs are created on the host $in"
}
catch{$error}
}