param($TargetHostName, $ZabbixAPIUrl)

Import-Module PSZabbix

Write-Host "Using Zabbix API endpoint: $ZabbixAPIUrl"

#
# Default Zabbix security protocol was not supported by newer PowerShell in my test bed.
# I had to tell PowerShell to use an older protocol
#
$defaultSecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol
# Write-Host "Default security protocol: $($defaultSecurityProtocol)"
# [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
# Write-Host "Using security protocol: $([Net.ServicePointManager]::SecurityProtocol)"
#

#
# Open an API session
#
$admin_creds = Get-Credential -UserName $env:USERNAME -Message "Zabbix credentials"
$ZbxSession = New-ZbxApiSession $ZabbixAPIUrl $admin_creds -erroraction Stop
$ver = Get-ZbxApiVersion -Session $ZbxSession 
Write-Host "Zabbix Server version $ver"

#
# Get the test host
#
Write-Host "Targeting host: $TargetHostName"
$targetHost = Get-ZbxHost -Session $ZbxSession -HostName $TargetHostName
[int] $targetHostID = $targetHost.hostid
Write-Host "HostID: $targetHostID"

#
# Either add or remove a maintenance
#
$maint = Get-ZbxMaintenance -Session $ZbxSession -HostId $targetHostID
if($maint -ne $null)
{
    Write-Host "Found existing maintenance on $($targetHost.host)"
    $maint | Format-Table

    Write-Host "Removing maintenance $($maint.maintenanceid)"
    Remove-ZbxMaintenance -Id $maint.maintenanceid
}
else 
{
    Write-Host "Adding default maintenance on $($targetHost.host) - ID $targetHostID"
    $newMaint = New-ZbxMaintenance -HostId $targetHostID -Name "Patching for $($targetHost.host) - HostId $targetHostID"
    $newMaint
}

#
# Put the security protocol back
#
[Net.ServicePointManager]::SecurityProtocol = $defaultSecurityProtocol