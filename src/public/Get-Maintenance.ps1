
function Get-Maintenance
{
    <#
    .SYNOPSIS
    Retrieve maintenance windows for a specific window, specific set of hosts or host group

    .DESCRIPTION
    If called with no parameters, the function will return all maintenance windows configured on the Zabbix server


    .INPUTS
    This function does not take pipe input.

    .OUTPUTS
    Zabbix maintenance objects

    .EXAMPLE
    PS> Get-Maintenance

    maintenanceid name                               maintenance_type description
    ------------- ----                               ---------------- -----------
    134           Lakenbake                          0                Baken laken
    136           Plaza socks                        1                Wool of course

    .EXAMPLE
    PS> Get-Maintenance -Id 134

    maintenanceid name                               maintenance_type description
    ------------- ----                               ---------------- -----------
    134           Lakenbake                          0                Baken laken


    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False)][Alias("MaintenanceId")]
        # Only retrieve the items with the given ID(s).
        [int[]] $Id,

        [Parameter(Mandatory=$False)]
        # Only retrieve items which belong to the given group(s).
        [int[]] $HostGroupId,

        [Parameter(Mandatory=$False, Position=0)]
        # Filter by hostname. Accepts wildcard.
        [int[]] $HostId
    )
    $prms = @{ output="extend"; selectGroups="extend"; selectTimePeriods="extend"}
    if ($Id.Length -gt 0)
    {
        $prms["maintenanceids"] = $Id
    }
    if ($HostGroupId.Length -gt 0)
    {
        $prms["groupids"] = $GroupId
    }
    if ($HostId.Length -gt 0)
    {
        $prms["hostids"] = $HostId
    }
    $result = Invoke-ZabbixApi $session "maintenance.get" $prms
    $result
}

