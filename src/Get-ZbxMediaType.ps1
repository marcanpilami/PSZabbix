function Get-ZbxMediaType 
{
    <#
    .SYNOPSIS
    Retrieve and filter media types
    
    .DESCRIPTION
    Query all media types with basic filters, or get all media types. 

    .INPUTS
    This function does not take pipe input.

    .OUTPUTS
    The ZabbixMediaType objects corresponding to the filter.

    .EXAMPLE
    PS> Get-ZbxMediaType -Type Email
    mediatypeid type                                 description
    ----------- ----                                 -----------
              1 Email                                Email
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False)][Alias("MediaTypeId")]
        # Only retrieve the media type with the given ID.
        [int[]] $Id,
        
        [Parameter(Mandatory=$False, Position=0)][Alias("Description")]
        # Filter by name. Accepts wildcard.
        [string] $Name,

        [Parameter(Mandatory=$False, Position=0)][Alias("MediaTypeType")]
        # Filter by type (email, SMS...)
        [ZbxMediaTypeType] $Type
    )
    $prms = @{search= @{}; filter=@{}; searchWildcardsEnabled=1; selectUsers = 0}
    if ($Id.Length -gt 0) {$prms["mediatypeids"] = $Id}
    if ($Name -ne $null) {$prms["search"]["description"] = $Name}
    if ($Type -ne $null) {$prms["filter"]["type"] = [int]$Type}

    Invoke-ZbxZabbixApi $session "mediatype.get" $prms | ForEach-Object {$_.mediatypeid = [int]$_.mediatypeid; $_.type = [ZbxMediaTypeType]$_.type; $_.status = [ZbxStatus]$_.status; $_.PSTypeNames.Insert(0,"ZabbixMediaType"); $_}
}
