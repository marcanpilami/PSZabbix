function Get-Proxy
{
    <#
    .SYNOPSIS
    Retrieve and filter proxies.

    .DESCRIPTION
    Query all proxies with basic filters, or get all proxies.

    .INPUTS
    This function does not take pipe input.

    .OUTPUTS
    The ZabbixProxy objects corresponding to the filter.

    .EXAMPLE
    PS> Get-Proxy
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False)][Alias("ProxyId")][int[]]
        # Only retrieve the item with the given ID.
        $Id,

        [Parameter(Mandatory=$False, Position=0)][Alias("ProxyName")]
        # Filter by name. Accepts wildcard.
        [string]$Name
    )
    $prms = @{searchWildcardsEnabled=1; filter= @{selectInterface=1}; search=@{}}
    if ($Id.Length -gt 0) {$prms["proxyids"] = $Id}
    if ($Name -ne $null) {$prms["search"]["name"] = $Name}
    Invoke-ZabbixApi $session "proxy.get"  $prms | ForEach-Object {$_.proxyid = [int]$_.proxyid; $_.PSTypeNames.Insert(0,"ZabbixProxy"); $_}
}

