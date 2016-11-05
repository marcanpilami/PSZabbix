$ErrorActionPreference = "Stop"
$latestSession = $null



################################################################################
## INTERNAL HELPERS
################################################################################

function new-JsonrpcRequest($method, $params, $auth = $null)
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
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )][Alias("HostId")][int[]]
        # Only retrieve the item with the given ID.
        $Id,
        
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )]
        # Only retrieve items which belong to the given group(s).
        [int[]]$GroupId,

        [Parameter(Mandatory=$False)]
        [string][Alias("HostName")]$Name
    )
    $prms = @{search= @{}; searchWildcardsEnabled = 1; selectInterfaces = 1; selectParentTemplates = 1}
    if ($Id.Length -gt 0) {$prms["hostids"] = $Id}
    if ($GroupId.Length -gt 0) {$prms["groupids"] = $GroupId}
    if ($Name -ne $null) {$prms["search"]["name"] = $Name}
    Invoke-ZabbixApi $session "host.get" $prms |% {$_.PSTypeNames.Insert(0,"ZabbixHost"); $_}
}


function New-Host
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
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
    Get-Host $s -Id $r.hostids
}


function Remove-Host
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        # The groups to remove. Either group objects (with a groupid property) or directly IDs.
        [Array]$Host
    )

    $prms = @($Host |% { if($_.hostid -ne $null) { $_.hostid } else {$_} })
    Invoke-ZabbixApi $session "host.delete" $prms | select -ExpandProperty hostids
}


function Enable-Host
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [parameter(Mandatory=$true, ValueFromPipeline=$true)][ValidateScript({ $_.PSObject.TypeNames[0] -eq 'ZabbixHost' -or $_ -is [int] })]
        # The host or hostid to enable.
        [PSCustomObject]$Host
    )

    Process
    {
        $id = if($Host.hostid -ne $null) {$Host.hostid} else {$Host}
        Invoke-ZabbixApi $session "host.update" @{hostid=$id; status=0}
    }
}


function Disable-Host
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [parameter(Mandatory=$true, ValueFromPipeline=$true)][ValidateScript({ $_.PSObject.TypeNames[0] -eq 'ZabbixHost' -or $_ -is [int] })]
        # The host or hostid to disable.
        [PSCustomObject]$Host
    )

    Process
    {
        $id = if($Host.hostid -ne $null) {$Host.hostid} else {$Host}
        Invoke-ZabbixApi $session "host.update" @{hostid=$id; status=1}
    }
}


function Add-HostGroupMembership
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
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
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
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
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true)][Alias("TemplateId")][int[]]
        # Only retrieve the template with the given ID.
        $Id,
        
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )]
        # Only retrieve remplates which belong to the given group(s).
        [int[]]$GroupId,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )]
        # Only retrieve templates which are linked to the given hosts
        [int[]]$HostId,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )]
        # Only retrieve templates which are children of the given parent template(s)
        [int[]]$ParentId,

        [string][Alias("TemplateName")]$Name
    )
    $prms = @{filter= @{}}
    if ($Id.Length -gt 0) {$prms["templateids"] = $Id}
    if ($GroupId.Length -gt 0) {$prms["groupids"] = $GroupId}
    if ($HostId.Length -gt 0) {$prms["hostids"] = $HostId}
    if ($Name -ne $null) {$prms["filter"]["name"] = $Name}
    Invoke-ZabbixApi $session "template.get"  $prms |% {$_.PSTypeNames.Insert(0,"ZabbixTemplate"); $_}
}



################################################################################
## GROUPS (hostgroups)
################################################################################

function Get-Group
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,
        
        # Only retrieve the groups with the given ID(s)
        [int[]] $Id, 
        
        [int[]]
        # Only retrieve the groups which contain the given host(s)
        $HostId,

        [string][Alias("GroupName")]$Name
    )
    $prms = @{filter= @{}}
    if ($HostId.Length -gt 0) {$prms["hostids"] = $HostId}
    if ($Id.Length -gt 0) {$prms["groupids"] = $Id}
    if ($Name -ne $null) {$prms["filter"]["name"] = $Name}
    Invoke-ZabbixApi $session "hostgroup.get"  $prms |% {$_.PSTypeNames.Insert(0,"ZabbixGroup"); $_}
}


function New-Group
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [parameter(Mandatory=$true)][Alias("HostName")]
        # The name of the new group
        [string] $Name
    )

    $prms = @{
        name = $Name        
    }

    $r = Invoke-ZabbixApi $session "hostgroup.create" $prms
    Get-Group $s -Id $r.groupids
}


