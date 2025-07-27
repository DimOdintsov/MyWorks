$Username = '1cservice'
$Pdce = (Get-AdDomain).PDCEmulator
$GweParams = @{
‘Computername’ = $Pdce
‘LogName’ = ‘Security’
‘FilterXPath’ = "*[System[EventID=4740] and EventData[Data[@Name='TargetUserName']='$Username']]"
}
$Events = Get-WinEvent @GweParams
$Events | foreach {$_.Properties[1].value + ' ' + $_.TimeCreated}


#4740 - блокировка
#4625 - вход с не правильным паролем
##########################################################################################

$Username = '1cservice'
$blockLOG = @()
$dc = Get-ADDomainController -filter * | Select-Object -ExpandProperty name
foreach($Pdce in $dc){
try{
$GweParams = @{
‘Computername’ = $Pdce
‘LogName’ = ‘Security’
‘FilterXPath’ = "*[System[EventID=4740] and EventData[Data[@Name='TargetUserName']='$Username']]"
}
#Write-Host "Host log  $Pdce"
$Events = Get-WinEvent @GweParams -ErrorAction SilentlyContinue
$a = $Events | foreach {$_.Properties[1].value + ' - ' + $_.Properties[0].value +' - ' + $_.TimeCreated}
foreach($in in $a){$blockLOG += $in}
}
catch{}
#$Events | foreach {$_.Properties[0].value + ' - ' + $_.Properties[1].value +' - ' + $_.Properties[2].value +' - ' + $_.Properties[3].value +' - ' + $_.Properties[4].value +' - ' + $_.Properties[5].value +' - ' + $_.Properties[6].value +' - ' + $_.Properties[7].value +' - ' + $_.Properties[8].value +' - ' + $_.Properties[9].value +' - ' + $_.Properties[10].value}
}
Write-Output $blockLOG

##########################################################################################

$blockLOG = @()
$dc = Get-ADDomainController -filter * | Select-Object -ExpandProperty name
foreach($Pdce in $dc){
try{
$GweParams = @{
‘Computername’ = $Pdce
‘LogName’ = ‘Security’
‘FilterXPath’ = "*[System[EventID=4740]]"
}
#Write-Host "Host log  $Pdce"
$Events = Get-WinEvent @GweParams -ErrorAction SilentlyContinue
$a = $Events | foreach {$_.Properties[1].value + ' - ' + $_.Properties[0].value +' - ' + $_.TimeCreated}
foreach($in in $a){$blockLOG += $in}
}
catch{}
#$Events | foreach {$_.Properties[0].value + ' - ' + $_.Properties[1].value +' - ' + $_.Properties[2].value +' - ' + $_.Properties[3].value +' - ' + $_.Properties[4].value +' - ' + $_.Properties[5].value +' - ' + $_.Properties[6].value +' - ' + $_.Properties[7].value +' - ' + $_.Properties[8].value +' - ' + $_.Properties[9].value +' - ' + $_.Properties[10].value}
}
Write-Output $blockLOG


$Pdce = Get-Content -Path "C:\Users\adm.odintsov\Documents\skripts\mail.txt"
#$Pdce = Get-Content -Path "C:\Users\adm.odintsov\Documents\skripts\DC.txt"
$Username = '1cservice'
foreach ($computer in $Pdce)
{
    Write-Host $computer
    Invoke-Command -ComputerName $computer -ErrorAction SilentlyContinue -ScriptBlock {
        param($remoteComputer, $Username)
        
        $GweParams = @{
            'LogName' = 'Security'
            'FilterXPath' = "*[System[EventID=4625] and EventData[Data[@Name='TargetUserName']='$Username']]"
        }

        $Events = Get-WinEvent @GweParams

        # Выводим информацию о неудачных попытках входа
        $Events | ForEach-Object {
            $AccountName = $_.Properties[5].Value  # Account For Which Logon Failed
            $FailureReason = $_.Properties[13].Value  # Failure Reason
            $IPAddress = $_.Properties[18].Value  # IP Address of the source
            $TimeCreated = $_.TimeCreated
            "$AccountName - $FailureReason - $TimeCreated"

            #"$AccountName - $FailureReason - $IPAddress - $TimeCreated"
        }
    } -ArgumentList $computer, $Username
}

