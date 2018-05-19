function Get-ZbxTemplate 
{
    <#
    .SYNOPSIS
    Retrieve and filter templates.
    
    .DESCRIPTION
    Query all templates (not hosts) with basic filters, or get all templates. 

    .INPUTS
    This function does not take pipe input.

    .OUTPUTS
    The ZabbixTemplate objects corresponding to the filter.

    .EXAMPLE
    PS> Get-ZbxHost
    templateid name                                               description
    ---------- ----                                               -----------
    10001      Template OS Linux
    10047      Template App Zabbix Server
    10048      Template App Zabbix Proxy
    10050      Template App Zabbix Agent

    .EXAMPLE
    PS> Get-ZbxHost -Id 10001
    templateid name                                               description
    ---------- ----                                               -----------
    10001      Template OS Linux
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False)][Alias("TemplateId")]
        # Only retrieve the template with the given ID.
        [int[]] $Id,
        
        [Parameter(Mandatory=$False)]
        # Only retrieve remplates which belong to the given group(s).
        [int[]] $GroupId,

        [Parameter(Mandatory=$False)]
        # Only retrieve templates which are linked to the given hosts
        [int[]] $HostId,

        [Parameter(Mandatory=$False)]
        # Only retrieve templates which are children of the given parent template(s)
        [int[]] $ParentId,

        [Parameter(Mandatory=$False, Position=0)][Alias("TemplateName")]
        # Filter by name. Accepts wildcard.
        [string] $Name
    )
    $prms = @{search= @{}; searchWildcardsEnabled=1}
    if ($Id.Length -gt 0) {$prms["templateids"] = $Id}
    if ($GroupId.Length -gt 0) {$prms["groupids"] = $GroupId}
    if ($HostId.Length -gt 0) {$prms["hostids"] = $HostId}
    if ($Name -ne $null) {$prms["search"]["name"] = $Name}
    Invoke-ZbxZabbixApi $session "template.get"  $prms | ForEach-Object {$_.templateid = [int]$_.templateid; $_.PSTypeNames.Insert(0,"ZabbixTemplate"); $_}
}

