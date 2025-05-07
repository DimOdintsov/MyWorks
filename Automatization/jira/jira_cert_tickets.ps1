#$credential = Get-Credential
#$credential | Export-Clixml 'C:\yourcredcredcred.xml'
#Install-Module JiraPS -Scope CurrentUser
#Update-Module JiraPS
Set-JiraConfigServer -Server "https://yourjiraserver.ru"
$cred = Import-CliXml -Path 'C:\yourcread.xml' -ea Stop
$issues = Get-JiraIssue -Query 'project = WIN AND issuetype = "Task" AND status in (Open) AND updated >= startOfDay(-1d)' -Credential $cred | Where-Object {$_.Summary -match "Замена сертификата "}
#Убрал назначение компонента и асайн т.к.это прописал в пост функции для ResouleToArchive, после прожатия назначается на autobot и проставляется компонент
if ($issues) {
    Write-Host "Тикеты получены"
}
else{
 Write-Host "Не найдено тикетов по данным параметрам"
Exit}
#2 пустые переменные которые будут наполняться хостами в зависимости от типа тикета, 1 тикет = 1 хост, либо 1 тикет = n хостов. Все Наполняется строго как хеш таблица
$hosts = @()
$listofHosts = @()
#регулярки для вытаскивания записей и определния у нас 1 тикет = 1 запись. Либо 1 тикет и n записей.
foreach ($issue in $issues) {
    $matchesArray = [regex]::Matches($issue.Description.Trim(), '(?<HostName>[^\|\s:]+):Cert:\\(?<Path>[^\s|]+)')

    # Если найден только один хост и путь, записываем в $hosts
    if ($matchesArray.Count -eq 1) {
        $hostEntry = @{
            IssueID  = $issue.Key  # ID тикета
            HostName = $matchesArray[0].Groups['HostName'].Value + ".domain.com"
            Path     = $matchesArray[0].Groups['Path'].Value
        }
        $hosts += $hostEntry
        Write-Host "$($issue.Key) Одиночный хост: $($hostEntry.HostName), Путь: $($hostEntry.Path), Тикет: $($hostEntry.IssueID)"
    }
    # Если несколько хостов и путей, записываем в $listofHosts
    elseif ($matchesArray.Count -gt 1) {
        $multiHostEntry = @{
            IssueID = $issue.Key
            Hosts   = @()
        }
        foreach ($match in $matchesArray) {
            $hostName = $match.Groups['HostName'].Value + ".domain.com"
            $path = $match.Groups['Path'].Value
            $multiHostEntry.Hosts += @{ HostName = $hostName; Path = $path; IssueID = $issue.Key }
        }

        $listofHosts += $multiHostEntry
        #Write-Host "Групповой тикет: $($issue.Key), Количество хостов: $($multiHostEntry.Hosts.Count)"
    }
}

