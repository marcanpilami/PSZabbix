$ErrorActionPreference = "Stop"
$latestSession = $null



################################################################################
## INTERNAL HELPERS
################################################################################

function New-JsonrpcRequest($method, $params, $auth = $null)
{
    if ($params.output -eq $null -and $method -like "*.get")
    {
        $params["output"] = "extend"
    }

    return ConvertTo-Json @{
        jsonrpc = "2.0"
	    method = $method
	    params = $params
	    id = 1
	    auth = $auth
    } -Depth 20
}


function Get-ApiVersion($Session)
{
    $r = Invoke-RestMethod -Uri $session.Uri -Method Post -ContentType "application/json" -Body (new-JsonrpcRequest "apiinfo.version" @{})
    $r.result
}

function New-ApiSession
{
    <#
    .SYNOPSIS
    Create a new authenticated session which can be used to call the Zabbix REST API.
    
    .DESCRIPTION
    It must be called all other functions. It returns the actual session object, but usually
    this object is not needed as the module caches and reuses the latest successful session.

    The validity of the credentials is checked and an error is thrown if not.

    .INPUTS
    This function does not take pipe input.

    .OUTPUTS
    The session object.

    .EXAMPLE
    PS> New-ZbxApiSession "http://myserver/zabbix/api_jsonrpc.php" (Get-Credentials MyAdminLogin)
    Name                           Value
    ----                           -----
    Auth                           2cce0ad0fac0a5da348fdb70ae9b233b
    Uri                            http://myserver/zabbix/api_jsonrpc.php
    WARNING : Connected to Zabbix version 3.2.1
    #>
    param(
        # The Zabbix REST endpoint. It should be like "http://myserver/zabbix/api_jsonrpc.php".
        [uri] $ApiUri, 
        
        # The credentials used to authenticate. Use Get-Credential to create this object.
        [PSCredential]$auth, 
        
        # If this switch is used, the information message "connected to..." will not be displayed.
        [switch]$Silent
    )
    $r = Invoke-RestMethod -Uri $ApiUri -Method Post -ContentType "application/json" -Body (new-JsonrpcRequest "user.login" @{user = $auth.UserName; password = $auth.GetNetworkCredential().Password})
    if ($r -eq $null -or $r.result -eq $null -or [string]::IsNullOrWhiteSpace($r.result))
    {
        Write-Error -Message "Session could not be opened"
    }
    $script:latestSession = @{Uri = $ApiUri; Auth = $r.result}
    $script:latestSession

    $ver = Get-ApiVersion -Session $script:latestSession
    $vers = $ver.split(".")
    if ( ($vers[0] -lt 2) -or ($vers[0] -eq 2 -and $vers[1] -lt 4))
    {
        Write-Warning "PSZabbix has not been tested with this version of Zabbix ${ver}. Tested version are >= 2.4. It should still work but be warned."
    }
    if (-not $Silent)
    {
        Write-Warning "Connected to Zabbix version ${ver}"
    }
}


function Invoke-ZabbixApi($session, $method, $parameters = @{})
{
    if ($session -eq $null) { $session = $latestSession }
    if ($session -eq $null)
    {
        Write-Error -Message "No session is opened. Call New-ZabbixApiSession before or pass a previously retrieved session object as a parameter."
        return
    }

    $r = Invoke-RestMethod -Uri $session.Uri -Method Post -ContentType "application/json" -Body (new-JsonrpcRequest $method $parameters $session.Auth)
    if ($r.error -ne $null)
    {
        Write-Error -Message "$($r.error.message) $($r.error.data)" -ErrorId $r.error.code
    }
    else
    {
        return $r.result
    }
}



################################################################################
## HOSTS
################################################################################

Add-Type -TypeDefinition @"
   public enum ZbxStatus
   {
      Enabled = 0,
      Disabled = 1    
   }
"@


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
    PS> Get-ZbxHost
    hostid host                    name                                        status
    ------ ----                    ----                                        ------
    10084  Zabbix server           Zabbix server                               Enabled
    10105  Agent Mongo 1           Agent Mongo 1                               Enabled

    .EXAMPLE
    PS> Get-ZbxHost -Id 10084
    hostid host                    name                                        status
    ------ ----                    ----                                        ------
    10084  Zabbix server           Zabbix server                               Enabled

    .EXAMPLE
    PS> Get-ZbxHost "Agent*"
    hostid host                    name                                        status
    ------ ----                    ----                                        ------
    10105  Agent Mongo 1           Agent Mongo 1                               Enabled
    10106  Agent Mongo 2           Agent Mongo 2                               Enabled
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
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
    $prms = @{search= @{}; searchWildcardsEnabled = 1; selectInterfaces = 1; selectParentTemplates = 1}
    if ($Id.Length -gt 0) {$prms["hostids"] = $Id}
    if ($HostGroupId.Length -gt 0) {$prms["groupids"] = $GroupId}
    if ($Name -ne $null) {$prms["search"]["name"] = $Name}
    Invoke-ZabbixApi $session "host.get" $prms |% {$_.status = [ZbxStatus]$_.status; $_.hostid = [int]$_.hostid; $_.PSTypeNames.Insert(0,"ZabbixHost"); $_}
}


