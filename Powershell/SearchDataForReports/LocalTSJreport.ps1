$reportFolder = "C:\Scripts\TaskReport"
if (-not (Test-Path $reportFolder)) {
    New-Item -Path $reportFolder -ItemType Directory | Out-Null
}

$hostname = $env:COMPUTERNAME
$taskNames = Get-ScheduledTask | Where-Object { $_.TaskName -match "\[TSJ\]" -or $_.Actions.Execute -match "powershell" } | Select-Object TaskName, Description, Author, @{Name='Execute'; Expression={$_.Actions.Execute}}, @{Name='Arguments'; Expression={$_.Actions.Arguments}}
$allEvents = Get-WinEvent -LogName "Microsoft-Windows-TaskScheduler/Operational" | Where-Object { $_.Id -eq 201 -or $_.Id -eq 202 }

$logData = @()

foreach ($task in $taskNames) {
    $actionString = if ($task.Execute -is [array]) {$task.Execute -join " | "} else {$task.Execute}
    $argumentsString = if ($task.Arguments -is [array]) {$task.Arguments -join " | "} else {$task.Arguments}
    $escapedTask = [regex]::Escape($task.TaskName)
    $eventok = $allEvents | Where-Object { $_.Id -eq 201 -and $_.Message -match $escapedTask }
    $eventneok = $allEvents | Where-Object { $_.Id -eq 202 -and $_.Message -match $escapedTask }
    foreach ($startEvent in $eventok) {

        $logData += [pscustomobject]@{
            HostName    = $hostname
            TaskName    = $task.TaskName
            Status      = $startEvent.TaskDisplayName
            Action      = $actionString 
            Arguments   = $argumentsString
            Author      = $task.Author
            StartTime   = $startEvent.TimeCreated
            EventId     = $startEvent.Id
            Message     = $startEvent.Message
        }
    }

    foreach ($endEvent in $eventneok) {

        $logData += [pscustomobject]@{
            HostName    = $hostname
            TaskName    = $task.TaskName
            Status      = $startEvent.TaskDisplayName
            Action      = $actionString 
            Arguments   = $argumentsString
            Author      = $task.Author
            StartTime   = $endEvent.TimeCreated
            EventId     = $endEvent.Id
            Message     = $endEvent.Message
        }
    }
}
$logData | ConvertTo-Json -Depth 5 | Out-File "$reportFolder\FullTaskLog.json" -Encoding UTF8