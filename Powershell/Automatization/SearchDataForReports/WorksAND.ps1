Set-JiraConfigServer -Server "https://YOURJIRA.domain.com"
$cred = Import-CliXml -Path 'C:\YOUR_cred.xml' -ea Stop
#Списки юзеров для поиска
$win = @("i.ivanov", "i.ivanov", "i.ivanov", "i.ivanov")
$sql = @("a.ivanov", "a.ivanov", "a.ivanov")
$adm1c = @("q.ivanov", "q.ivanov")
#списки БД
$sqlServer = "SQLDB.Domain.com"
$database = "reportTest"
$reportwin = "JiraWORKSWin"
$reportsql = "JiraWORKSsql"
$reportcommon = "JiracommonWORKS"
$reportlog = "JiraWORKSlog"
#функция для записи в БД
function Write-LogToDB {
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
#обработка ****
foreach($user in $win){
    $newEntries = 0
    $status = "Success"
    try {
        $issues = Get-JiraIssue -Query "project in (PROJECT) AND status = Closed AND status changed from 'In Progress' to Monitoring by ($user) after '2025/05/01'" -Credential $cred | 
                  Select-Object Key, Status, @{Name="Resolution"; Expression={$_.resolution.name}}, Created, resolutiondate
        
        if($issues){
            foreach($issue in $issues){
                $query = @"
IF NOT EXISTS (SELECT 1 FROM $reportwin WHERE Issue = '$($issue.Key)' AND username = '$user')
BEGIN
    INSERT INTO $reportwin (username, Issue, Status, Resolution, Created, resolutiondate)
    VALUES (
        '$user',
        '$($issue.Key)',
        '$($issue.Status)',
        '$($issue.Resolution)',
        '$($issue.Created.ToString("yyyy-MM-dd HH:mm:ss"))', 
        '$($issue.resolutiondate.ToString("yyyy-MM-dd HH:mm:ss"))')
        
    SELECT 1
END
ELSE
    SELECT 0
"@
                $result = Write-LogToDB -query $query -sqlServer $sqlServer -database $database
                if($result -eq 1) { 
                    $newEntries++ 
                }
                elseif($result -eq -1) {
                    throw "Error write to DB issue $($issue.Key)"
                }
            }
            
            Write-Host "Add $newEntries new values for $user (PROJECT)"
        }
        else {
            $status = "No issues found"
            Write-Host "For user $user do not have issues (PROJECT)"
        }
    }
    catch {
        $status = "Error: $($_.Exception.Message)"
        Write-Error "Error with user $user : $_"
    }
    finally {
        $logQuery = @"
INSERT INTO $reportlog (TableName, UserName,Status, NewValueCount, Date)
VALUES ('$reportwin', '$user','$status', $newEntries, GETDATE())
"@
        Write-LogToDB -query $logQuery -sqlServer $sqlServer -database $database | Out-Null
    }
}
#обработка SQL
foreach($user in $sql){
    $newEntries = 0
    $status = "Success"
    
    try {
        $issues = Get-JiraIssue -Query "project in (PROJECT) AND status = Closed AND status changed from 'In Progress' to Monitoring by ($user) after '2025/05/01'" -Credential $cred | 
                  Select-Object Key, Status, @{Name="Resolution"; Expression={$_.resolution.name}}, Created, resolutiondate
        
        if($issues){
            foreach($issue in $issues){
                $query = @"
IF NOT EXISTS (SELECT 1 FROM $reportsql WHERE Issue = '$($issue.Key)' AND username = '$user')
BEGIN
    INSERT INTO $reportsql (username, Issue, Status, Resolution, Created, resolutiondate)
    VALUES (
        '$user',
        '$($issue.Key)',
        '$($issue.Status)',
        '$($issue.Resolution)',
        '$($issue.Created.ToString("yyyy-MM-dd HH:mm:ss"))', 
        '$($issue.resolutiondate.ToString("yyyy-MM-dd HH:mm:ss"))')
        
    SELECT 1
END
ELSE
    SELECT 0
"@
                $result = Write-LogToDB -query $query -sqlServer $sqlServer -database $database
                if($result -eq 1) { 
                    $newEntries++ 
                }
                elseif($result -eq -1) {
                    throw "Error write to DB issue $($issue.Key)"
                }
            }
            
            Write-Host "Add $newEntries new values for $user (PROJECT)"
        }
        else {
            $status = "No issues found"
            Write-Host "For user $user do not have issues (PROJECT)"
        }
    }
    catch {
        $status = "Error: $($_.Exception.Message)"
        Write-Error "Error with user $user : $_"
    }
    finally {
        $logQuery = @"
INSERT INTO $reportlog (TableName, UserName,Status, NewValueCount, Date)
VALUES ('$reportsql', '$user','$status', $newEntries, GETDATE())
"@
        Write-LogToDB -query $logQuery -sqlServer $sqlServer -database $database | Out-Null
    }
}
#Common PROJECT
$ourteam = $win + $sql + $adm1c
foreach($user in $ourteam){
    $newEntries = 0
    $status = "Success"
    
    try {
        $issues = Get-JiraIssue -Query "project in (PROJECT, PROJECT) AND status = Closed AND status changed from 'In Progress' to Monitoring by ($user) after '2025/05/01'" -Credential $cred | 
                  Select-Object Key, Status, @{Name="Resolution"; Expression={$_.resolution.name}}, Created, resolutiondate
        
        if($issues){
            foreach($issue in $issues){
                $query = @"
IF NOT EXISTS (SELECT 1 FROM $reportcommon WHERE Issue = '$($issue.Key)' AND username = '$user')
BEGIN
    INSERT INTO $reportcommon (username, Issue, Status, Resolution, Created, resolutiondate)
    VALUES (
        '$user',
        '$($issue.Key)',
        '$($issue.Status)',
        '$($issue.Resolution)',
        '$($issue.Created.ToString("yyyy-MM-dd HH:mm:ss"))', 
        '$($issue.resolutiondate.ToString("yyyy-MM-dd HH:mm:ss"))')
        
    SELECT 1
END
ELSE
    SELECT 0
"@
                $result = Write-LogToDB -query $query -sqlServer $sqlServer -database $database
                if($result -eq 1) { 
                    $newEntries++ 
                }
                elseif($result -eq -1) {
                    throw "Error write to DB issue $($issue.Key)"
                }
            }
            
            Write-Host "Add $newEntries new values for $user (Common)"
        }
        else {
            $status = "No issues found"
            Write-Host "For user $user do not have issues (Common)"
        }
    }
    catch {
        $status = "Error: $($_.Exception.Message)"
        Write-Error "Error with user $user : $_"
    }
    finally {
        $logQuery = @"
INSERT INTO $reportlog (TableName, UserName,Status, NewValueCount, Date)
VALUES ('$reportcommon', '$user','$status', $newEntries, GETDATE())
"@
        Write-LogToDB -query $logQuery -sqlServer $sqlServer -database $database | Out-Null
    }
}