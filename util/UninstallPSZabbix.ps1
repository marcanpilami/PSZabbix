#Requires -runasadministrator
$modulepath = "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\"
try 
{
    Remove-Module PSZabbix -ErrorAction Stop
}
catch 
{
    Write-host "PSZabbix Module is not installed"  -ForegroundColor Yellow
}

try 
{
    if(Test-Path -Path $modulepath -PathType Container)
    {
        Remove-Item -path $modulepath -Force -Recurse -ErrorAction Stop
    }
}
catch 
{
    Write-host "Failed to remove folder $modulepath" -ForegroundColor Yellow
}