function Remove-ZbxHostGroup 
{
    <#
    .SYNOPSIS
    Remove one or more host groups from Zabbix.
    
    .DESCRIPTION
    Removal is immediate. 

    .INPUTS
    This function accepts ZabbixHostGroup objects or host group IDs from the pipe. Equivalent to using -HostGroupId parameter.

    .OUTPUTS
    The ID of the removed objects.

    .EXAMPLE
    Remove all groups
    PS> Get-ZbxHostGroup | Remove-ZbxHostGroup
    10084
    10085
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)][ValidateNotNullOrEmpty()][Alias("Id", "GroupId")]
        # ID of one or more groups to remove. You can also pipe in objects with an "ID" of "groupid" property.
        [int[]]$HostGroupId
    )

    begin
    {
        $prms = @()
    }
    process
    {
        $prms += $HostGroupId 
    }
    end
    {
        if ($prms.Count -eq 0) { return }
        Invoke-ZbxZabbixApi $session "hostgroup.delete" $prms | Select-Object -ExpandProperty groupids
    }
}
