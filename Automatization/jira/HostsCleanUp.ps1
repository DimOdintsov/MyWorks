#$credential = Get-Credential
#$credential | Export-Clixml 'C:\yourcredcred.xml'
#Install-Module JiraPS -Scope CurrentUser
#Update-Module JiraPS
Set-JiraConfigServer -Server "https://domain.com"
$cred = Import-CliXml -Path 'C:\yourcredcred.xml' -ea Stop
$issues = Get-JiraIssue -Query 'project = WIN AND issuetype = "Task" AND status in (Open) AND updated >= startOfDay(-6d)' -Credential $cred | Where-Object {$_.Summary -match "На диске C: свободно"}

if ($issues) {
    Set-JiraIssue -Key $issues.Key -Fields @{
        Components = @(@{id = "57049"})
        Assignee = @{name = "hereUSERNAME"}
    } -Credential $cred -ea Stop
}
else{
Write-Host "Не найдено тикетов по данным параметрам"
Exit}

$hosts = @()
foreach ($issue in $issues) {
    $matchesArray = [regex]::Matches($issue.Summary, '^(?<HostName>\S+): На диске C: свободно (?<FreePercentage>\d+(\.\d+)?) % \((?<FreeSpace>\d+(\.\d+)?) GB из (?<TotalSpace>\d+(\.\d+)?) GB\)')
    if ($matchesArray) {
        $hostEntry = @{
            IssueID  = $issue.Key  # ID тикета
            HostName = $matchesArray[0].Groups['HostName'].Value
            FreePercentage = $matchesArray[0].Groups['FreePercentage'].Value
            FreeSpace = $matchesArray[0].Groups['FreeSpace'].Value
            TotalSpace = $matchesArray[0].Groups['TotalSpace'].Value
        }
        $hosts += $hostEntry
        Write-Host " $($hostEntry.IssueID) - Host:  $($hostEntry.HostName), Free: $($hostEntry.FreePercentage)%, Free Space: $($hostEntry.FreeSpace) GB, Total Space: $($hostEntry.TotalSpace) GB,"    }
    }