function New-Host
{
    <#
    .SYNOPSIS
    Create a new host.
    
    .DESCRIPTION
    Create a new host. 

    .INPUTS
    This function does not take pipe input.

    .OUTPUTS
    The ZabbixHost object created.

    .EXAMPLE
    PS> New-ZbxHost -Name "mynewhostname$(Get-Random)" -HostGroupId 2 -TemplateId 10108 -Dns localhost
    hostid host                    name                                        status
    ------ ----                    ----                                        ------
    10084  mynewhostname321        mynewhostname                               Enabled

    .NOTES
    Contrary to other New-* functions inside this module, this method does not take pipe input. 
    This is inconsistent and needs to be changed.
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [parameter(Mandatory=$true)][Alias("HostName")]
        # The name of the new host (not the visible name)
        [string] $Name,

        [parameter(Mandatory=$false)][Alias("DisplayName")]
        # The name as displayed in the interface. Defaults to Name.
        [string] $VisibleName,

        [parameter(Mandatory=$false)]
        # A description of the new host.
        [string] $Description = $null,

        [parameter(Mandatory=$true, ParameterSetName="Ids")]
        # The groups the new host should belong to.
        [int[]] $HostGroupId,

        [parameter(Mandatory=$true, ParameterSetName="Objects")]
        # The groups the new host should belong to.
        [PSCustomObject[]] $HostGroup,

        [parameter(Mandatory=$true, ParameterSetName="Ids")]
        # The templates the new host should belong to.
        [int[]] $TemplateId,

        [parameter(Mandatory=$true, ParameterSetName="Objects")]
        # The templates the new host should belong to.
        [PSCustomObject[]] $Template,

        [parameter(Mandatory=$false)]
        # An optional map of inventory properties
        $Inventory = @{},

        [parameter(Mandatory=$true)]
        # The DNS or IP address to use to contact the host
        [string] $Dns,

        [parameter(Mandatory=$false)]
        # The port to use to use to contact the host. Default is 10050.
        [int] $Port = 10050,

        [parameter(Mandatory=$false)]
        # Should the newly created host be enabled? Default is true.
        [ZbxStatus] $Status = [ZbxStatus]::Enabled,

        [parameter(Mandatory=$false)]
        # The ID of the proxy to use. Default is no proxy.
        [int] $ProxyId
    )

    $isIp = 0
    try { [ipaddress]$Dns; $isIp = 1} catch {}

    if ($Hostgroupid -ne $null)
    {
        $HostGroup = @()
        $HostGroupId |% { $HostGroup += @{"groupid" = $_} }
    }
    if ($TemplateId -ne $null)
    {
        $Template = @()
        $TemplateId |% { $template += @{"templateid" = $_} }
    }

    $prms = @{
        host = $Name
        name = if ([string]::IsNullOrWhiteSpace($VisibleName)) { $null } else { $VisibleName }
        description = $Description
        interfaces = @( @{
            type = 1
            main = 1
            useip = $isIp
            dns = if ($isIp -eq 1) { "" } else { $Dns }
            ip = if ($isIp -eq 0) { "" } else { $Dns }
            port = $Port
        })
        groups = $HostGroup
        templates = $Template
        inventory_mode = 0
        inventory = $Inventory
        status = [int]$Status
        proxy_hostid = if ($ProxyId -eq $null) { "" } else { $ProxyId }
    }

    $r = Invoke-ZabbixApi $session "host.create" $prms
    Get-Host -session $s -Id $r.hostids
}


function Remove-Host
{
    <#
    .SYNOPSIS
    Remove one or more hosts from Zabbix.
    
    .DESCRIPTION
    Removal is immediate. 

    .INPUTS
    This function accepts ZabbixHost objects or host IDs from the pipe. Equivalent to using -HostId parameter.

    .OUTPUTS
    The ID of the removed objects.

    .EXAMPLE
    Remove all hosts
    PS> Get-ZbxHost | Remove-ZbxHost
    10084
    10085
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)][ValidateNotNullOrEmpty()][Alias("Id")]
        # The ID of one or more hosts to remove. You can also pipe a ZabbixHost object or any object with a hostid or id property.
        [int[]]$HostId
    )

    begin
    {
        $prms = @()
    }
    process
    {
        $prms += $HostId 
    }
    end
    {
        if ($prms.Count -eq 0) { return }
        Invoke-ZabbixApi $session "host.delete" $prms | select -ExpandProperty hostids
    }
}


