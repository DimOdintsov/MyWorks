<#
Важно, запускаем его предварительно проверив директорию на наличие "Изменивших фамилию юзеров", код ниже. Ручками меняем эти папкина корректные и тогда уже запускаем мув.

$folders = Get-ChildItem "M:\FS\Users" -Directory -Exclude "_BackedUp", "_Orphaned"| Select-Object Name
foreach ($user in $folders) 
{

   try{
   Get-ADUser -Identity ($user).Name -Properties SamAccountName, Enabled | Where-Object Enabled -eq 0 | Select-Object SamAccountName, Enabled
   }
   catch
   {
   write-host ($user).Name "-Изменили фамилию"
   }
}
#>
# Получаем все вложенные папки
$folders = Get-ChildItem "M:\FS\Users" -Directory -Exclude "_BackedUp", "_Orphaned"| Select-Object Name

#путь откуда будем переносить
$sourceDirectory = "M:\FS\Users"

#путь куда будем переносить
$destinationDirectory = "M:\Old\"

#Перебираем все папки из переменной
foreach ($user in $folders) 
{

   $a = Get-ADUser -Identity $user.Name -Properties SamAccountName, Enabled | Where-Object Enabled -eq 0 # делаем поиск юзера по имени папки в ад, проверяем что уз отключена
   $a.SamAccountName -split "`r`n" | Where-Object { $_ -match '\S' } #убираем срезы в полученном списке
   $sourceFolderPath = Get-ChildItem $sourceDirectory -Directory | Where-Object { $_.Name -eq $a.Samaccountname } # сканируем директорию список полученным из ад на наличие папок

   foreach($folder in $sourceFolderPath) #заносим в форечь список полученных папок
   {
   $sourceFolderPath = Join-Path -Path $sourceDirectory -ChildPath $folder.Name #Получаем полный путь папки отключенного юзера
   $destinationFolderPath = Join-Path -Path $destinationDirectory -ChildPath $folder.Name #Получаем директорию куда будет перенесено
   Move-Item -Path $sourceFolderPath -Destination $destinationFolderPath -Force
   }

}



