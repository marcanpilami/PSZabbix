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


function New-ApiSession($ApiUri, $auth)
{
    $r = Invoke-RestMethod -Uri $ApiUri -Method Post -ContentType "application/json" -Body (new-JsonrpcRequest "user.login" @{user = $auth.UserName; password = $auth.GetNetworkCredential().Password})
    if ($r -eq $null -or $r.result -eq $null -or [string]::IsNullOrWhiteSpace($r.result))
    {
        Write-Error -Message "Session could not be opened"
    }
    $script:latestSession = @{Uri = $ApiUri; Auth = $r.result}
    $script:latestSession
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

function Get-Host
{
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False)][Alias("HostId")]
        # Only retrieve the item with the given ID.
        [int[]] $Id,
        
        [Parameter(Mandatory=$False)]
        # Only retrieve items which belong to the given group(s).
        [int[]] $GroupId,

        [Parameter(Mandatory=$False, Position=0)][Alias("HostName")]
        # Filter by hostname. Accepts wildcard.
        [string] $Name
    )
    $prms = @{search= @{}; searchWildcardsEnabled = 1; selectInterfaces = 1; selectParentTemplates = 1}
    if ($Id.Length -gt 0) {$prms["hostids"] = $Id}
    if ($GroupId.Length -gt 0) {$prms["groupids"] = $GroupId}
    if ($Name -ne $null) {$prms["search"]["name"] = $Name}
    Invoke-ZabbixApi $session "host.get" $prms |% {$_.hostid = [int]$_.hostid; $_.PSTypeNames.Insert(0,"ZabbixHost"); $_}
}


function New-Host
{
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
        [int[]] $GroupId,

        [parameter(Mandatory=$true, ParameterSetName="Objects")]
        # The groups the new host should belong to.
        [PSCustomObject[]] $Group,

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
        [string]$Dns,

        [parameter(Mandatory=$false)]
        # The port to use to use to contact the host. Default is 10050.
        $Port = 10050
    )

    $isIp = 0
    try { [ipaddress]$Dns; $isIp = 1} catch {}

    if ($groupid -ne $null)
    {
        $group = @()
        $groupId |% { $group += @{"groupid" = $_} }
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
        groups = $Group
        templates = $Template
        inventory_mode = 0
        inventory = $Inventory
    }

    $r = Invoke-ZabbixApi $session "host.create" $prms
    Get-Host -session $s -Id $r.hostids
}


function Remove-Host
{
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
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)][ValidateScript({ $_.PSObject.TypeNames[0] -eq 'ZabbixHost'})][Alias("Host")][ValidateNotNullOrEmpty()]
        # The host or hostid to add to the hostgroup.
        [PSCustomObject[]]$Hosts,

        [Parameter(Mandatory=$true, Position=0)][ValidateNotNullOrEmpty()]
        # The Host is added to this list of one or more hostgroups.
        [PSCustomObject[]]$Groups
    )
    begin
    {
        $grpids = @($Groups |% {@{groupid = $_.groupid}} )
        $prms = @{hosts = @(); groups = $grpids}
    }
    process
    {
        $prms["hosts"] += $Hosts.hostid
    }
    end
    {
        Invoke-ZabbixApi $session "host.massadd" $prms | select -ExpandProperty hostids
    }   
}


function Remove-HostGroupMembership
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=1)][ValidateScript({ $_.PSObject.TypeNames[0] -eq 'ZabbixHost'})][Alias("Host")][ValidateNotNullOrEmpty()]
        # The host or hostid to remove from the hostgroup(s).
        [PSCustomObject[]]$Hosts,

        [Parameter(Mandatory=$true, Position=0)][ValidateNotNullOrEmpty()][ValidateScript({ $_.PSObject.TypeNames[0] -eq 'ZabbixGroup'})]
        # The Host is removed from this list of one or more hostgroups.
        [PSCustomObject[]]$Groups
    )
    begin
    {
        $grpids = @($Groups |% {$_.groupid} )
        $prms = @{hostids = @(); groupids = $grpids}
    }
    process
    {
        $prms["hostids"] += $Hosts.hostid
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
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,
        
        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)][ValidateNotNullOrEmpty()][Alias("TemplateId", "templateid")]
        # The templates to remove. Either template objects (with a templateid property) or directly IDs.
        [int[]]$Template
    )

    begin
    {
        $prms = @()
    }
    process
    {
        $prms += $Template 
    }
    end
    {
        if ($prms.Count -eq 0) { return }
        Invoke-ZabbixApi $session "template.delete" $prms | select -ExpandProperty templateids
    }
}



################################################################################
## GROUPS (hostgroups)
################################################################################

#region host groups
function Get-Group
{
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


function New-Group
{
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
        $r = Invoke-ZabbixApi $session "hostgroup.create" $prms
        Get-Group -Session $s -Id $r.groupids
    }
}


function Remove-Group
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)][ValidateNotNullOrEmpty()][Alias("Id", "Group")]
        # ID of one or more groups to remove. You can also pipe in objects with an "ID" of "groupid" property.
        [int[]]$GroupId
    )

    begin
    {
        $prms = @()
    }
    process
    {
        $prms += $GroupId 
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
    Invoke-ZabbixApi $session "usergroup.get"  $prms |% {$_.usrgrpid = [int]$_.usrgrpid; $_.PSTypeNames.Insert(0,"ZabbixUserGroup"); $_}
}


function New-UserGroup
{
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
        $r = Invoke-ZabbixApi $session "usergroup.create" $prms
        Get-UserGroup -Session $s -Id $r.usrgrpids
    }
}


function Remove-UserGroup
{
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



################################################################################
## USERS
################################################################################

function Get-User
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true)][Alias("UserId")]
        # Only retrieve the user with the given ID
        [int[]] $Id,
        
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )][Alias("UsergrpId")]
        # Only retrieve groups which contain the given users
        [int[]] $GroupId,

        [Parameter(Mandatory=$False, Position=0)][Alias("UserName")]
        # Filter by name. Accepts wildcard.
        [string] $Name
    )
    $prms = @{selectUsrgrps = "extend"; getAccess = 1; search= @{}; searchWildcardsEnabled = 1}
    if ($Id.Length -gt 0) {$prms["userids"] = $Id}
    if ($GroupId.Length -gt 0) {$prms["usrgrpids"] = $GroupId}
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
        $id = Invoke-ZabbixApi $session "user.create"  $prms
        Get-User -Session $Session -Id $id.userids
    }
}


function Remove-User
{
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

<#
    .notes
    Very slow when modifying many users as there is no "mass update" API for this operation in Zabbix.
#>
function Add-UserGroupMembership
{
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
        [int[]] $GroupId,

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
    if ($GroupId.Length -gt 0) {$prms["groupids"] = $GroupId}
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