# Директория для сканирования
$folder = "D:\FS\Resources"

# Получаем все вложенные папки
$folders = Get-ChildItem $folder -Directory -Exclude "MACVC" #-Recurse

# Проходим по каждой найденной папке
foreach ($folderItem in $folders) {
    # Получаем ACL текущей папки
    $acl = Get-Acl $folderItem.FullName

    # Ищем группу с именем, соответствующим шаблону "*-wr"
    $groupName = $acl.Access | Where-Object { $_.IdentityReference -like "*-wr" } | Select-Object -ExpandProperty IdentityReference

    # Если группа найдена, создаем аналогичную без наследования на родителя, в котором запрещаем удаление родителя
    if ($groupName) {
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $groupName,"Delete","None","None","deny"
        $acl.SetAccessRule($accessRule)
        Set-Acl $folderItem.FullName $acl
        Write-Host "Done for -  $($folderItem.FullName)."
    } else {
        Write-Host "error! Already DONE before $($folderItem.FullName)."
    }
}
