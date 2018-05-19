##Requires -runasadministrator
$modulepath = "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\"

if(Test-Path -Path $modulepath -PathType Container)
{
    Write-Host "Module folder exists - please uninstall PSZabbix: $modulepath"
    exit
}
New-Item -ItemType Directory -Path $modulepath

$scriptLocation = Split-Path -Parent $MyInvocation.MyCommand.Path
$moduleRoot = Split-Path -Parent $scriptLocation
Push-Location $moduleRoot 
Copy-item -path *.* -Destination $modulepath
Copy-Item -Path .\src -Destination $modulepath\src -Container -Recurse
Pop-Location

Import-Module PSZabbix
Get-Module PSZabbix