function Enable-Host
{
    <#
    .SYNOPSIS
    Enable one or more hosts from Zabbix.
    
    .DESCRIPTION
    Simple change of the status of the host. Idempotent.

    .INPUTS
    This function accepts ZabbixHost objects or host IDs from the pipe. Equivalent to using -HostId parameter.

    .OUTPUTS
    The ID of the changed objects.

    .EXAMPLE
    Enable all hosts
    PS> Get-ZbxHost | Enable-ZbxHost
    10084
    10085
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true, Position=0)][Alias("Id", "Host")]
        # The ID of one or more hosts to enable. You can also pipe a ZabbixHost object or any object with a hostid or id property.
        [int[]]$HostId
    )
    begin
    {
        $ids = @()
    }
    Process
    {
         $HostId |% {$ids += @{hostid = $_}}
    }
    end
    {
        if ($ids.Count -eq 0) { return }
        Invoke-ZabbixApi $session "host.massupdate" @{hosts=$ids; status=0} | select -ExpandProperty hostids
    }
}


function Disable-Host
{
    <#
    .SYNOPSIS
    Disable one or more hosts from Zabbix.
    
    .DESCRIPTION
    Simple change of the status of the host. Idempotent.

    .INPUTS
    This function accepts ZabbixHost objects or host IDs from the pipe. Equivalent to using -HostId parameter.

    .OUTPUTS
    The ID of the changed objects.

    .EXAMPLE
    Disable all hosts
    PS> Get-ZbxHost | Disable-ZbxHost
    10084
    10085
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true, Position=0)][Alias("Id", "Host")]
        # The ID of one or more hosts to disable. You can also pipe a ZabbixHost object or any object with a hostid or id property.
        [int[]]$HostId
    )
    begin
    {
        $ids = @()
    }
    Process
    {
        $HostId |% {$ids += @{hostid = $_}}
    }
    end
    {
        if ($ids.Count -eq 0) { return }
        Invoke-ZabbixApi $session "host.massupdate" @{hosts=$ids; status=1} | select -ExpandProperty hostids
    }
}


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
    PS> Get-ZbxHost | Add-ZbxHostGroupMembership (Get-ZbxGroup group1),(Get-ZbxGroup group2)
    10084
    10085

    Add two groups to all hosts
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
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
        Invoke-ZabbixApi $session "host.massadd" $prms | select -ExpandProperty hostids
    }   
}


function Remove-HostGroupMembership
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
        Invoke-ZabbixApi $session "host.massremove" $prms | select -ExpandProperty hostids
    }   
}



################################################################################
## TEMPLATES
################################################################################

function Get-Template
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
    Invoke-ZabbixApi $session "template.get"  $prms |% {$_.templateid = [int]$_.templateid; $_.PSTypeNames.Insert(0,"ZabbixTemplate"); $_}
}


function Remove-Template
{
    <#
    .SYNOPSIS
    Remove one or more templates from Zabbix.
    
    .DESCRIPTION
    Removal is immediate. 

    .INPUTS
    This function accepts ZabbixTemplate objects or template IDs from the pipe. Equivalent to using -TemplateId parameter.

    .OUTPUTS
    The ID of the removed objects.

    .EXAMPLE
    Remove all templates
    PS> Get-ZbxTemplate | Remove-ZbxTemplate
    10084
    10085
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,
        
        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)][ValidateNotNullOrEmpty()][Alias("Template")]
        # The templates to remove. Either template objects (with a templateid property) or directly IDs.
        [int[]]$TemplateId
    )

    begin
    {
        $prms = @()
    }
    process
    {
        $prms += $TemplateId 
    }
    end
    {
        if ($prms.Count -eq 0) { return }
        Invoke-ZabbixApi $session "template.delete" $prms | select -ExpandProperty templateids
    }
}



################################################################################
## HOST GROUPS
################################################################################

#region host groups
function Get-HostGroup
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
    Invoke-ZabbixApi $session "hostgroup.get"  $prms |% {$_.groupid = [int]$_.groupid; $_.PSTypeNames.Insert(0,"ZabbixGroup"); $_}
}