function Remove-Group
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        # The groups to remove. Either group objects (with a groupid property) or directly IDs.
        [Array]$Group
    )

    $prms = @($Group |% { if($_.groupid -ne $null) { $_.groupid } else {$_} })
    Invoke-ZabbixApi $session "hostgroup.delete" $prms | select -ExpandProperty groupids
}



################################################################################
## USER GROUPS
################################################################################

function Get-UserGroup
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true)][Alias("UsergrpId")]
        # Only retrieve the usergroup with the given ID
        [int[]] $Id,
        
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )]
        # Only retrieve groups which contain the given users
        [int[]]$UserId,

        [string][Alias("UserGroupName")]$Name
    )
    $prms = @{selectUsers= 1; selectRights = 1; filter= @{}}
    if ($Id.Length -gt 0) {$prms["usrgrpids"] = $Id}
    if ($UserId.Length -gt 0) {$prms["userids"] = $UserId}
    if ($Name -ne $null) {$prms["filter"]["name"] = $Name}
    Invoke-ZabbixApi $session "usergroup.get"  $prms |% {$_.PSTypeNames.Insert(0,"ZabbixUserGroup"); $_}
}


function New-UserGroup
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [parameter(Mandatory=$true)][Alias("UserGroupName")]
        # The name of the new group
        [string] $Name
    )

    $prms = @{
        name = $Name        
    }

    $r = Invoke-ZabbixApi $session "usergroup.create" $prms
    Get-UserGroup $s -Id $r.usrgrpids
}


function Remove-UserGroup
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        # The groups to remove. Either group objects (with a usrgrpid property) or directly IDs.
        [Array]$UserGroup
    )

    $prms = @($UserGroup |% { if($_.usrgrpids -ne $null) { $_.usrgrpids } else {$_} })
    Invoke-ZabbixApi $session "usergroup.delete" $prms | select -ExpandProperty usrgrpids
}



################################################################################
## USERS
################################################################################

function Get-User
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true)][Alias("UserId")]
        # Only retrieve the user with the given ID
        [int[]] $Id,
        
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )][Alias("UsergrpId")]
        # Only retrieve groups which contain the given users
        [int[]] $GroupId,

        [string][Alias("UserName")]$Name
    )
    $prms = @{selectUsrgrps = "extend"; getAccess = 1; search= @{}; searchWildcardsEnabled = 1}
    if ($Id.Length -gt 0) {$prms["userids"] = $Id}
    if ($GroupId.Length -gt 0) {$prms["usrgrpids"] = $GroupId}
    if ($Name -ne $null) {$prms["search"]["alias"] = $Name}
    Invoke-ZabbixApi $session "user.get"  $prms |% {$_.PSTypeNames.Insert(0,"ZabbixUser"); $_}
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
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$true)][Alias("Login")]
        # Login of the new user. Must be unique.
        [string] $Alias,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true)][Alias("Pwd")]
        # Password of the new user. If not specified, a long random string is used (useful if authenticated 
        # against a LDAP, as in that case the internal Zabbix password is not used).
        [string] $Password = $null,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true)]
        # Display name of the new user. If not given, the Alias is used.
        [string] $Name,
        
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )]
        # Type of user. Default is simple user.
        [ZbxUserType] $UserType = [ZbxUserType]::User,

        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$true, ParameterSetName="Ids")]
        [int[]]$UserGroupIds,

        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$true, ParameterSetName="Objects")]
        [PSCustomObject[]]$UserGroups
    )

    $usergrps = @()
    if ($UserGroupIds -ne $null)
    {
        $UserGroupIds |% { $usergrps += @{usrgrpid = $_} }
    }
    else 
    {
        $usergrps = $UserGroups
    }
    
    $prms = @{
        alias = $Alias
        name = if ($Name -ne $null) { $Name } else {$Alias}
        type = [int]$UserType
        passwd = if ($Password -ne $null) {$Password} else { "" + (Get-Random -Maximum ([long]::MaxValue)) }
        usrgrps = $usergrps
    }

    $id = Invoke-ZabbixApi $session "user.create"  $prms
    Get-User -Id $id.userids
}


function Remove-User
{
    [CmdletBinding(DefaultParameterSetName="Ids")]
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [Parameter(Mandatory=$True, ValueFromPipeline=$true, ParameterSetName="Ids", Position=0)]
        # ID of the user to remove.
        [int] $UserId,
        
        [Parameter(Mandatory=$True, ValueFromPipeline=$true, ParameterSetName="Objects", Position=0)]
        [ValidateScript({ $_.userid -ne $null })]
        # User to remove.
        [PSCustomObject] $User
    )

    Begin
    {
        $ids = @()
    }
    process
    {
        $ids += if ($PSCmdlet.ParameterSetName -eq "Ids") { $UserId } else { $User.userid }
    }
    end
    {
        Invoke-ZabbixApi $session "user.delete"  $ids | select -ExpandProperty userids
    }    
}


