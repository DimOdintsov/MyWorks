########################V1 FIO
$name = Get-Content -Path "W:\FS\listofusers.csv" #Получаем список юзеров из csv
$location = "W:\FS\WSBackup" #директория где будут создаваться папки
$errorlog = @()
foreach ($namefromarray in $name){
    $namefromarray = $namefromarray.Trim() #Обрезаем косячные пробелы
    $getsam = Get-ADUser -Filter "DisplayName -eq '$namefromarray' -and Enabled -eq 'True'" | Select-Object -ExpandProperty SamAccountName
    if(!$getsam){
        Clear-Variable getsam
        $errorlog += "$namefromarray  - Не смогли найти данную уз в AD"
        Continue 
    } #Если не находим SAM по фио сохраняем запись в глобальную переменную
    $newfolder = New-Item -Path $location -Name $getsam -ItemType Directory -ErrorAction SilentlyContinue
    if(!$newfolder){
        Clear-Variable newfolder
        $errorlog += "$namefromarray  - Не смогли создать папку для данного юзера"
        Continue
    }#Если даже находим SAM, но папку создать не получается сохраняем запись в глобальную переменную
    try{
        $folderItem = Get-ChildItem $($newfolder).FullName -Directory #Получаем данные по созданной папке
        $acl = Get-Acl $($newfolder).FullName #Получаем ACL
        $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $getsam,"Modify,Synchronize","ContainerInherit,ObjectInherit","None","allow" #задаем параметры ACL
        $acl.SetAccessRule($AccessRule)
        $acl | Set-Acl #применяем параметры ACL
    }catch{$errorlog += "$namefromarray  - Ошибки с ACL`n"}
}
$errorlog |Out-File $location\logofscript4.txt