function New-HostGroup
{
    <#
    .SYNOPSIS
    Create a new host group.
    
    .DESCRIPTION
    Create a new host group. 

    .INPUTS
    This function accepts a ZabbixHostGroup as pipe input, or any object which properties map the function parameters.

    .OUTPUTS
    The ZabbixHostGroup object created.

    .EXAMPLE
    PS> New-ZbxHostGroup "newgroupname1","newgroupname2"
    groupid internal flags name
    ------- -------- ----- ----
         13 0        0     newgroupname1
         14 0        0     newgroupname2

    .EXAMPLE
    PS> "newgroupname1","newgroupname2" | New-ZbxHostGroup 
    groupid internal flags name
    ------- -------- ----- ----
         13 0        0     newgroupname1
         14 0        0     newgroupname2
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)][ValidateNotNullOrEmpty()][Alias("HostGroupName")]
        # The name of the new group (one or more separated by commas)
        [string[]] $Name
    )
    begin
    {
        $prms = @()
    }
    process
    {
        $Name |% { $prms += @{name = $_} }
    }
    end
    {
        if ($prms.Count -eq 0) { return }
        $r = Invoke-ZabbixApi $session "hostgroup.create" $prms
        Get-HostGroup -Session $s -Id $r.groupids
    }
}


function Remove-HostGroup
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
        Invoke-ZabbixApi $session "hostgroup.delete" $prms | select -ExpandProperty groupids
    }
}
#endregion



################################################################################
## USER GROUPS
################################################################################

function Get-UserGroup
{
    <#
    .SYNOPSIS
    Retrieve and filter user groups.
    
    .DESCRIPTION
    Query all user groups with basic filters, or get all user groups. 

    .INPUTS
    This function does not take pipe input.

    .OUTPUTS
    The ZabbixUserGroup objects corresponding to the filter.

    .EXAMPLE
    PS> Get-ZbxUserGroup "*admin*"
    usrgrpid count name
    -------- ----- ----
           7 1     Zabbix administrators

    .EXAMPLE
    PS> Get-ZbxUserGroup
    usrgrpid count name
    -------- ----- ----
           7 1     Zabbix administrators
           8 4     Guests
           9 0     Disabled

    .EXAMPLE
    PS> Get-ZbxUserGroup -Id 7
    usrgrpid count name
    -------- ----- ----
           7 1     Zabbix administrators
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False)][Alias("UserGroupId", "UsrGrpId")]
        # Only retrieve the usergroup with the given ID
        [int[]] $Id,
        
        [Parameter(Mandatory=$False)]
        # Only retrieve groups which contain the given users
        [int[]] $UserId,

        [Parameter(Mandatory=$False, Position=0)][Alias("UserGroupName")]
        # Filter by name. Accepts wildcard.
        [string] $Name
    )
    $prms = @{searchWildcardsEnabled=1; selectUsers= 1; selectRights = 1; search= @{}}
    if ($Id.Length -gt 0) {$prms["usrgrpids"] = $Id}
    if ($UserId.Length -gt 0) {$prms["userids"] = $UserId}
    if ($Name -ne $null) {$prms["search"]["name"] = $Name}
    Invoke-ZabbixApi $session "usergroup.get"  $prms |% {$_.usrgrpid = [int]$_.usrgrpid; $_.users_status = [ZbxStatus]$_.users_status; $_.debug_mode = [ZbxStatus]$_.debug_mode; $_.PSTypeNames.Insert(0,"ZabbixUserGroup"); $_}
}


function New-UserGroup
{
    <#
    .SYNOPSIS
    Create a new user group.
    
    .DESCRIPTION
    Create a new user group. 

    .INPUTS
    This function accepts a ZabbixUserGroup as pipe input, or any object which properties map the function parameters.

    .OUTPUTS
    The ZabbixUserGroup object created.

    .EXAMPLE
    PS> New-ZbxUserGroup "newgroupname1","newgroupname2"
    usrgrpid count name
    -------- ----- ----
           7 1     newgroupname1
           8 1     newgroupname2

    .EXAMPLE
    PS> "newgroupname1","newgroupname2" | New-ZbxUserGroup 
    usrgrpid count name
    -------- ----- ----
           7 1     newgroupname1
           8 1     newgroupname2
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)][ValidateNotNullOrEmpty()][Alias("UserGroupName")]
        # The name of the new group (one or more separated by commas)
        [string[]] $Name
    )
    begin
    {
        $prms = @()
    }
    process
    {
        $Name |% { $prms += @{name = $_} }
    }
    end
    {
        if ($prms.Count -eq 0) { return }
        $r = Invoke-ZabbixApi $session "usergroup.create" $prms
        Get-UserGroup -Session $s -Id $r.usrgrpids
    }
}


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
    PS> Get-ZbxUserGroup | Remove-ZbxUserGroup
    10084
    10085
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
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
        Invoke-ZabbixApi $session "usergroup.delete" $prms | select -ExpandProperty usrgrpids
    }
}


Add-Type -TypeDefinition @"
   public enum ZbxPermission
   {
      Clear = -1,
      Deny = 0,
      ReadOnly = 2,
      ReadWrite = 3    
   }
"@