#проверяем доступность хостов, записываем в переменную.
$accessibleHosts = @()
$cleanResults = @()
foreach ($hostss in $hosts) {
    $testWinRM = Test-NetConnection -ComputerName $hostss.HostName -Port 5985 -WarningAction SilentlyContinue
    Copy-Item "\\yourPATCH\myFolder\Start-WindowsCleanup.ps1" "\\$($hostss.HostName)\C$\Windows\Temp\" -ErrorAction SilentlyContinue -Force
        if (-not $testWinRM.TcpTestSucceeded) {
           Write-Host "Хост $($hostss.HostName) недоступен по WinRM, удаляю из списка" -ForegroundColor Red
           $Transitionswait = ((Get-JiraIssue -Issue $hostss.IssueID -Credential $cred -ea Stop).Transition | Where-Object {$_.Name -match 'Waiting'}).id
           Add-JiraIssueComment -Comment "[~USERNAME] Призываю живую версию себя`nНе закрываем тикет для хоста $($hostss.HostName) - хост недоступен по WInRM," -Issue $issue.Key -Credential $cred -VisibleRole "Developers" -ea Stop | Out-Null
           Invoke-JiraIssueTransition -Issue $hostss.IssueID -Transition $Transitionswait -Credential $cred -ea Stop
           }
           else {
        $accessibleHosts += $hostss
            }
    }
    foreach ($hostss in $accessibleHosts) {
    try{
    $result = Invoke-Command -ComputerName $hostss.HostName -ScriptBlock{
        param($FreeSpace, $FreePercentage, $TotalSpace)
        powershell.exe -ExecutionPolicy Bypass -Command "C:\Windows\Temp\Start-WindowsCleanup.ps1" > $null 2>&1
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        $limitDate = (Get-Date).AddDays(-10)
        if (Test-Path "C:\Windows\Temp\") {
        Get-ChildItem -Path "C:\Windows\Temp\" -File | Where-Object { $_.LastWriteTime -lt $limitDate } | Remove-Item -Force -ErrorAction SilentlyContinue}
        if (Test-Path "C:\Windows\SoftwareDistribution\Download\") {
        Get-ChildItem -Path "C:\Windows\SoftwareDistribution\Download\" -File | Where-Object { $_.LastWriteTime -lt $limitDate } | Remove-Item -Force -ErrorAction SilentlyContinue}
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        Get-ChildItem -Path "C:\`$Recycle.Bin" -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        [__comobject]$CCMComObject = New-Object -ComObject 'UIResource.UIResourceMgr'
        $CacheInfo = $CCMComObject.GetCacheInfo().GetCacheElements()
        ForEach ($CacheItem in $CacheInfo) {$null = $CCMComObject.GetCacheInfo().DeleteCacheElement([string]$($CacheItem.CacheElementID)) }
        try{$a = cmd.exe /c Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase > $null 2>&1}catch{}
        $disk = Get-PSDrive -Name C
        $newFreeSpace = [math]::Round($disk.Free / 1GB, 2)
        $newTotalSpace = [math]::Round(($disk.Used + $disk.Free) / 1GB, 2)
        $freeSpaceDifference = [math]::Round($newFreeSpace - $freeSpace, 2)
        $newFreePercentage = [math]::Round(($newFreeSpace / $newTotalSpace) * 100, 2)
        $freePercentageDifference = [math]::Round($newFreePercentage - $freePercentage, 2)
        Write-Host "Host: $env:COMPUTERNAME | New Free Percentage: $newFreePercentage% | New Free Space: $newFreeSpace GB (Was - $freeSpace GB) | New Free Percentage: $newFreePercentage% (Was - $freePercentage%) | Difference: $freePercentageDifference%"  -ForegroundColor Yellow
        return [PSCustomObject]@{
                HostName                = $env:COMPUTERNAME
                NewFreePercentage       = $newFreePercentage
                NewFreeSpace            = $newFreeSpace
                OldFreeSpace            = $freeSpace
                FreeSpaceDifference     = $freeSpaceDifference
                OldFreePercentage       = $freePercentage
                FreePercentageDifference = $freePercentageDifference
            }
    } -ArgumentList $hostss.FreeSpace, $hostss.FreePercentage, $hostss.TotalSpace
    if ($result) {
    $cleanResults += $result
    }
    else{Write-Host "Ошибка: данные с $($hostss.HostName) не получены" -ForegroundColor Red}
    }catch{Write-Host "Ошибка во время подключения к удаленному хосту $($hostss.HostName) : $($_.Exception.Message)" -ForegroundColor Red}
}
foreach ($result in $cleanResults) {
    $commentBody = "Очистка дисков завершена. Результаты:`n"
    $commentBody += "Host: $($result.HostName).domain.com | New Free Space: $($result.NewFreeSpace) GB (Was - $($result.OldFreeSpace) GB) | New Free Percentage: $($result.NewFreePercentage)% (Was - $($result.OldFreePercentage)%) | Difference: $($result.FreePercentageDifference)%"
    Write-Host $commentBody
    $issue = $issues | Where-Object { $_.Summary -match "$($result.HostName)" }
    if ($issue) {
        if ($result.NewFreePercentage -lt 11) {
            Write-Host "Не закрываем тикет для хоста $($result.HostName), свободное место меньше 11%" -ForegroundColor Red
            $Transitionswait = ((Get-JiraIssue -Issue $issue.Key -Credential $cred -ea Stop).Transition | Where-Object {$_.Name -match 'Waiting'}).id
            Add-JiraIssueComment -Comment "[~USERNAME] Призываю живую версию себя`nНе закрываем тикет для хоста $($result.HostName) - вободное место меньше 11% - $($result.NewFreePercentage) and was - $($result.OldFreeSpace) " -Issue $issue.Key -Credential $cred -VisibleRole "Developers" -ea Stop | Out-Null
            Invoke-JiraIssueTransition -Issue $issue.Key -Transition $Transitionswait -Credential $cred -ea Stop
            continue
            }
        Write-Host "$commentBody - на закрытие тикета" -ForegroundColor Green
        Set-JiraIssue -Key $issue.Key -Fields @{ Components = @(@{id = "57049"}) } -Credential $cred -ea Stop
        $Transitions = ((Get-JiraIssue -Issue $issue.Key -Credential $cred -ea Stop).Transition | Where-Object {$_.Name -match 'ResolveDone'}).id
        Add-JiraIssueComment -Comment $commentBody -Issue $issue.Key -Credential $cred -VisibleRole "All users" -ea Stop | Out-Null
        Set-JiraIssueLabel -Issue $issue.Key -Set "success" -Credential $cred -ea Stop
        Invoke-JiraIssueTransition -Issue $issue.Key -Transition $Transitions -Credential $cred -ea Stop
    }
}