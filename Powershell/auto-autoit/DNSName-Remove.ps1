param(
	[Parameter(Mandatory=$True)]
	$NodeToDelete,
	$User,
	$Client
	)

trap {
	Send-MailMessage -From bot@domain.com -To user@domain.com -Subject "[BOT][DNS] Ошибка удаления DNS записи $NodeToDelete" -Body "Сервер: $($env:COMPUTERNAME)`nСкрипт: $($PSCommandPath)`n$($_.Exception.Message)`nСтрока: $($_.InvocationInfo.Line)`nЗапущен пользователем:$($Remote_User)`nС адреса:$($Remote_Addr)" -SmtpServer smtp.domain.com -Priority High -Encoding UTF8
	Break
}
if($NodeToDelete -notmatch "^[A-Za-z0-9-]*$") { Write-Host "Имя содержит недопустимые символы."; Break }

# Оригинальный скрипт https://itblog.ldlnet.net/index.php/2019/01/17/removing-a-dns-a-record-through-powershell/
#$NodeToDelete = "NB557078"
$DNSServer = (Get-ADDomain "domain.com").PDCEmulator
$ZoneName = "hq.qiwi.com"
$NodeDNS = Get-DnsServerResourceRecord -ZoneName $ZoneName -ComputerName $DNSServer -Node $NodeToDelete -RRType A -ErrorAction SilentlyContinue
if(!$NodeDNS){
	Write-Host "Запись $NodeToDelete не найдена в зоне $ZoneName"
} elseif($NodeDNS.Count -gt 3){
	Write-Host "Было найдено более 3-х DNS записей $NodeToDelete - обратись в WIN!"
} else{
	foreach($in in $nodeDNS) {Remove-DnsServerResourceRecord -ZoneName $ZoneName -ComputerName $DNSServer -InputObject $in -Force}
	Send-MailMessage -From bot@domain.com -To user@domain.com -Subject "[BOT][DNS] Успешное удаления DNS записи $NodeToDelete" -Body "Удалена DNS запись $NodeToDelete с адресом(ми) $($NodeDNS.RecordData.IPv4Address -join ', ') в зоне $ZoneName.`nЗадача запущена пользователем:$($Remote_User).`nС адреса:$($Remote_Addr)" -SmtpServer smtp.domain.com -Priority High -Encoding UTF8
	Write-Host "Запись $NodeToDelete уcпешно удалена!"
}