function Add-UserGroupPermission
{
    <#
    .SYNOPSIS
    Set permissions for user groups on host groups.
    
    .DESCRIPTION
    Add, modify or remove permissions granted to one or more user groups on one or more host groups.
    This is idempotent.
    This is additional: existing permissions on host groups not mentionned in -HostGroup are not modified.

    .INPUTS
    This function accepts ZabbixUserGroup objects from the pipe. Equivalent to using -UserGroup parameter.

    .OUTPUTS
    The ID of the modified objects.

    .EXAMPLE
    PS> $usergroup11,$usergroup2 | Add-ZbxUserGroupPermission $hostgroup1,$hostgroup2 ReadWrite
    10084
    10085

    .NOTES
    There is no Remove-UserGroupPermission, as this method with -Permission Clear actually removes a permission.
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$true, Position=0)][ValidateScript({ $_.groupid -ne $null})][ValidateNotNullOrEmpty()]
        # The host group(s) to add to the user group.
        [PSCustomObject[]]$HostGroup,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=2)][ValidateScript({ $_.usrgrpid -ne $null})][ValidateNotNullOrEmpty()]
        # The user groups to add permissions to. Can come from the pipe.
        [PSCustomObject[]]$UserGroup,

        [Parameter(Mandatory=$true, Position=1)]
        # The permission to grant on the specified groups. "Clear" means any rule concerning these groups will be removed from the user groups.
        [ZbxPermission] $Permission
    )
    begin
    {
        $newRights = if ($Permission -eq [ZbxPermission]::Clear) {@()} else {@($HostGroup |% {@{id = $_.groupid; permission = [int]$Permission}} )}
        $HostGroupIds = @($HostGroup | select -ExpandProperty groupid) 
        $usrgrpids = @()
        $prms = @()
    }
    process
    {
        $usrgrpids += $UserGroup.usrgrpid
    }
    end
    {
        # Note: there is no usergroup.massremove verb in the API. And the usergroup.massadd method cannot update existing permissions.
        # So we have to use the normal "update" verb. To do so we need to collect existing permissions and alter them.
        # This is done in "end" and not in "process" so as to make a single GET API request to fetch existing rights - much faster.

        if ($usrgrpids.Count -eq 0) { return }

        foreach ($usergroup in (Get-UserGroup -Id $usrgrpids))
        {
            # First filter existing permissions - do not touch permissions which are not about the $HostGroups
            $rights = @()
            foreach($right in $usergroup.rights)
            {
                if (-not($right.id -in $HostGroupIds))
                {
                    $rights += $right
                }
            }
            # Then add permissions for $HostGroups
            $rights += $newRights

            # Finaly create the update object
            $prms += @{usrgrpid = $usergroup.usrgrpid; rights = $rights}
        }

        Invoke-ZabbixApi $session "usergroup.update" $prms | select -ExpandProperty usrgrpids
    }   
}



################################################################################
## USERS
################################################################################

function Get-User
{
    <#
    .SYNOPSIS
    Retrieve and filter users.
    
    .DESCRIPTION
    Query all users with basic filters, or get all users. 

    .INPUTS
    This function does not take pipe input.

    .OUTPUTS
    The ZabbixUser objects corresponding to the filter.

    .EXAMPLE
    PS> Get-ZbxUser "marsu*"
    userid alias           name                 surname              usrgrpsnames
    ------ -----           ----                 -------              ------------
         1 marsu1          Zabbix               Administrator        Zabbix administrators
         2 marsu2                                                    Guests

    .EXAMPLE
    PS> Get-ZbxUser
    userid alias           name                 surname              usrgrpsnames
    ------ -----           ----                 -------              ------------
         1 Admin           Zabbix               Administrator        Zabbix administrators
         2 guest                                                     Guests

    .EXAMPLE
    PS> Get-ZbxUser -Id 1
    userid alias           name                 surname              usrgrpsnames
    ------ -----           ----                 -------              ------------
         1 Admin           Zabbix               Administrator        Zabbix administrators
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true)][Alias("UserId")]
        # Only retrieve the user with the given ID
        [int[]] $Id,
        
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )][Alias("UsergrpId")]
        # Only retrieve users which belong to these user groups
        [int[]] $UserGroupId,

        [Parameter(Mandatory=$False, Position=0)][Alias("UserName")]
        # Filter by name. Accepts wildcard.
        [string] $Name
    )
    $prms = @{selectUsrgrps = "extend"; getAccess = 1; search= @{}; searchWildcardsEnabled = 1}
    if ($Id.Length -gt 0) {$prms["userids"] = $Id}
    if ($UserGroupId.Length -gt 0) {$prms["usrgrpids"] = $UserGroupId}
    if ($Name -ne $null) {$prms["search"]["alias"] = $Name}
    Invoke-ZabbixApi $session "user.get"  $prms |% {$_.userid = [int]$_.userid; $_.PSTypeNames.Insert(0,"ZabbixUser"); $_}
}


