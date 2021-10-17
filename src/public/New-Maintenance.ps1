
function New-Maintenance
{
    <#
    .SYNOPSIS
    Create maintenance windows for a specific set of hosts or host groups

    .DESCRIPTION
    Both the host id and host group parameter is optional, but between the two, at least one host or host group must be specified.

    .INPUTS
    This function does not take pipe input, but it should.

    .OUTPUTS
    Id of the new Zabbix maintenance object

    .EXAMPLE
    PS> New-Maintenance -HostId 42,43 -Name "Lakenbake"

    maintenanceid name                               maintenance_type description
    ------------- ----                               ---------------- -----------
    134           Lakenbake                          0                Baken laken

    .EXAMPLE
    PS> New-Maintenance -HostGroupId 14 -Name "Lakenbake Group"

    maintenanceid name                               maintenance_type description
    ------------- ----                               ---------------- -----------
    134           Lakenbake                          0                Baken laken


    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$true)]
        # Name of the maintenance window
        [string] $Name,

        [Parameter(Mandatory=$False)]
        # IDs of the host groups that will undergo maintenance.
        [int[]] $HostGroupId,

        [Parameter(Mandatory=$False)]
        # IDs of the hosts that will undergo maintenance.
        [int[]] $HostId,

        [Parameter(Mandatory=$False)]
        # Start of the maintenance window
        [DateTime] $StartTime = $(Get-Date),

        [Parameter(Mandatory=$False)]
        # Start of the maintenance window
        [TimeSpan] $Duration = $(New-TimeSpan -Hours 1)

    )

    if([string]::IsNullOrEmpty($Name))
    {
        throw "-Name parameter must be populated"
    }
    $prms = @{"name" = $Name}

    #
    # Affected hosts
    #
    if($HostGroupId -eq $null -and $HostId -eq $null)
    {
        throw "Either -HostId or -HostGroupId must be specified."
    }
    if ($HostGroupId.Length -gt 0)
    {
        $prms["groupids"] = $HostGroupId
    }
    if ($HostId.Length -gt 0)
    {
        $prms["hostids"] = $HostId
    }

    #
    # Maintenance window boundaries
    #
    $prms["active_since"] = ConvertTo-EpochTime $StartTime
    $prms["active_till"] = $prms["active_since"] + $Duration.TotalSeconds

    #
    # Only create one-time maintenance period - matching the maintenance window size.
    #
    $oneTimePeriod =
    @(
        @{
            "timeperiod_type"= 0;                   # one time only
            "start_date" = $prms["active_since"];   # same as window
            "period" = $Duration.TotalSeconds;      # same as window
        }
    )
    $prms["timeperiods"] = $oneTimePeriod

    $result = Invoke-ZabbixApi $session "maintenance.create" $prms
    $result
}

