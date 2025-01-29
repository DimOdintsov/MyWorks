$serv = Hostname
[string] $logname = $serv.Split('.')[0]
$LogFile = "C:\Windows\Temp\$($logname)_UppateLog_$($(Get-Date -Format "yyyy-MM-dd")).txt"
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "$timestamp - $Message"
}
#Write-Host "Начинаем процесс проверки UpTime и выводим список последних обновлний хоста, каждый пук логируется"
Write-Log "Начинаем процесс проверки UpTime и выводим список последних обновлний хоста"
$osInfo = Get-WmiObject win32_operatingsystem | Select-Object csname, 
      @{LABEL=’LastBootUpTime’; EXPRESSION={$_.ConvertToDateTime($_.lastbootuptime)}},
      @{LABEL='DaysSinceLastBoot'; EXPRESSION={
          $lastBoot = $_.ConvertToDateTime($_.lastbootuptime)
          $currentTime = Get-Date
          $diff = $currentTime - $lastBoot
          [math]::Round($diff.TotalDays, 1)
      }}
$updates = Get-WmiObject -Class win32_quickfixengineering | Select-Object Description, InstalledOn, HotFixID | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Description) } | Sort-Object InstalledOn -Descending |Select-Object -First 3
$lastUpdate = $updates | Sort-Object InstalledOn -Descending |Select-Object -First 1
#Write-Host "`nPSComputerName: $($osInfo.csname)" "`nLastBootUpTime: $($osInfo.LastBootUpTime)" "`nDaysSinceLastBoot: $($osInfo.DaysSinceLastBoot)"
Write-Log "`nPSComputerName: $($osInfo.csname)"
Write-Log "`nLastBootUpTime: $($osInfo.LastBootUpTime)"
Write-Log "`nDaysSinceLastBoot: $($osInfo.DaysSinceLastBoot)"
Write-Log "Список обнов: "
foreach ($update in $updates) {
    #Write-Host "Description: $($update.Description)" "|" "InstalledOn: $($update.InstalledOn)" "|" "HotFixID: $($update.HotFixID)"
    Write-Log "Description: $($($update.Description)) | InstalledOn: $($($update.InstalledOn)) | HotFixID: $($($update.HotFixID))"

}
<#
if ($osInfo.LastBootUpTime -gt 100){ ########################### gt
    #Write-host "тут будет код о том что проблема с аптаймом и искать решение"
    try{
    if (@(Get-ADComputer $serv -ErrorAction SilentlyContinue).Count){
    $groups = Get-ADComputer $serv -Properties MemberOf -ErrorAction SilentlyContinue | Select-Object -ExpandProperty MemberOf |ForEach-Object {Get-ADGroup $_ -Properties SamAccountname} |Select-Object -ExpandProperty SamAccountname
    #Write-Host "Данный хост находится в:`n_"
    Write-Log "Данный хост находится в:"
    foreach ($grouplist in $groups) {
      #Write-Host "$($grouplist)"
      Write-Log "$($grouplist)"
    }
     #Write-Host "Просьба внимательно обратить внимание на группы UPD-*"
     Write-Log "Просьба внимательно обратить внимание на группы UPD-*"
     }
     }catch{Write-Log "Ошибка во время выполнения Get-Adcomputer $_"}
}
#>
#foreach($update in $lastUpdate.InstalledOn){

    if (($null -eq $update.InstalledOn) -or ([datetime]$update.InstalledOn -lt (Get-Date).AddDays(-60))){######################## lt 60
    #Write-Host "тут следующая логика по проверке групп, обнов, сервера обнов, передергиванию..... и сервисов тоже"
        #Ласт установка была больше 60 назад
        #Write-Host "На данном хосте обновы не устанавливались более 60 дней, запускаем процедуру проверки хоста"
        Write-Log "На данном хосте обновы не устанавливались более 60 дней или ни разу, запускаем процедуру проверки хоста, свободного места и тп"
        

        $regedit = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -ErrorAction SilentlyContinue
        if ($regedit.UseWUServer -eq 1){
        #Write-Host "Данный хост использует обновления из Wsus"
        Write-Log "Данный хост использует обновления из Wsus"
        }
        $freeSpace = Get-WmiObject -Class Win32_LogicalDisk |Where-Object {$_.DeviceID -eq "C:"} |Select-Object -Property @{Name="FreeSpaceGB"; Expression={[math]::Round($_.FreeSpace / 1GB, 2)}} | Select-Object -ExpandProperty FreeSpaceGB
        $alertforspace = @()
        if($freeSpace -lt 12){
            Write-log "На данном хосте слишком мало свободного пространства $($freeSpace) по этому выполнение кода останавливаем."
            #Write-Host "На данном хосте слишком мало свободного пространства $($freeSpace) по этому выполнение кода останавливаем. Нужно сделать алерт на ПЯ. Попробуем почистить"
            Copy-Item -Path "\\cm01.hq.qiwi.com\PatchConnectPlusApplications\myFolder\Start-WindowsCleanup.ps1" -Recurse -Destination "C:\Windows\Temp\" -force
            #Write-host "В процессе реализации"

            [int]$a = 0
            $alertforspace+= $a
            #break #Если тру, данный код прекращает выполняться
        }else {
            [int]$a = 1
            $alertforspace = $a
            Write-Log "Возвращаем 1 после проверки доступного пространства на диске"}

        if ($alertforspace -eq 1){
                
                #Write-host "1 циклы обновлений винды"
                Write-log "вернулось 1 запускаем циклы обновлений винды"
                $attempts = 0
                $maxAttempts = 2 # Максимальное количество попыток

                do {
                    try {
                    $attempts++
                    Write-Log "Попытка $attempts из $maxAttempts..."

                            if (-not (Get-Module -Name PSWindowsUpdate -ListAvailable)) {
                            Copy-Item -Path "\\cm01.hq.qiwi.com\PatchConnectPlusApplications\myFolder\Updates\PSWindowsUpdate" -Recurse -Destination "C:\Program Files\WindowsPowerShell\Modules\" -force
                            Write-log "Перенос - ок PSWindowsUpdate"
                            Import-Module -Name PSWindowsUpdate
                            Write-Log "Модуль PSWindowsUpdate импортирован успешно."
                            } else {
                                 Write-Log "Модуль PSWindowsUpdate уже установлен."
                            }
                            #Copy-Item -Path "\\cm01.hq.qiwi.com\PatchConnectPlusApplications\myFolder\Updates\PSWindowsUpdate" -Recurse -Destination "C:\Program Files\WindowsPowerShell\Modules\" -force
                            #Write-log "Перенос - ок PSWindowsUpdate"

                            #Import-Module -Name "C:\Program Files\WindowsPowerShell\Modules\PSWindowsUpdate"
                            #Write-log "import was OK"
                            Write-log "Начинаем поиск обнов для хоста"
                            $updates = Get-WindowsUpdate
                            if($updates.Count -eq 0){
                                Write-Log "Нет доступных обновлений."
                            }else{
                            Write-log "найденные обновления:`n"
                            foreach ($i in $updates) {
                                #Write-Host "$($i.KB) $($i.Size) $($i.Title)"
                                Write-Log "$($i.KB) $($i.Size) $($i.Title)"
                            }
                            $installupdates = Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot
                            Write-Log "Загруженные и установленные обновления (может быть пустой список:`n"
                            foreach ($i in $installupdates) {
                                #Write-Host "$($i.KB) $($i.Size) $($i.Title)"
                                Write-Log "$($i.KB) $($i.Size) $($i.Title)"
                            }
                            $updates = Get-WmiObject -Class win32_quickfixengineering | Select-Object Description, InstalledOn, HotFixID | Where-Object { -not [string]::IsNullOrWhiteSpace($_.Description) } | Sort-Object InstalledOn -Descending |Select-Object -First 3
                            Write-Log "Выводим список из последних 3-х обнов установленных на хост:`n"
                            foreach ($update in $updates) {
                                #Write-Host "Description: $($($update.Description)) | InstalledOn: $($($update.InstalledOn)) | HotFixID: $($($update.HotFixID))"
                                Write-Log "Description: $($($update.Description)) | InstalledOn: $($($update.InstalledOn)) | HotFixID: $($($update.HotFixID))"
                            }
                            }
                            Write-Log "Sucess"
                            $restartNeeded = $true
                        break
                    }catch{
                        Write-log "Произошла ошибка: $($_.Exception.Message)"
                        Write-Log "Stack Trace: $($_.Exception.StackTrace)"
                        if ($attempts -lt $maxAttempts) {
                            Write-log "Перезапускаем служб Windows Update и пробуем снова..."                        
                            Restart-Service -Name wuauserv, BITS, CryptSvc, msiserver, AppIDSvc, WaaSMedicSvc -Force
                        } else {
                            Write-log "Достигнуто максимальное количество попыток. Завершение."
                            Write-Log "Error Message: $($_.Exception.Message)"
                            Write-Log "Stack Trace: $($_.Exception.StackTrace)"
                        throw
                        }
                    }
                    } while ($attempts -lt $maxAttempts)
            }
    }else {Write-Log "На данном хосте обновы устанавливались ранее 60 дней назад,запускаем проверку свободного места и тп"}
    
if ($restartNeeded) {
    Write-Log "Initiating system restart..."
    Start-Sleep -Seconds 5  # Даем время на завершение логирования
    Restart-Computer -Force
}