Add-Type -TypeDefinition @"
   public enum ZbxUserType
   {
      User = 1,
      Admin,
      SuperAdmin      
   }
"@


function New-User
{
    <#
    .SYNOPSIS
    Create a new user.
    
    .DESCRIPTION
    Create a new user. 

    .INPUTS
    This function accepts a ZabbixUser as pipe input, or any object which properties map the function parameters.

    .OUTPUTS
    The ZabbixUser object created.

    .EXAMPLE
    PS> New-ZbxUser -Alias "login1" -name "marsu" -UserGroupId (get-zbxgroup "GROUPNAME*").id
    userid alias           name                 surname              usrgrpsnames
    ------ -----           ----                 -------              ------------
        19 login1          marsu                                     GROUPNAME1,GROUPNAME2,GROUPNAME3

    Create a user from scratch.

    .EXAMPLE
    PS> $u = New-ZbxUser -Alias "login1" -name "marsu" -UserGroupId (get-zbxgroup "GROUPNAME*").id
    PS> $u | new-user -alias "login2"
    userid alias           name                 surname              usrgrpsnames
    ------ -----           ----                 -------              ------------
        20 login2          marsu                                     GROUPNAME1,GROUPNAME2,GROUPNAME3

    Copy a user.
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$true)][Alias("Login")]
        # Login of the new user. Must be unique.
        [string] $Alias,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true)][Alias("Pwd", "passwd")]
        # Password of the new user. If not specified, a long random string is used (useful if authenticated 
        # against a LDAP, as in that case the internal Zabbix password is not used).
        [string] $Password = $null,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true)]
        # Display name of the new user. If not given, the Alias is used.
        [string] $Name,
        
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )]
        # Type of user. Default is simple user.
        [ZbxUserType] $UserType = [ZbxUserType]::User,

        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$true, ParameterSetName = "ids")][ValidateNotNullOrEmpty()][Alias("UsrGrpId")]
        [int[]] $UserGroupId,

        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$true, ParameterSetName = "objects")][ValidateNotNullOrEmpty()][Alias("UsrGrps")]
        [ValidateScript({ $_.usrgrpid -ne $null})]
        [object[]] $UserGroup
    )

    begin
    {
        $prms = @()
    }
    process
    {
        $usergrps = @()
        if ($PSCmdlet.ParameterSetName -eq "ids")
        {
            $UserGroupId |% { $usergrps += @{usrgrpid = $_} }
        }
        else 
        {
            $usergrps += $UserGroup
        }

        $prms += @{
            alias = $Alias
            name = if ($Name -ne $null) { $Name } else {$Alias}
            type = [int]$UserType
            passwd = if ($Password -ne $null) {$Password} else { "" + (Get-Random -Maximum ([long]::MaxValue)) }
            usrgrps = $usergrps
        }
    }
    end
    {
        if ($prms.Count -eq 0) { return }
        $id = Invoke-ZabbixApi $session "user.create"  $prms
        Get-User -Session $Session -Id $id.userids
    }
}


function Remove-User
{
    <#
    .SYNOPSIS
    Remove one or more users from Zabbix.
    
    .DESCRIPTION
    Removal is immediate. 

    .INPUTS
    This function accepts ZabbixUser objects or user IDs from the pipe. Equivalent to using -UserId parameter.

    .OUTPUTS
    The ID of the removed objects.

    .EXAMPLE
    Remove all users
    PS> Get-ZbxUser | Remove-ZbxUser
    10084
    10085
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$True, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)][ValidateNotNullOrEmpty()][Alias("User", "Id")]
        # One or more users to remove. Either user objects (with a userid property) or directly IDs.
        [int[]] $UserId
    )

    Begin
    {
        $prms = @()
    }
    process
    {
        $prms += $UserId 
    }
    end
    {
        if ($prms.Count -eq 0) { return }
        Invoke-ZabbixApi $session "user.delete"  $prms | select -ExpandProperty userids
    }    
}