function Push-User
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [Parameter(Mandatory=$True, ParameterSetName="Objects")]
        # Group to add the user to
        $Group,
        
        [Parameter(Mandatory=$True, ParameterSetName="Objects" )]
        # User to add to the group
        $User,

        [Parameter(Mandatory=$True, ParameterSetName="Ids")]
        # Group to add the user to
        $GroupId,
        
        [Parameter(Mandatory=$True, ParameterSetName="Ids")]
        # User to add to the group
        $UserId
    )

    if ($Group -ne $null)
    {
        $GroupId = $Group.groupid
    }
    if ($UserId -ne $null)
    {
        $User = Get-ZabbixUser $s -id $UserId
    }
    $grps = @($User.usrgrps)
    if (($grps |? usrgrpid -eq $GroupId | measure).Count -eq 1)
    {
        Write-Warning "Already in group - nothing will be done"
        return
    }
    $grps += @{usrgrpid = $GroupId}

    $prms = @{
        userid = $User.userid
        usrgrps = $grps
    }
    
    Invoke-ZabbixApi $session "user.update"  $prms
}


function Pop-User
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [Parameter(Mandatory=$True, ParameterSetName="Objects")]
        # Group to remove the user from
        $Group,
        
        [Parameter(Mandatory=$True, ParameterSetName="Objects" )]
        # User to remove from the group
        $User,

        [Parameter(Mandatory=$True, ParameterSetName="Ids")]
        # Group to remove the user from
        $GroupId,
        
        [Parameter(Mandatory=$True, ParameterSetName="Ids")]
        # User to remove from the group
        $UserId
    )

    if ($Group -ne $null)
    {
        $GroupId = $Group.groupid
    }
    if ($UserId -ne $null)
    {
        $User = Get-ZabbixUser $s -id $UserId
    }
    $grps = $User.usrgrps
    if (($grps |? usrgrpid -eq $GroupId | measure).Count -eq 0)
    {
        Write-Warning "User not in group - nothing will be done"
        return
    }
    $grps = @($grps |? usrgrpid -ne $GroupId)

    $prms = @{
        userid = $User.userid
        usrgrps = $grps
    }
    
    Invoke-ZabbixApi $session "user.update"  $prms
}



################################################################################
## ACTIONS
################################################################################

function Get-Action
{
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true)][Alias("ActionId")]
        # Only retrieve the action with the given ID
        [int[]] $Id,
        
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )]
        # Only retrieve actions which use the following hosts in their conditions
        [int[]] $HostId,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )]
        # Only retrieve actions which use the following groups in their conditions
        [int[]] $GroupId,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )]
        # Only retrieve actions which use the following triggers in their conditions
        [int[]] $TriggerId,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )]
        # Only retrieve actions which send messages to these users
        [int[]] $UserId,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )][Alias("UsergrpId")]
        # Only retrieve actions which send messages to these user groups
        [int[]] $UserGroupId,

        [string][Alias("ActionName")]$Name
    )
    $prms = @{selectConditions = "extend"; selectOperations = "extend"; filter= @{}}
    if ($Id.Length -gt 0) {$prms["actionids"] = $Id}
    if ($HostId.Length -gt 0) {$prms["hostids"] = $HostId}
    if ($GroupId.Length -gt 0) {$prms["groupids"] = $GroupId}
    if ($TriggerId.Length -gt 0) {$prms["triggerids"] = $TriggerId}
    if ($UserId.Length -gt 0) {$prms["userids"] = $UserId}
    if ($UserGroupId.Length -gt 0) {$prms["usrgrpids"] = $UserGroupId}
    if ($Name -ne $null) {$prms["filter"]["name"] = $Name}
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
        # A valid Zabbix API session retrieved with New-ZabbixApiSession. If not given, the latest opened session will be used.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )][Alias("ProxyId")][int[]]
        # Only retrieve the item with the given ID.
        $Id,

        [string][Alias("ProxyName")]$Name
    )
    $prms = @{filter= @{selectInterface=1}}
    if ($Id.Length -gt 0) {$prms["proxyids"] = $Id}
    if ($Name -ne $null) {$prms["filter"]["name"] = $Name}
    Invoke-ZabbixApi $session "proxy.get"  $prms |% {$_.PSTypeNames.Insert(0,"ZabbixProxy"); $_}
}