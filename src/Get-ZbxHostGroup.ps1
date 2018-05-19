function Get-ZbxHostGroup 
{
    <#
    .SYNOPSIS
    Retrieve and filter host groups.
    
    .DESCRIPTION
    Query all host groups with basic filters, or get all host groups. 

    .INPUTS
    This function does not take pipe input.

    .OUTPUTS
    The ZabbixHostGroup objects corresponding to the filter.

    .EXAMPLE
    PS> Get-ZbxHostGroup "Linux*"
    groupid internal flags name
    ------- -------- ----- ----
          1 0        0     Linux Group 1
          2 0        0     Linux Group 2

    .EXAMPLE
    PS> Get-ZbxHostGroup
    groupid internal flags name
    ------- -------- ----- ----
          1 0        0     Templates
          2 0        0     Linux servers
          4 0        0     Zabbix servers

    .EXAMPLE
    PS> Get-ZbxHostGroup -Id 1
    groupid internal flags name
    ------- -------- ----- ----
          1 0        0     Templates
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,
        
        [Parameter(Mandatory=$False)]
        # Only retrieve the groups with the given ID(s)
        [int[]] $Id, 
        
        [Parameter(Mandatory=$False)]
        # Only retrieve the groups which contain the given host(s)
        [int[]] $HostId,

        [Parameter(Mandatory=$False, Position=0)][Alias("GroupName")]
        # Filter by name. Accepts wildcard.
        [string] $Name
    )
    $prms = @{search= @{}; searchWildcardsEnabled = 1; selectHosts = 1}
    if ($HostId.Length -gt 0) {$prms["hostids"] = $HostId}
    if ($Id.Length -gt 0) {$prms["groupids"] = $Id}
    if ($Name -ne $null) {$prms["search"]["name"] = $Name}
    Invoke-ZbxZabbixApi $session "hostgroup.get"  $prms | ForEach-Object {$_.groupid = [int]$_.groupid; $_.PSTypeNames.Insert(0,"ZabbixGroup"); $_}
}
