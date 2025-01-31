#Вывод из эксплуатации машины
#customfield_31571 - FQDN машины                 

param ($issue) 
Import-Module ActiveDirectory
Import-Module DhcpServer
Import-Module C:\Scripts\Jira\Common.psm1

$PDC = (Get-ADDomain "domain.com").PDCEmulator

#Трап для всего остального
trap { AdminError $issue "[BOT]Ошибка автоматзации по выводу из эксплуатации" $error[0] }

# Проверка имени в AD
[string] $field = GetJiraField $issue "customfield_31571"
[string] $name = $field.Split('.')[0]
try{
if (@(Get-ADComputer -Identity $name -ErrorAction SilentlyContinue).Count){[string] $vm = $name + ".domain.com" }}
catch{
$comment = "Имя ($field) машины указано неверно или уже не существует! Объект не найден в AD."
#setCommentAndResult -issue $issue -comment $comment -result "false"
UserError -issue $issue -comment $comment -result "false"
exit
}

#Импортирование кредов для vSphere PowerCLI
$vicred = Import-CliXML "C:\Scripts\Jira\vicred.xml" -ErrorAction Stop

#Подключение ко всем VPX
Connect-VIServer -Server vpx1.domain.com -AllLinked -Credential $vicred

# Проверка имени на VmWare
if (@(Get-VM $vm -ErrorAction SilentlyContinue).Count){
#Выключить тачку на варе 
    if((Get-VM $vm).PowerState -eq "PoweredOn"){
        Shutdown-VMGuest -VM $vm -Confirm:$False
    }

#Добавить дату удаления на VmWare +90 дней
    $date = (Get-Date).AddDays(90).ToString("dd.MM.yyyy")
    Set-Annotation -Entity $vm -CustomAttribute "delete" -Value $date
}
else {
$comment = "Машина с таким именем не найдена на VmWare. Автоматизация прервана."
setCommentAndResult -issue $issue -comment $comment -result "false"
exit
}




#Определяю необходимую OU
$OUpath = (Get-ADComputer $name).DistinguishedName
$OUpath = $OUpath -replace '^CN=.+?(?<!\\),'

#Проверяю OU на содержание двух групп и объекта компьютер, все остальное обрабатывается руками
Get-ADOrganizationalUnit -Filter * -SearchBase $OUpath -SearchScope Subtree -Server $PDC | ForEach-Object {
	$obj = Get-ADObject -Filter * -SearchBase $_.DistinguishedName -SearchScope 1 -Server $PDC
	if(($obj.ObjectClass -match 'computer' | Measure-Object).Count -eq 1 -and ($obj.ObjectClass -match 'group' | Measure-Object).Count -eq 2 -and ($obj | Measure-Object).Count -eq 3) {
#Перемещаю в OU=TrashComputers,DC=hq,DC=qiwi,DC=com
        Set-ADObject $OUpath -ProtectedFromAccidentalDeletion 0 -Server $PDC
		Move-ADObject -Identity $OUpath -TargetPath "OU=TrashComputers,DC=hq,DC=qiwi,DC=com" -Server $PDC
	}
    else {UserError -issue $issue -comment "В *$OUpath* находятся не стандартные объекты!"}
}

#Чистим DNS запись
$ip = (Get-DnsServerResourceRecord -ComputerName $PDC -Name $name -ZoneName hq.qiwi.com -ErrorAction SilentlyContinue).RecordData.IPv4Address.IPAddressToString
if($ip){
    $dnscomment = @()
    $dhcpcomment = @()
    foreach($address in $ip){
    $dnscomment =$dnscomment + "На DNS удалена А-запись: " + $address +" = " + $name + "`n"
    Remove-DnsServerResourceRecord -ComputerName $PDC -Name $name  -ZoneName hq.qiwi.com  -RRType A –Force
    #Чистим DHCP 
        if (get-DhcpServerv4Reservation -ComputerName dhcp01 -IPAddress $address -ErrorAction SilentlyContinue) {
            $scopeid = $address -replace "\d+$","0"
            Remove-DhcpServerv4Reservation -ComputerName dhcp01 -IPAddress $address 
            Start-Sleep 5
            Invoke-DhcpServerv4FailoverReplication -ComputerName dhcp01 -ScopeId $scopeid -Force
            $dhcpcomment = $dhcpcomment + $address +" - удален из резервирования`n" 

        }
        else {$dhcpcomment = $dhcpcomment + $address + " на DHCP не зарезервирован`n"}
    }
}
else {$dnscomment = "На DNS нет записи с именем машины`n"}

#Чистим группы машины
$srv = Get-ADComputer $name
$groups = Get-ADPrincipalGroupMembership -Identity $srv   | Where-Object {$_.name -notmatch "Domain Computers"}| select-object Name,distinguishedName
 
Remove-ADPrincipalGroupMembership -Identity $srv -MemberOf $groups.distinguishedName -Confirm:$false -Server $PDC

#Сообщение в Jira

$comment = "Машина $name выключена, дата удаления проставлена.`n"
$comment = $comment + $dnscomment
$comment = $comment + $dhcpcomment
$comment = $comment + "Были удалены следующие группы:`n"
$comment = $comment + $groups.Name



setCommentAndResult -issue $issue -comment $comment -result "success"