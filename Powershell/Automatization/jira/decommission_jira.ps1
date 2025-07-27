#Вывод из эксплуатации машины
#customfield_31571 - FQDN машины    31571                     
#foreach($server in $cat) { .\decommission.ps1 -issue "TASK" -server $server }
#прикрутил массовые выводы по списку из файла
param (
    $issue,
    [string] $server
    ) 
Import-Module ActiveDirectory
Import-Module DhcpServer
Import-Module C:\Common.psm1

#ловим ошибки
#$ErrorLog = "C:\decommission_errors.log"
#try {


$PDC = (Get-ADDomain "domain.com").PDCEmulator

#Трап для всего остального
trap { AdminError $issue "[BOT]Ошибка автоматзации по выводу из эксплуатации" $error[0] }

# Проверка имени в AD
if(!$server) {
    [string] $field = GetJiraField $issue "customfield_31571"
} else {
    [string] $field = $server
}
[string] $name = $field.Split('.')[0]
[string] $comment = @()

$srv = Get-ADComputer -Identity $name -Properties MemberOf -ErrorAction SilentlyContinue # Эта строка сократит количество обращений к AD

if ($srv) {
    [string] $vm = $name + ".hq.qiwi.com" }
else {
    $comment += "Имя ($field) машины указано неверно или уже не существует! Объект не найден в AD."
    UserError -issue $issue -comment $comment -result "false"
}

#Импортирование кредов для vSphere PowerCLI
$vicred = Import-CliXML "C:\cred.xml" -ErrorAction Stop

#Подключение ко всем VPX
Connect-VIServer -Server vpx1.hq.qiwi.com -AllLinked -Credential $vicred

# Проверка имени на VmWare
if (@(Get-VM $vm -ErrorAction SilentlyContinue).Count){
#Выключить тачку на варе 
    if((Get-VM $vm).PowerState -eq "PoweredOn"){
        Shutdown-VMGuest -VM $vm -Confirm:$False
        $comment += "Виртуальная машина $name выключена, дата удаления проставлена.`n"
    }

#Добавить дату удаления на VmWare +90 дней
    $date = (Get-Date).AddDays(90).ToString("dd.MM.yyyy")
    Set-Annotation -Entity $vm -CustomAttribute "delete" -Value $date
}
else {
    $comment += "Машина с именем $name не найдена на VmWare.`n"
    if((Test-NetConnection $field).PingSucceeded) {
        Stop-Computer $field -Force -ErrorAction SilentlyContinue ### Выключит железку, если существует.
        $comment += "Физическая машина $name выключена.`n"
    }
}


#Определяю необходимую OU
$OUpath = $srv.DistinguishedName
$OUpath = $OUpath -replace '^CN=.+?(?<!\\),'

#Проверяю OU на содержание двух групп и объекта компьютер, все остальное обрабатывается руками
Get-ADOrganizationalUnit -Filter * -SearchBase $OUpath -SearchScope Subtree -Server $PDC | ForEach-Object {
	$obj = Get-ADObject -Filter * -SearchBase $_.DistinguishedName -SearchScope 1 -Server $PDC
	if(($obj.ObjectClass -match 'computer' | Measure-Object).Count -eq 1 -and ($obj.ObjectClass -match 'group' | Measure-Object).Count -eq 2 -and ($obj | Measure-Object).Count -eq 3) {
#Перемещаю в OU=TrashComputers,DC=YouOU,DC=com
        Set-ADObject $OUpath -ProtectedFromAccidentalDeletion 0 -Server $PDC
		Move-ADObject -Identity $OUpath -TargetPath "OU=TrashComputers,DC=YouOU,DC=com" -Server $PDC
	}
    else {
        UserError -issue $issue -comment "В *$OUpath* находятся не стандартные объекты!"
    }
}

#Чистим DNS запись
$ip = (Get-DnsServerResourceRecord -ComputerName $PDC -Name $name -ZoneName hq.qiwi.com -ErrorAction SilentlyContinue).RecordData.IPv4Address.IPAddressToString
if($ip){
# Плюсуем комментарий сразу к основной переменной, избавляемся от промежуточных
#    $dnscomment = @() 
#    $dhcpcomment = @()
    foreach($address in $ip){
    $comment += "На DNS удалена А-запись: $($address) = $($name)`n"
    Remove-DnsServerResourceRecord -ComputerName $PDC -Name $name  -ZoneName hq.qiwi.com  -RRType A –Force
    #Чистим DHCP 
        if (get-DhcpServerv4Reservation -ComputerName dhcp01 -IPAddress $address -ErrorAction SilentlyContinue) {
            $scopeid = $address -replace "\d+$","0"
            Remove-DhcpServerv4Reservation -ComputerName dhcp01 -IPAddress $address 
            Start-Sleep 5
            Invoke-DhcpServerv4FailoverReplication -ComputerName dhcp01 -ScopeId $scopeid -Force
            $comment += "$($address) - удален из резервирования`n" 

        }
        else {
            $comment += "$($address) на DHCP не зарезервирован`n"}
    }
}
else {
    $comment += "На DNS нет записи с именем $name`n"
}


if($srv.MemberOf) {
    $srv.MemberOf | Remove-ADGroupMember -Members $srv.SID -Confirm:$false
    #$comment += "Были удалены следующие группы:`n$($srv.MemberOf)" # Да, не имя группы будет, но думаю DN тоже сойдёт.
    $comment += "Были удалены следующие группы:`n$(($srv.MemberOf | % { $_.Split(',')[0].Replace('CN=','') }) -join `"`n`")"
}
Disable-ADAccount $srv.SID -Confirm:$false


setCommentAndResult -issue $issue -comment $comment -result "success"
