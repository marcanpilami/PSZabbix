function Add-ZbxUserMail 
{
    <#
    .SYNOPSIS
    Add a new mail type media to one or more users.
    
    .DESCRIPTION
    Add a new mail type media to one or more users. Purely an ADD cmdlet - if there is already a mail media for the given user, it won't be
    modified and the user will have multiple mail media.

    .INPUTS
    This function takes ZbxUser objects or integer ID as pipeline input (equivalent to using -UserId parameter)

    .OUTPUTS
    The ID of the new media object(s).

    .EXAMPLE
    PS> Get-ZbxUser -Name toto1 | Add-ZbxUserMail toto1@company.com
    12
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$True, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=2)][ValidateNotNullOrEmpty()][Alias("User", "Id")]
        # One or more users to modify. Either user objects (with a userid property) or directly IDs.
        [int[]] $UserId,
        
        [Parameter(Mandatory=$True, Position=0)]
        # Mail adress to send the alerts to
        [string] $SendTo,

        [Parameter(Mandatory=$False, Position=1)]
        # A severity mask. Default is Disaster,High
        [ZbxSeverity] $Severity = [ZbxSeverity]::Disaster -bor [ZbxSeverity]::High
    )

    Begin
    {
        $users = @()
        $type = @(Get-ZbxMediaType -session $Session -type Email)[0]
        $media = @{mediatypeid = $type.mediatypeid; sendto = $SendTo; active = [int][ZbxStatus]::Enabled; severity = [int]$Severity; period = "1-7,00:00-24:00"}
    }
    process
    {
        $UserId |% {$users += @{userid = $_}} 
    }
    end
    {
        if ($users.Count -eq 0) { return }
        Invoke-ZbxZabbixApi $session "user.addmedia"  @{users = $users; medias = $media} | Select-Object -ExpandProperty mediaids
    } 
}
