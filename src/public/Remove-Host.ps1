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
    PS> Get-Host | Remove-Host
    10084
    10085
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
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
        Invoke-ZabbixApi $session "host.delete" $prms | Select-Object -ExpandProperty hostids
    }
}