function Add-UserGroupMembership
{
    <#
    .SYNOPSIS
    Make a user (or multiple users) member of one or more user groups. 
    
    .DESCRIPTION
    This is additional: existing membership to other groups are not changed. 

    .INPUTS
    This function accepts ZabbixUser objects or user IDs from the pipe. Equivalent to using -UserId parameter.

    .OUTPUTS
    The ID of the changed objects.

    .EXAMPLE
    PS> Get-ZbxUser | Add-ZbxUserGroupMembership (Get-ZbxUserGroup group1),(Get-ZbxUserGroup group2)
    10084
    10085

    Add two groups to all users.

    .NOTES
    Very slow when modifying many users as there is no "mass update" API for this operation in Zabbix.
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$True, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Alias("Id", "User")]
        [ValidateNotNullOrEmpty()]
        # User to add to the group
        [int[]] $UserId,

        [Parameter(Mandatory=$True, ParameterSetName="Objects", Position=0)][ValidateScript({ $_.usrgrpid -ne $null})]
        # Group to add the user to
        [PSCustomObject[]] $UserGroup,
        
        [Parameter(Mandatory=$True, ParameterSetName="Ids",Position=0)]
        # Group to add the user to
        [int[]] $UserGroupId
    )

    begin
    {
        $prms = @()
        $groupids = @()
        if ($PSCmdlet.ParameterSetName -eq "Objects")
        {
            $UserGroup |% { $groupids += $_.usrgrpid}
        }
        else 
        {
             $groupids += $UserGroupId
        }
    }
    process
    {
        foreach ($uid in $UserId)
        {
            $User = Get-User -session $s -id $uid
            $grps = @()
            $existingGid = @($User.usrgrps.usrgrpid)
            $addedGid = @()

            foreach ($gid in $groupids)
            {
                if (-not ($gid -in $existingGid))
                {
                    $addedGid += $gid
                }
            }

            if ($addedGid.count -eq 0)
            {
                # already in requested groups
                continue
            }

            $addedGid += $existingGid
            foreach($gid in $addedGid)
            {
                $grps += @{usrgrpid = $gid}
            }

            $prms = @{
                userid = $User.userid
                usrgrps = $grps
            }
            # Sad, but not mass API.
            Invoke-ZabbixApi $session "user.update"  $prms | select -ExpandProperty userids
        }
    }
}


function Remove-UserGroupMembership
{
    <#
    .SYNOPSIS
    Remove a user (or multiple users) as a member of one or more user groups. 
    
    .DESCRIPTION
    This is additional: existing membership to other groups are not changed. 

    .INPUTS
    This function accepts ZabbixUser objects or user IDs from the pipe. Equivalent to using -UserId parameter.

    .OUTPUTS
    The ID of the changed objects.

    .EXAMPLE
    PS> Get-ZbxUser | Remove-ZbxUserGroupMembership (Get-ZbxUserGroup group1),(Get-ZbxUserGroup group2)
    10084
    10085

    Make sure no user is member of two specified groups.
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$True, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Alias("Id", "User")]
        [ValidateNotNullOrEmpty()]
        # User to remove from the groups
        [int[]] $UserId,

        [Parameter(Mandatory=$True, ParameterSetName="Objects", Position=0)][ValidateScript({ $_.usrgrpid -ne $null})]
        # Groups to remove the users from
        [PSCustomObject[]] $UserGroup,
        
        [Parameter(Mandatory=$True, ParameterSetName="Ids",Position=0)]
        # Groups to remove the users from
        [int[]] $UserGroupId
    )

    begin
    {
        $prms = @()
        $groupids = @()
        if ($PSCmdlet.ParameterSetName -eq "Objects")
        {
            $UserGroup |% { $groupids += $_.usrgrpid}
        }
        else 
        {
             $groupids += $UserGroupId
        }
    }
    process
    {
        foreach ($uid in $UserId)
        {
            $User = Get-User -session $s -id $uid
            $grps = @()
            $existingGid = @($User.usrgrps.usrgrpid)
            $removedGid = @()
            $remainingGid = @()

            foreach ($gid in $existingGid)
            {
                if (($gid -in $groupids))
                {
                    $removedGid += $gid
                }
                else 
                {
                    $remainingGid += $gid
                }
            }

            if ($removedGid.count -eq 0)
            {
                # already absent from requested groups
                continue
            }

            foreach($gid in $remainingGid)
            {
                $grps += @{usrgrpid = $gid}
            }

            $prms = @{
                userid = $User.userid
                usrgrps = $grps
            }
            # Sad, but not mass API.
            Invoke-ZabbixApi $session "user.update"  $prms | select -ExpandProperty userids
        }
    }
}



################################################################################
## ACTIONS
################################################################################

