$hosts = (Get-ADComputer -Filter "Enabled -eq 'True'" -SearchBase "OU=YOUROU,DC=Domain,DC=com").Name
$remotePath = "C$\Scripts\TaskReport\FullTaskLog.json"
$sqlServer = "SQLDB.Domain.com"
$database = "reportTest"
$reportLogTable = "TaskSchedulerLogs"
$connectionLogTable = "ConnectionLog"

$hosts | ForEach-Object -Parallel {
    function FixEncoding {
    param([string]$inputString)
    try {
        if ($inputString -match "^[ -~А-Яа-яЁё]*$") {
            return $inputString
        }
        
        $bytes = [System.Text.Encoding]::Default.GetBytes($inputString)
        return [System.Text.Encoding]::UTF8.GetString($bytes)
    }
    catch {
        return $inputString
    }
}

function WriteLogToDB {
    param(
        [string]$query,
        [string]$sqlServer,
        [string]$database
    )
    try {
        $connectionString = "Server=$sqlServer;Database=$database;Integrated Security=SSPI;"
        $connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        $connection.Open()
        $result = $command.ExecuteScalar()
        $connection.Close()
        return [int]$result
    }
    catch {
        Write-Error "Ошибка при записи в БД: $_"
        return -1
    }
}
    $localhost = $_
    $remotePath = $using:remotePath
    $sqlServer = $using:sqlServer
    $database = $using:database
    $reportLogTable = $using:reportLogTable
    $connectionLogTable = $using:connectionLogTable

    $fullPath = "\\$($localhost)\$remotePath"
    $connectionStatus = "Success"
    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    try {
        if (-not (Test-Connection -ComputerName $localhost -Count 1 -Quiet)) {
            $connectionStatus = "HostUnreachable"
            $successCount = 0
            throw "Хост $($localhost) недоступен"
        }

        if (Test-Path $fullPath) {
            $jsonContent = Get-Content $fullPath -Raw -Encoding UTF8
            $exclusions = Get-Content -Path 'C:\SerchServersDataExclude.txt' | Where-Object { $_ -ne "" }
            $exclusionPattern = ($exclusions | ForEach-Object { [regex]::Escape($_) }) -join '|'
            $json = $jsonContent | ConvertFrom-Json | Where-Object {$_.TaskName -notmatch $exclusionPattern}
            $successCount = 0

            foreach ($entry in $json) {
                try {
                    # Обработка с проверкой кодировки для русских символов
                    $hostName = if ($null -ne $entry.HostName -and $entry.HostName) {FixEncoding $entry.HostName.Replace("'", "''")} else { 'Unknown' }
                    $taskName = if ($null -ne $entry.TaskName -and $entry.TaskName) {FixEncoding $entry.TaskName.Replace("'", "''")} else { 'Unknown' }
                    $status = if ($null -ne $entry.Status -and $entry.Status) {FixEncoding $entry.Status.Replace("'", "''")} else { 'Unknown' }
                    $action = if ($null -ne $entry.Action -and $entry.Action) {FixEncoding $entry.Action.Replace("'", "''")} else { 'Unknown' }
                    $arguments = if ($null -ne $entry.Arguments -and $entry.Arguments) {FixEncoding $entry.Arguments.Replace("'", "''")} else { 'Unknown' }
                    $author = if ($null -ne $entry.Author -and $entry.Author) {FixEncoding $entry.Author.Replace("'", "''")} else { 'Unknown' }
                    if ($null -eq $entry.StartTime -or -not $entry.StartTime) {throw "StartTime is null or empty"}
                    $startTime = [DateTime]::Parse($entry.StartTime, [Globalization.CultureInfo]::InvariantCulture)
                    $eventId = if ($null -ne $entry.EventId -and $entry.EventId -ge 0) { $entry.EventId } else { 0 }
                    $message = if ($null -ne $entry.Message -and $entry.Message) {FixEncoding $entry.Message.Replace("'", "''")} else { '' }
                    $query = @"
IF NOT EXISTS (
    SELECT 1 FROM $reportLogTable
    WHERE HostName = '$hostName' AND TaskName = '$taskName' AND StartTime = '$($startTime.ToString("yyyy-MM-dd HH:mm:ss"))'
)
BEGIN
    INSERT INTO $reportLogTable (
        HostName, 
        TaskName,
        Status,
        Action,
        Arguments,
        Author,
        StartTime,  
        EventId, 
        Message
    )
    VALUES (
        '$hostName', 
        '$taskName',
        '$status',
        '$action',
        '$arguments',
        '$author',
        '$($startTime.ToString("yyyy-MM-dd HH:mm:ss"))',
        $eventId, 
        '$message'
    );
    SELECT 1;
END
ELSE
    SELECT 0;
"@
                $result = WriteLogToDB -query $query -sqlServer $sqlServer -database $database
                if ($result -eq 1) {
                    $successCount++
                } elseif ($result -eq -1) {
                    throw "Ошибка записи в БД"
                }
                }
                catch {
                    Write-Warning "Ошибка обработки записи на хосте $localhost : $_"
                    Write-Warning "Проблемная запись: $($entry | ConvertTo-Json -Depth 3)"
                    $connectionStatus = "DataError: $($_.Exception.Message)"
                    continue
                }
            }

            if ($successCount -gt 0) {
                Remove-Item $fullPath -Force -ErrorAction SilentlyContinue
                $connectionStatus = "Success ($successCount new records)"
            } else {
                Remove-Item $fullPath -Force -ErrorAction SilentlyContinue
                $connectionStatus = "New records wos not add"
                $successCount = 0
            }
        }
        else {
            $connectionStatus = "FileNotFound"
            $successCount = 0
        }
    }
    catch {
        $connectionStatus = "Error: $($_.Exception.Message)"
        Write-Error "Ошибка при обработке хоста $($localhost) : $_"
    }
    finally {
        $logQuery = "INSERT INTO $connectionLogTable (HostName, CheckedAt, Status, NewValueCount) VALUES ('$($localhost)', '$now', '$connectionStatus', $successCount)"
        WriteLogToDB -query $logQuery -sqlServer $sqlServer -database $database | Out-Null
    }
} -ThrottleLimit 20