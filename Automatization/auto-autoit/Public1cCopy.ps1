param(
	[Parameter(Mandatory=$True)]
	[String]$appname
	)
trap {
#	Send-MailMessage -From bot@qiwi.com -To automation_reports@qiwi.com -Subject "[BOT][1C] Ошибка во время публикации базы $appname" -Body "Сервер: $($env:COMPUTERNAME)`nСкрипт: $($PSCommandPath)`n$($_.Exception.Message)`nСтрока: $($_.InvocationInfo.Line)`nЗапущен пользователем:$($Remote_User)`nС адреса:$($Remote_Addr)" -SmtpServer smtp1.osmp.ru -Priority High -Encoding UTF8
#	Send-MailMessage -From bot@qiwi.com -To d.odintsov@qiwi.com -Subject "[BOT][1C] Ошибка во время публикации базы $appname" -Body "Сервер: $($env:COMPUTERNAME)`nСкрипт: $($PSCommandPath)`n$($_.Exception.Message)`nСтрока: $($_.InvocationInfo.Line)`nЗапущен пользователем:$($Remote_User)`nС адреса:$($Remote_Addr)" -SmtpServer smtp1.osmp.ru -Priority High -Encoding UTF8
Break
}
$Date = Get-Date
#хост на котором происходит публикация
$hosts = "host.domain.com"
$appPath = "C:\inetpub\wwwroot\$appname"
$poolName = "8.3.24.1586"
if($appname -match "appname"){
Write-Host "Отработал шаблон по: appname"
$params = @(
    "-publish",
    "-iis",
    "-wsdir", $appname,
    "-dir", $appPath,
    "-connstr", "Srvr=yoursrv.domain.com:1543;Ref=$appname;",
    "-descriptor", '"C:\Шаблоны публикаций 1С\ШаблонДляБД.vrd"'
)
}elseif($appname -match "appname") {
Write-Host "Отработал шаблон по: appname"
$params = @(
    "-publish",
    "-iis",
    "-wsdir", $appname,
    "-dir", $appPath,
    "-connstr", "Srvr=yoursrv.domain.com:1544;Ref=$appname;",
    "-descriptor", '"C:\Шаблоны публикаций 1С\ШаблонДляБД.vrd"'
)
}elseif($appname -match "appname") {
Write-Host "Отработал шаблон по: appname"
$params = @(
    "-publish",
    "-iis",
    "-wsdir", $appname,
    "-dir", $appPath,
    "-connstr", "Srvr=yoursrv.domain.com:1544;Ref=$appname;",
    "-descriptor", '"C:\Шаблоны публикаций 1С\ШаблонДляБД.vrd"'
)
}elseif($appname -match "appname") {
Write-Host "Отработал шаблон по: appname"
$params = @(
    "-publish",
    "-iis",
    "-wsdir", $appname,
    "-dir", $appPath,
    "-connstr", "Srvr=yoursrv.domain.com:1544;Ref=$appname;",
    "-descriptor", '"C:\Шаблоны публикаций 1С\ШаблонДляБД.vrd"'
)
}elseif($appname -match "appname") {
Write-Host "Отработал шаблон по: appname"
$params = @(
    "-publish",
    "-iis",
    "-wsdir", $appname,
    "-dir", $appPath,
    "-connstr", "Srvr=yoursrv.domain.com:1542;Ref=$appname;",
    "-descriptor", '"C:\Шаблоны публикаций 1С\ШаблонДляБД.vrd"'
)
}elseif($appname -match "appname") {
Write-Host "Отработал шаблон по: appname"
$params = @(
    "-publish",
    "-iis",
    "-wsdir", $appname,
    "-dir", $appPath,
    "-connstr", "Srvr=yoursrv.domain.com:1544;Ref=$appname;",
    "-descriptor", '"C:\Шаблоны публикаций 1С\ШаблонДляБД.vrd"'
)
}elseif($appname -match "appname") {
Write-Host "Отработал шаблон по: appname"
$params = @(
    "-publish",
    "-iis",
    "-wsdir", $appname,
    "-dir", $appPath,
    "-connstr", "Srvr=yoursrv.domain.com:1544;Ref=$appname;",
    "-descriptor", '"C:\Шаблоны публикаций 1С\ШаблонДляБД.vrd"'
)
}elseif($appname -match "appname") {
Write-Host "Отработал шаблон по: appname"
$params = @(
    "-publish",
    "-iis",
    "-wsdir", $appname,
    "-dir", $appPath,
    "-connstr", "Srvr=yoursrv.domain.com:1544;Ref=$appname;",
    "-descriptor", '"C:\Шаблоны публикаций 1С\ШаблонДляБД.vrd"'
)
}elseif($appname -match "appname") {
Write-Host "Отработал шаблон по: appname"
$params = @(
    "-publish",
    "-iis",
    "-wsdir", $appname,
    "-dir", $appPath,
    "-connstr", "Srvr=yoursrv.domain.com:1542;Ref=$appname;",
    "-descriptor", '"C:\Шаблоны публикаций 1С\ШаблонДляБД.vrd"'
)
}elseif($appname -match "appname") {
Write-Host "Отработал шаблон по: appname"
$params = @(
    "-publish",
    "-iis",
    "-wsdir", $appname,
    "-dir", $appPath,
    "-connstr", "Srvr=yoursrv.domain.com:1542;Ref=$appname;",
    "-descriptor", '"C:\Шаблоны публикаций 1С\ШаблонДляБД.vrd"'
)
}elseif($appname -match "appname") {
Write-Host "Отработал шаблон по: appname"
$params = @(
    "-publish",
    "-iis",
    "-wsdir", $appname,
    "-dir", $appPath,
    "-connstr", "yoursrv.domain.com:1543;Ref=$appname;",
    "-descriptor", '"C:\Шаблоны публикаций 1С\ШаблонДляБД.vrd"'
)
}elseif($appname -match "appname") {
Write-Host "Отработал шаблон по: appname"
$params = @(
    "-publish",
    "-iis",
    "-wsdir", $appname,
    "-dir", $appPath,
    "-connstr", "Srvr=yoursrv.domain.com:1544;Ref=$appname;",
    "-descriptor", '"C:\Шаблоны публикаций 1С\ШаблонДляБД.vrd"'
)
}elseif($appname -match "appname") {
Write-Host "Отработал шаблон по: appname"
$params = @(
    "-publish",
    "-iis",
    "-wsdir", $appname,
    "-dir", $appPath,
    "-connstr", "Srvr=yoursrv.domain.com:1546;Ref=$appname;",
    "-descriptor", '"C:\Шаблоны публикаций 1С\ШаблонДляБД.vrd"'
)
}
else{
write-host "Совпадений не обнаружено"}
$cleanResults = @()
try{
    $result = Invoke-Command -ComputerName $hosts -ScriptBlock {
    param($params,$appname, $appPath, $hosts)
    #& "fC:\Program Files\1cv8\8.3.24.1586\bin\webinst.exe" @params
    Start-Process -FilePath "C:\Program Files\1cv8\8.3.24.1586\bin\webinst.exe" -ArgumentList $using:params -Wait -NoNewWindow
    $vrdFile = "C:\inetpub\wwwroot\$appname\default.vrd"
    (Get-Content $vrdFile -Raw) -replace 'ib="Srvr=([^;]+);Ref=([^;]+);"', 'ib="Srvr=&quot;$1&quot;;Ref=&quot;$2&quot;;"' | Set-Content $vrdFile
    Start-Process -FilePath "C:\Windows\System32\inetsrv\appcmd.exe" -ArgumentList "set app `"Default Web Site/$using:appname`" /applicationPool:`"$using:poolName`"" -NoNewWindow -Wait
    Start-Process -FilePath "C:\Windows\System32\inetsrv\appcmd.exe" -ArgumentList "recycle apppool `"$using:poolName`"" -NoNewWindow -Wait

    $staleFiles = Get-ChildItem -Path $appPath -File | Where-Object {
        ($Date - $_.LastWriteTime).TotalMinutes -gt 5
    }
    if ($staleFiles.Count -gt 0) {
        Write-Host "Есть файлы старше 5 минут" -ForegroundColor Red
    } else {
        Write-Host "Все файлы обновлены успешно`nСсылка на ресурс:`nhttps://$($hosts)/$($appname)" -ForegroundColor Green
    }
    } -ArgumentList $params, $appname, $appPath, $hosts
    if ($result) {
       $cleanResults += $result
    }
    Write-Host $cleanResults
    }
catch{Write-Host "Не смог подключиться к хосту $($hosts)" -ForegroundColor Red}

