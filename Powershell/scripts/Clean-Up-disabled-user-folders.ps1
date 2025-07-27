<#
#Перепроверка для себя если нужно
# Получаем все вложенные папки
$folders = Get-ChildItem "M:\Old" -Directory -Exclude "_BackedUp", "_Orphaned"| Select-Object Name


#Перебираем все папки из переменной
foreach ($user in $folders) 
{
   $date = (Get-Date).AddDays(-90)
   Get-ADuser -Identity $user.Name -Properties whenchanged, Enabled | Where-Object {$_.whenchanged -lt $date -and $_.Enabled -eq 0} | select samaccountname, whenchanged,Enabled
}

#>


# Получаем все вложенные папки
$folders = Get-ChildItem "M:\Old" -Directory -Exclude "_BackedUp", "_Orphaned"| Select-Object Name

$sourceDirectory = "M:\Old"

#Перебираем все папки из переменной
foreach ($user in $folders) 
{
   $date = (Get-Date).AddDays(-90)
   $a = Get-ADuser -Identity $user.Name -Properties whenchanged, Enabled | Where-Object {$_.whenchanged -lt $date -and $_.Enabled -eq 0} | select samaccountname # делаем поиск юзера по имени папки в ад, проверяем что уз отключена
   $a.SamAccountName -split "`r`n" | Where-Object { $_ -match '\S' } #убираем срезы в полученном списке
   $sourceFolderPath = Get-ChildItem $sourceDirectory -Directory | Where-Object { $_.Name -eq $a.Samaccountname } # сканируем директорию список полученным из ад на наличие папок

   foreach($folder in $sourceFolderPath) #заносим в форечь список полученных папок
   {
   $sourceFolderPath = Join-Path -Path $sourceDirectory -ChildPath $folder.Name #Получаем полный путь папки отключенного юзера
   Remove-Item -Path $sourceFolderPath -Recurse -Force
   }
}