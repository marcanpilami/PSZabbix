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
    PS> Get-UserGroup "*admin*"
    usrgrpid count name
    -------- ----- ----
           7 1     Zabbix administrators

    .EXAMPLE
    PS> Get-UserGroup
    usrgrpid count name
    -------- ----- ----
           7 1     Zabbix administrators
           8 4     Guests
           9 0     Disabled

    .EXAMPLE
    PS> Get-UserGroup -Id 7
    usrgrpid count name
    -------- ----- ----
           7 1     Zabbix administrators
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
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
    Invoke-ZabbixApi $session "usergroup.get"  $prms | ForEach-Object {$_.usrgrpid = [int]$_.usrgrpid; $_.users_status = [ZbxStatus]$_.users_status; $_.debug_mode = [ZbxStatus]$_.debug_mode; $_.PSTypeNames.Insert(0,"ZabbixUserGroup"); $_}
}
