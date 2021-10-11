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
    PS> Get-User | Remove-User
    10084
    10085
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
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
        Invoke-ZabbixApi $session "user.delete"  $prms | Select-Object -ExpandProperty userids
    }
}

