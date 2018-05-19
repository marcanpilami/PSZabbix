function Enable-ZbxUserGroup 
{
    <#
    .SYNOPSIS
    Enable one or more user groups.
    
    .DESCRIPTION
    Simple change of the status of the group. Idempotent.

    .INPUTS
    This function accepts ZabbixuserGroup objects or user group IDs from the pipe. Equivalent to using -UserGroupId parameter.

    .OUTPUTS
    The ID of the changed objects.

    .EXAMPLE
    Enable all user groups
    PS> Get-ZbxUserGroup | Enable-ZbxUserGroup
    10084
    10085
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true, Position=0)][Alias("Id", "UserGroup", "GroupId", "UsrGrpId")]
        # The ID of one or more user groups to enable. You can also pipe a ZabbixUserGroup object or any object with a usrgrpid or id property.
        [int[]]$UserGroupId
    )
    begin
    {
        $ids = @()
    }
    Process
    {
         $ids += $UserGroupId
    }
    end
    {
        if ($ids.Count -eq 0) { return }
        Invoke-ZbxZabbixApi $session "usergroup.massupdate" @{usrgrpids=$ids; users_status=0} | Select-Object -ExpandProperty usrgrpids
    }
}

