#
# Helpers
#
Write-Warning "PSScriptRoot: [$PSScriptRoot]"
. "$PSScriptRoot/src/New-ZbxJsonrpcRequest.ps1"
. "$PSScriptRoot/src/Get-ZbxApiVersion.ps1"
. "$PSScriptRoot/src/New-ZbxApiSession.ps1"
. "$PSScriptRoot/src/Invoke-ZbxZabbixApi.ps1"
. "$PSScriptRoot/src/InternalTimeHelpers.ps1"
. "$PSScriptRoot/src/InternalZabbixTypes.ps1"
. "$PSScriptRoot/src/Get-ZbxReadableOperation.ps1"

#
# Proxies
#
. "$PSScriptRoot/src/Get-ZbxProxy.ps1"

#
# Hosts
#
. "$PSScriptRoot/src/New-ZbxHost.ps1"
. "$PSScriptRoot/src/Get-ZbxHost.ps1"
. "$PSScriptRoot/src/Update-ZbxHost.ps1"
. "$PSScriptRoot/src/Enable-ZbxHost.ps1"
. "$PSScriptRoot/src/Disable-ZbxHost.ps1"
. "$PSScriptRoot/src/Remove-ZbxHost.ps1"

. "$PSScriptRoot/src/New-ZbxHostGroup.ps1"
. "$PSScriptRoot/src/Get-ZbxHostGroup.ps1"
. "$PSScriptRoot/src/Add-ZbxHostGroupMembership.ps1"
. "$PSScriptRoot/src/Remove-ZbxHostGroupMembership.ps1"
. "$PSScriptRoot/src/Remove-ZbxHostGroup.ps1"

#
# Maintenance
#
. "$PSScriptRoot/src/New-ZbxMaintenance.ps1"
. "$PSScriptRoot/src/Get-ZbxMaintenance.ps1"
. "$PSScriptRoot/src/Remove-ZbxMaintenance.ps1"

#
# Actions
#
. "$PSScriptRoot/src/Get-ZbxAction.ps1"

#
# Users
#
. "$PSScriptRoot/src/New-ZbxUser.ps1"
. "$PSScriptRoot/src/Get-ZbxUser.ps1"
. "$PSScriptRoot/src/Remove-ZbxUser.ps1"

. "$PSScriptRoot/src/New-ZbxUserGroup.ps1"
. "$PSScriptRoot/src/Get-ZbxUserGroup.ps1"
. "$PSScriptRoot/src/Add-ZbxUserMail.ps1"
. "$PSScriptRoot/src/Enable-ZbxUserGroup.ps1"
. "$PSScriptRoot/src/Disable-ZbxUserGroup.ps1"
. "$PSScriptRoot/src/Add-ZbxUserGroupMembership.ps1"
. "$PSScriptRoot/src/Remove-ZbxUserGroupMembership.ps1"
. "$PSScriptRoot/src/Add-ZbxUserGroupPermission.ps1"
. "$PSScriptRoot/src/Remove-ZbxUserGroup.ps1"

#
# Media
#
. "$PSScriptRoot/src/Get-ZbxMedia.ps1"
. "$PSScriptRoot/src/Get-ZbxMediaType.ps1"
. "$PSScriptRoot/src/Remove-ZbxMedia.ps1"

#
# Templates
#
. "$PSScriptRoot/src/Get-ZbxTemplate.ps1"
. "$PSScriptRoot/src/Remove-ZbxTemplate.ps1"
