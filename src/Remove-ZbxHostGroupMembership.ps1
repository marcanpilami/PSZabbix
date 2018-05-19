function Remove-ZbxHostGroupMembership 
{
    <#
    .SYNOPSIS
    Remove a host (or multiple hosts) as a member of one or more host groups. 
    
    .DESCRIPTION
    This is additional: existing membership to other groups are not changed. 

    .INPUTS
    This function accepts ZabbixHost objects from the pipe. Equivalent to using -Host parameter.

    .OUTPUTS
    The ID of the changed objects.

    .EXAMPLE
    PS> Get-ZbxHost | Remove-ZbxHostGroupMembership (Get-ZbxGroup group1),(Get-ZbxGroup group2)
    10084
    10085

    Make sure no host is member of two specified groups.
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)][ValidateScript({ $_.PSObject.TypeNames[0] -eq 'ZabbixHost'})][ValidateNotNullOrEmpty()]
        # The host or hostid to remove from the hostgroup(s).
        [PSCustomObject[]]$Host,

        [Parameter(Mandatory=$true, Position=0)][ValidateNotNullOrEmpty()][ValidateScript({ $_.PSObject.TypeNames[0] -eq 'ZabbixGroup'})]
        # The Host is removed from this list of one or more hostgroups.
        [PSCustomObject[]]$HostGroup
    )
    begin
    {
        $grpids = @($HostGroup |% {$_.groupid} )
        $prms = @{hostids = @(); groupids = $grpids}
    }
    process
    {
        $prms["hostids"] += $Host.hostid
    }
    end
    {
        Invoke-ZbxZabbixApi $session "host.massremove" $prms | Select-Object -ExpandProperty hostids
    }   
}
