function Get-ZbxMedia 
{
    <#
    .SYNOPSIS
    Retrieve and filter media (the definition of how a media type should be used for a user).
    
    .DESCRIPTION
    Query all media with basic filters, or get all media. 

    .INPUTS
    This function does not take pipe input.

    .OUTPUTS
    The ZabbixMedia objects corresponding to the filter.

    .EXAMPLE
    PS> Get-ZbxMedia -Status Enabled
    mediaid  userid mediatypeid active
    -------  ------ ----------- ------
          1       3           1 Enabled
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "")]
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False)][Alias("MediaId")]
        # Only retrieve the media with the given ID.
        [int[]] $Id,
        
        [Parameter(Mandatory=$False)]
        # Only retrieve media which are used by the users in the given group(s).
        [int[]] $UserGroupId,

        [Parameter(Mandatory=$False)]
        # Only retrieve media which are used by the given user(s).
        [int[]] $UserId,

        [Parameter(Mandatory=$False)]
        # Only retrieve media which use the give media type(s).
        [int[]] $MediaTypeId,

        [Parameter(Mandatory=$False)]
        # Only retrieve media which are in the given status.
        [ZbxStatus] $Status
    )
    $prms = @{}
    if ($Id.Length -gt 0) {$prms["mediaids"] = $Id}
    if ($UserGroupId.Length -gt 0) {$prms["usrgrpids"] = $UserGroupId}
    if ($UserId.Length -gt 0) {$prms["userids"] = $UserId}
    if ($MediaTypeId.Length -gt 0) {$prms["mediatypeids"] = $MediaTypeId}
    if ($Status -ne $null) {$prms["filter"] = @{"active" = [int]$Status}}
    Invoke-ZbxZabbixApi $session "usermedia.get" $prms | ForEach-Object {$_.severity = [ZbxSeverity]$_.severity; $_.mediaid = [int]$_.mediaid; $_.active=[ZbxStatus]$_.active; $_.PSTypeNames.Insert(0,"ZabbixMedia"); $_}
}
