function Get-Host
{
    <#
    .SYNOPSIS
    Retrieve and filter hosts.

    .DESCRIPTION
    Query all hosts (not templates) with basic filters, or get all hosts.

    .INPUTS
    This function does not take pipe input.

    .OUTPUTS
    The ZabbixHost objects corresponding to the filter.

    .EXAMPLE
    PS> Get-Host
    hostid host                    name                                        status
    ------ ----                    ----                                        ------
    10084  Zabbix server           Zabbix server                               Enabled
    10105  Agent Mongo 1           Agent Mongo 1                               Enabled

    .EXAMPLE
    PS> Get-Host -Id 10084
    hostid host                    name                                        status
    ------ ----                    ----                                        ------
    10084  Zabbix server           Zabbix server                               Enabled

    .EXAMPLE
    PS> Get-Host "Agent*"
    hostid host                    name                                        status
    ------ ----                    ----                                        ------
    10105  Agent Mongo 1           Agent Mongo 1                               Enabled
    10106  Agent Mongo 2           Agent Mongo 2                               Enabled
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False)][Alias("HostId")]
        # Only retrieve the items with the given ID(s).
        [int[]] $Id,

        [Parameter(Mandatory=$False)]
        # Only retrieve items which belong to the given group(s).
        [int[]] $HostGroupId,

        [Parameter(Mandatory=$False, Position=0)][Alias("HostName")]
        # Filter by hostname. Accepts wildcard.
        [string] $Name
    )
    $prms = @{search= @{}; searchWildcardsEnabled = 1; selectInterfaces = @("interfaceid", "ip", "dns"); selectParentTemplates = 1}
    if ($Id.Length -gt 0) {$prms["hostids"] = $Id}
    if ($HostGroupId.Length -gt 0) {$prms["groupids"] = $GroupId}
    if ($Name -ne $null) {$prms["search"]["name"] = $Name}
    $result = Invoke-ZabbixApi $session "host.get" $prms
    $result | ForEach-Object {
        $_.status = [ZbxStatus]$_.status
        $_.hostid = [int]$_.hostid
        $_.PSTypeNames.Insert(0,"ZabbixHost")
        $_
    }
}

