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
    PS> Get-User "marsu*"
    userid alias           name                 surname              usrgrpsnames
    ------ -----           ----                 -------              ------------
         1 marsu1          Zabbix               Administrator        Zabbix administrators
         2 marsu2                                                    Guests

    .EXAMPLE
    PS> Get-User
    userid alias           name                 surname              usrgrpsnames
    ------ -----           ----                 -------              ------------
         1 Admin           Zabbix               Administrator        Zabbix administrators
         2 guest                                                     Guests

    .EXAMPLE
    PS> Get-User -Id 1
    userid alias           name                 surname              usrgrpsnames
    ------ -----           ----                 -------              ------------
         1 Admin           Zabbix               Administrator        Zabbix administrators
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
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
    Invoke-ZabbixApi $session "user.get"  $prms | ForEach-Object {$_.userid = [int]$_.userid; $_.PSTypeNames.Insert(0,"ZabbixUser"); $_}
}
