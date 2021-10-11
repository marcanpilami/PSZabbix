function Remove-UserGroup
{
    <#
    .SYNOPSIS
    Remove one or more user groups from Zabbix.

    .DESCRIPTION
    Removal is immediate.

    .INPUTS
    This function accepts ZabbixUserGroup objects or user group IDs from the pipe. Equivalent to using -UserGroupId parameter.

    .OUTPUTS
    The ID of the removed objects.

    .EXAMPLE
    Remove all groups
    PS> Get-UserGroup | Remove-UserGroup
    10084
    10085
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)][ValidateNotNullOrEmpty()][Alias("UsrGrpId", "UserGroup", "Id")]
        # Id of one or more groups to remove. You can also pipe in objects with an "Id" of "usrgrpid" property.
        [int[]]$UserGroupId
    )

    begin
    {
        $prms = @()
    }
    process
    {
        $prms += $UserGroupId
    }
    end
    {
        if ($prms.Count -eq 0) { return }
        Invoke-ZabbixApi $session "usergroup.delete" $prms | Select-Object -ExpandProperty usrgrpids
    }
}

