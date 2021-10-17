function Remove-Media
{
    <#
    .SYNOPSIS
    Remove one or more user media from Zabbix.

    .DESCRIPTION
    Removal is immediate.

    .INPUTS
    This function accepts ZabbixMedia objects or media IDs from the pipe. Equivalent to using -MediaId parameter.

    .OUTPUTS
    The ID of the removed objects.

    .EXAMPLE
    Remove all users
    PS> Get-Media | Remove-Media
    10084
    10085
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$True, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)][ValidateNotNullOrEmpty()][Alias("Media", "Id")]
        # One or more media to remove. Either user objects (with a mediaid property) or directly IDs.
        [int[]] $MediaId
    )

    Begin
    {
        $prms = @()
    }
    process
    {
        $prms += $MediaId
    }
    end
    {
        if ($prms.Count -eq 0) { return }
        $prms = @{ array = $prms }
        Invoke-ZabbixApi $session "user.deletemedia"  $prms | Select-Object -ExpandProperty mediaids
    }
}