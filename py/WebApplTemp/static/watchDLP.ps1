param(
    [Parameter(Mandatory = $true)]
    [string]$CompName
)
[string] $name = $CompName.Split('.')[0]
try{
if (@(Get-ADComputer -Identity $name -ErrorAction SilentlyContinue).Count){[string] $name = $name + "DOMAIN.com" }}
catch{
Write-Output "The name ($CompName) don't corrent or cannot found in AD."
exit
}
$forex = Invoke-Command -ScriptBlock { get-wmiobject win32_product | ? {$_.vendor -like "*NAME*"} } -ComputerName $name
Write-Output $forex