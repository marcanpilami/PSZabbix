function Add-HostGroupMembership
{
    <#
    .SYNOPSIS
    Make a host (or multiple hosts) member of one or more host groups.

    .DESCRIPTION
    This is additional: existing membership to other groups are not changed.

    .INPUTS
    This function accepts ZabbixHost objects from the pipe. Equivalent to using -Host parameter.

    .OUTPUTS
    The ID of the changed objects.

    .EXAMPLE
    PS> Get-Host | Add-HostGroupMembership (Get-Group group1),(Get-Group group2)
    10084
    10085

    Add two groups to all hosts
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)][ValidateScript({ $_.PSObject.TypeNames[0] -eq 'ZabbixHost'})][ValidateNotNullOrEmpty()]
        # The host or hostid to add to the hostgroup.
        [PSCustomObject[]]$Host,

        [Parameter(Mandatory=$true, Position=0)][ValidateNotNullOrEmpty()]
        # The Host is added to this list of one or more hostgroups.
        [PSCustomObject[]]$HostGroup
    )
    begin
    {
        $grpids = @($HostGroup |% {@{groupid = $_.groupid}} )
        $prms = @{hosts = @(); groups = $grpids}
    }
    process
    {
        $prms["hosts"] += $Host.hostid
    }
    end
    {
        if ($prms.Count -eq 0) { return }
        $prms = @{ array = $prms }
        Invoke-ZabbixApi $session "host.massadd" $prms | Select-Object -ExpandProperty hostids
    }
}


