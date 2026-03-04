$sqlServer = "sqlserver"
$database = "darabase"

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
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
        $table   = New-Object System.Data.DataTable
        [void]$adapter.Fill($table)
        return $table
    }
    catch {
        Write-Error "$_"
        return 0
    }
    finally {
        if ($connection) { $connection.Close(); $connection.Dispose() }
    }
}
$query = @"
SELECT 
    enc.SerialNumber0 AS [SerialNumber],
    tsp.Name AS [TaskSequence],
    CONVERT(SMALLDATETIME, stat.LastStatusTime) AS [Datefinish]
FROM v_ClientAdvertisementStatus stat
JOIN v_Advertisement adv ON stat.AdvertisementID = adv.AdvertisementID
JOIN v_TaskSequencePackage tsp ON adv.PackageID = tsp.PackageID
LEFT  JOIN v_R_System rs ON stat.ResourceID = rs.ResourceID
LEFT  JOIN v_GS_SYSTEM_ENCLOSURE enc ON enc.ResourceID = stat.ResourceID
WHERE stat.AdvertisementID IN (
    'AdvertisementID',
	'AdvertisementID',
	'AdvertisementID',
	'AdvertisementID'
)
AND stat.LastStateName = 'Succeeded'
AND stat.LastStatusTime >= DATEADD(day, -7, GETDATE()) -- Comment this line if don't need -7 days
ORDER BY stat.LastStatusTime DESC, rs.Netbios_Name0;
"@
$result = WriteLogToDB -query $query -sqlServer $sqlServer -database $database
$result | Format-Table -AutoSize