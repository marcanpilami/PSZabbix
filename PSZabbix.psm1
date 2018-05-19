#
# Helpers
#
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\New-ZbxJsonrpcRequest.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Get-ZbxApiVersion.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\New-ZbxApiSession.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Invoke-ZbxZabbixApi.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\InternalTimeHelpers.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\InternalZabbixTypes.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Get-ZbxReadableOperation.ps1"

#
# Proxies
#
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Get-ZbxProxy.ps1"

#
# Hosts
#
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\New-ZbxHost.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Get-ZbxHost.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Update-ZbxHost.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Enable-ZbxHost.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Disable-ZbxHost.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Remove-ZbxHost.ps1"

. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\New-ZbxHostGroup.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Get-ZbxHostGroup.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Add-ZbxHostGroupMembership.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Remove-ZbxHostGroupMembership.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Remove-ZbxHostGroup.ps1"

#
# Maintenance
#
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\New-ZbxMaintenance.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Get-ZbxMaintenance.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Remove-ZbxMaintenance.ps1"

#
# Actions
#
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Get-ZbxAction.ps1"

#
# Users
#
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\New-ZbxUser.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Get-ZbxUser.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Remove-ZbxUser.ps1"

. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\New-ZbxUserGroup.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Get-ZbxUserGroup.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Add-ZbxUserMail.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Enable-ZbxUserGroup.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Disable-ZbxUserGroup.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Add-ZbxUserGroupMembership.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Remove-ZbxUserGroupMembership.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Add-ZbxUserGroupPermission.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Remove-ZbxUserGroup.ps1"

#
# Media
#
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Get-ZbxMedia.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Get-ZbxMediaType.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Remove-ZbxMedia.ps1"

#
# Templates
#
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Get-ZbxTemplate.ps1"
. "$($env:ProgramFiles)\WindowsPowerShell\Modules\PSZabbix\src\Remove-ZbxTemplate.ps1"
