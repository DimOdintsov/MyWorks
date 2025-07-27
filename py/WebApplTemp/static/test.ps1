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
$forex = Invoke-Command -ScriptBlock { Get-LocalGroupMember -SID S-1-5-32-544 } -ComputerName $name | Select-Object PSComputerName, Name, SID, PrincipalSource
Write-Output $forex



#$CompName = "NB556293"