function Get-Action
{
    <#
    .SYNOPSIS
    Retrieve and filter users.
    
    .DESCRIPTION
    Query all actions with many filters, or get all actions. 

    .INPUTS
    This function does not take pipe input.

    .OUTPUTS
    The ZabbixAction objects corresponding to the filter.

    .EXAMPLE
    PS> Get-ZbxAction
    Actionid Name                           def_shortdata        OperationsReadable
    -------- ----                           -------------        ------------------
           2 Auto discovery. Linux servers.                      {@{ConditionEvaluat...
           3 Report problems to Zabbix a... {TRIGGER.STATUS}:... {@{ConditionEvaluat...
           4 Report not supported items     {ITEM.STATE}: {HO... {@{ConditionEvaluat...
           5 Report not supported low le... {LLDRULE.STATE}: ... {@{ConditionEvaluat...
           6 Report unknown triggers        {TRIGGER.STATE}: ... {@{ConditionEvaluat...
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False)][Alias("ActionId")]
        # Only retrieve the action with the given ID
        [int[]] $Id,
        
        [Parameter(Mandatory=$False)]
        # Only retrieve actions which use the following hosts in their conditions
        [int[]] $HostId,

        [Parameter(Mandatory=$False)]
        # Only retrieve actions which use the following groups in their conditions
        [int[]] $HostGroupId,

        [Parameter(Mandatory=$False)]
        # Only retrieve actions which use the following triggers in their conditions
        [int[]] $TriggerId,

        [Parameter(Mandatory=$False)]
        # Only retrieve actions which send messages to these users
        [int[]] $UserId,

        [Parameter(Mandatory=$False)][Alias("UsergrpId")]
        # Only retrieve actions which send messages to these user groups
        [int[]] $UserGroupId,

        [Parameter(Mandatory=$False, Position=0)][Alias("ActionName")]
        # Filter by name
        [string] $Name
    )
    $prms = @{searchWildcardsEnabled=1; selectConditions = "extend"; selectOperations = "extend"; search= @{}}
    if ($Id.Length -gt 0) {$prms["actionids"] = $Id}
    if ($HostId.Length -gt 0) {$prms["hostids"] = $HostId}
    if ($HostGroupId.Length -gt 0) {$prms["groupids"] = $HostGroupId}
    if ($TriggerId.Length -gt 0) {$prms["triggerids"] = $TriggerId}
    if ($UserId.Length -gt 0) {$prms["userids"] = $UserId}
    if ($UserGroupId.Length -gt 0) {$prms["usrgrpids"] = $UserGroupId}
    if ($Name -ne $null) {$prms["search"]["name"] = $Name}
    $res = Invoke-ZabbixApi $session "action.get"  $prms
    $res |% { $action = $_; $action | Add-Member -NotePropertyName "OperationsReadable" -notepropertyvalue @($action.operations | Get-ReadableOperation) }
    $res |% {$_.PSTypeNames.Insert(0,"ZabbixAction")}
    $res
}


$ActOpType = @{
    0 = "send message"
    1 = "remote command"
    2 = "add host"
    3 = "remove host"
    4 = "add to host group"
    5 = "moreve from host group"
    6 = "link to template"
    7 = "unlink from template"
    8 = "enable host"
    9 = "disable host"
}

$ActOpCmd = @{
    0 = "custom script"
    1 = "IPMI"
    2 = "SSH"
    3 = "Telnet"
    4 = "global script"
}

$ActConditionEvalMethod = @{
    0 = "AND/OR"
    1 = "AND"
    2 = "OR"
}

$ActOpExecuteOn = @{
    0 = "Zabbix agent"
    1 = "Zabbix server"
}


function Get-ReadableOperation([Parameter(Mandatory=$True, ValueFromPipeline=$true )]$op)
{
    Process
    {
        $res = New-Object psobject -Property @{
            OperationId = $_.operationid
            OperationType = $ActOpType[[int]$_.operationtype]
            EscalationPeriodSecond = $_.esc_period
            EscalationStartStep = $_.esc_step_from
            EscalationEndStep = $_.esc_step_to
            ConditionEvaluationMethod = $ActConditionEvalMethod[[int]$_.evaltype]
            MessageSubject = if($_.opmessage) {$_.opmessage.subject} else {$null}
            MessageContent = if($_.opmessage) {$_.opmessage.message} else {$null}
            MessageSendToGroups = $_.opmessage_grp | select usrgrpid
            MessageSendToUsers = $_.opmessage_usr | select userid
            CommandType = if($_.opcommand -ne $null) { $ActOpCmd[[int]$_.opcommand.type] } else {$null}
            Command = if($_.opcommand -ne $null) { $_.opcommand.command } else {$null}
            CommandUserName = if($_.opcommand -ne $null) { $_.opcommand.username } else {$null}
            CommandGlobalScriptId = if($_.opcommand -ne $null) { $_.opcommand.scriptid } else {$null}
            CommandExecuteOn = if($_.opcommand -ne $null) { $ActOpExecuteOn[[int]$_.opcommand.execute_on] } else {$null}
        }
        $res.PSTypeNames.Insert(0,"ZabbixActionOperation")
        $res
    }
}



################################################################################
## PROXIES
################################################################################

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
    PS> Get-ZbxProxy    
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
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
    Invoke-ZabbixApi $session "proxy.get"  $prms |% {$_.proxyid = [int]$_.proxyid; $_.PSTypeNames.Insert(0,"ZabbixProxy"); $_}
}