#--------------------1 проверка на тикет+1 хост и все операции
$accessibleHosts = @()
if($hosts){
foreach ($hostss in $hosts) {
    #проверка доступности и переформирование списка
    $testWinRM = Test-NetConnection -ComputerName $hostss.HostName -Port 5985 -WarningAction SilentlyContinue
        if (-not $testWinRM.TcpTestSucceeded) {
            Write-Host "Хост $($hostss.HostName) недоступен по WinRM, удаляю из списка" -ForegroundColor Red
            Add-JiraIssueComment -Comment "*Кожаные мешки нужно обратить внимание на тикет*`n*Хост $($hostss.HostName) недоступен по WinRM*" -Issue $hostss.IssueID -Credential $cred -VisibleRole "All users" -ea Stop | Out-Null
            $Transitionswait = ((Get-JiraIssue -Issue $hostss.IssueID -Credential $cred -ea Stop).Transition | Where-Object {$_.Name -match 'Waiting'}).id
            Invoke-JiraIssueTransition -Issue $hostss.IssueID -Transition $Transitionswait -Credential $cred -ea Stop
           }
           else {
            #тють переформируем
        $accessibleHosts += $hostss
            }
    }
    #тють инфа с зостов, так же в виде хеш таблицы
    $cleanResults = @()
    foreach ($hostss in $accessibleHosts) {
    try{
        $result = Invoke-Command -ComputerName $hostss.HostName -ScriptBlock {
                param($path)
                    #Сначала сделал провевку такую, где тру и фолс выдает, но дальнейшая проверка была по разному когда значение нулл было, поведение было по разному, через каунт всегда четко 0 или 1 и все
                    #$statusofcert = Get-ChildItem -Path "Cert:\$($Path)" -ErrorAction SilentlyContinue | select-object -ExpandProperty Archived
                    $hasArchivedCert = (Get-ChildItem -Path "Cert:\$($path)" -ErrorAction SilentlyContinue | Where-Object { $_.Archived } | Measure-Object).Count -gt 0
                    return [PSCustomObject]@{
                    HostName                = $env:COMPUTERNAME
                    statusofcert            = $hasArchivedCert 
                    Patch                   = $path
                    }
            } -ArgumentList $hostss.Path
            if ($result) {
                $cleanResults += $result
            } else {
                Write-Host "Ошибка: данные с $($hostss.HostName) не получены" -ForegroundColor Red
            }
        }
     catch{Write-Host "Ошибка при подключении\получении сертификата к $($hostss['HostName']): $($_.Exception.Message)" -ForegroundColor Red}
        }
#получаем инфу по хостам и уже отправляем на закрытие\нет
foreach ($result in $cleanResults) {
    $commentBody = "Сертификат на Host: $($result.HostName).domain.com по пути: $($result.Patch) находится в архиве StatusOfArchived: $($result.statusofcert)"
    Write-Host $commentBody
    $escapedPath = [regex]::Escape($result.Patch)
    $issue = $issues | Where-Object { $_.Description -match "$($result.HostName)" -and $_.Description -match "$escapedPath"}
    if ($issue) {
        if ($null -eq $result.statusofcert -or $result.statusofcert -eq 0) {
            Write-Host "Не закрываем тикет для хоста $($result.HostName), т.к сертификат не находится в архиве или что-то еще $($result.Patch)" -ForegroundColor Red

            Add-JiraIssueComment -Comment "*Кожаные мешки нужно обратить внимание на тикет*`nНе закрываем тикет для хоста $($result.HostName) - $($result.Patch), Status - $($result.statusofcert)," -Issue $issue.Key -Credential $cred -VisibleRole "All users" -ea Stop | Out-Null
            $Transitionswait = ((Get-JiraIssue -Issue $issue.Key -Credential $cred -ea Stop).Transition | Where-Object {$_.Name -match 'Waiting'}).id
            Invoke-JiraIssueTransition -Issue $issue.Key -Transition $Transitionswait -Credential $cred -ea Stop
            continue
            }
        #Write-Host "$commentBody - на закрытие тикета" -ForegroundColor Green
        #Write-Host "$commentBody" -ForegroundColor Green
        $Transitions = ((Get-JiraIssue -Issue $issue.Key -Credential $cred -ea Stop).Transition | Where-Object {$_.Name -match 'ResouleToArchive'}).id
        Add-JiraIssueComment -Comment $commentBody -Issue $issue.Key -Credential $cred -VisibleRole "All users" -ea Stop | Out-Null
        Set-JiraIssueLabel -Issue $issue.Key -Set "success" -Credential $cred -ea Stop
        Invoke-JiraIssueTransition -Issue $issue.Key -Transition $Transitions -Credential $cred -ea Stop   
        }
    }
}
#--------------------2 проверка на тикет+n хостов и все операции (тут может быть 1 тикет и 100 хостов в нем), тут собираем и обрабатываем именно такие случаи
$accessiblelistofHosts = @()
if($listofHosts){
    #забираем в переменную, если хостов оказалось больше 50, то забираем только 1е 10 штук на проверку.
    $hostsToCheck = if(($listofHosts.Hosts.HostName).Count -ge 50) {$listofHosts.Hosts | Select-Object -First 10}
    else {$listofHosts.Hosts}
    #для сохранения структуры хеш таблиц создаем темп листы, чтобы их наполнить потом списком хостов и примапить обратно к хеш таблице
    $tempList = $listofHosts | Select-Object * -ExcludeProperty Hosts
    $tempList | Add-Member -MemberType NoteProperty -Name 'Hosts' -Value @()
    foreach ($in in $hostsToCheck){
    $testWinRM = Test-NetConnection -ComputerName $in.HostName -Port 5985 -WarningAction SilentlyContinue
    #Write-Host "Хост $($in.HostName) ОК"
    
        if (-not $testWinRM.TcpTestSucceeded) {
            Write-Host "Хост $($in.HostName) недоступен по WinRM, удаляю из списка" -ForegroundColor Red
            Add-JiraIssueComment -Comment "*Кожаные мешки нужно обратить внимание на тикет*`n*Хост $($in.HostName) недоступен по WinRM*" -Issue $in.IssueID -Credential $cred -VisibleRole "All users" -ea Stop | Out-Null
            $Transitionswait = ((Get-JiraIssue -Issue $in.IssueID -Credential $cred -ea Stop).Transition | Where-Object {$_.Name -match 'Waiting'}).id
            Invoke-JiraIssueTransition -Issue $in.IssueID -Transition $Transitionswait -Credential $cred -ea Stop
            }
        else {
            #Write-Host "Хост $($in.HostName) Добавлен"
            $tempList.Hosts += $in
        }
    }
    #Для сохранения всех данных все делаетяс через хеш таблицу, чтобы при удалении хоста по не доступности, сразу удалялся и путь к серту.
    #создаем структуру как и было.
    if($tempList.Hosts.Count -gt 0) {
        $accessiblelistofHosts += $tempList
    }
    
    $cleanResults = @()
    foreach ($hostss in $accessiblelistofHosts.Hosts) 
    {
    try{
        $result = Invoke-Command -ComputerName $hostss.HostName -ScriptBlock {
                param($path, $IssueID)
                    #$statusofcert = Get-ChildItem -Path "Cert:\$($Path)" -ErrorAction SilentlyContinue | select-object -ExpandProperty Archived
                    $hasArchivedCert = (Get-ChildItem -Path "Cert:\$($path)" -ErrorAction SilentlyContinue | Where-Object { $_.Archived } | Measure-Object).Count -gt 0
                    return [PSCustomObject]@{
                    HostName                = $env:COMPUTERNAME
                    statusofcert            = $hasArchivedCert 
                    Patch                   = $path
                    IssueID                 = $IssueID
                    }
            } -ArgumentList $hostss.Path, $hostss.IssueID
            if ($result) {
                $cleanResults += $result
            } else {
                Write-Host "Ошибка: данные с $($hostss.HostName) не получены" -ForegroundColor Red
            }
        }
    catch{Write-Host "Ошибка при подключении\получении сертификата к $($hostss['HostName']): $($_.Exception.Message)" -ForegroundColor Red}
    }

    $groupedResults = $cleanResults | Group-Object -Property IssueID
#результаты для тикета, все собираем чтобы хост = путь тикета, даже при удалении и тп, количество хостов всегда = количеству путей.
foreach ($group in $groupedResults) {
    $issueID = $group.Name
    $results = $group.Group
    #если тикеты не в архиве то сохраняем их в переменную чтобы проверить, я знаю что можно впихнуть прям в иф но будет менее читабельно
    $notArchived = $results | Where-Object { $_.statusofcert -eq $null -or $_.statusofcert -eq 0 }
    if ($notArchived) {
        Write-Host "$issueID - Есть сертификаты, которые не находятся в архиве, тикет не закрываем!" -ForegroundColor Red
        $commentBody = "*Кожаные мешки нужно обратить внимание на тикет*`nНе закрываем тикет c хостами:`n"

            foreach ($entry in $notArchived) {
                $commentBody += "- Host: $($entry.HostName) Path: $($entry.Patch), Status: $($entry.statusofcert)`n"
            }
        if(($listofHosts.Hosts.HostName).Count -ge 50){
            $commentBody += "`n*Внимание в списке находится $(($listofHosts.Hosts.HostName).Count) хостов, по этому статистику снимаем 1-х 10.*"
        }
        #в одиночном виде было с трансишинами, оставлю их в таком виде, вдруг в будущем передумаем)
        Add-JiraIssueComment -Comment $commentBody -Issue $issueID -Credential $cred -VisibleRole "All users" -ea Stop | Out-Null
        $Transitionswait = ((Get-JiraIssue -Issue $issueID -Credential $cred -ea Stop).Transition | Where-Object {$_.Name -match 'Waiting'}).id
        Invoke-JiraIssueTransition -Issue $issueID -Transition $Transitionswait -Credential $cred -ea Stop
        continue
    }

    $commentBody = "Список сертификатов для тикета $issueID:n"
    foreach ($result in $results) {
        $commentBody += "- Host: $($result.HostName).domain.com, Path: $($result.Patch), Status: $($result.statusofcert)"
    }

    #Write-Host "$commentBody - на закрытие тикета $issueID" -ForegroundColor Green
    Add-JiraIssueComment -Comment $commentBody -Issue $issueID -Credential $cred -VisibleRole "All users" -ea Stop | Out-Null
    Set-JiraIssueLabel -Issue $issueID -Set "success" -Credential $cred -ea Stop
    $Transitions = ((Get-JiraIssue -Issue $issueID -Credential $cred -ea Stop).Transition | Where-Object {$_.Name -match 'ResouleToArchive'}).id
    Invoke-JiraIssueTransition -Issue $issueID -Transition $Transitions -Credential $cred -ea Stop
}
}