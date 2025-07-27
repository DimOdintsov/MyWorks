param(
    [Parameter(Mandatory = $true)]
    [string]$folder
)
$computers = Get-Content -Path $folder
$result = @()
foreach ($username in $computers)
{
    try{
        $results = Get-ADUser $($username) -Properties UserPrincipalName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty UserPrincipalName
        $result += $results}
        catch{
         $errorss = Write-Output "The name ($username) don't corrent or cannot found in AD."
         $result += $errorss
        Continue
        }

}
Write-Output $result