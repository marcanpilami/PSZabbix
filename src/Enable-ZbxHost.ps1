function Enable-ZbxHost 
{
    <#
    .SYNOPSIS
    Enable one or more hosts from Zabbix.
    
    .DESCRIPTION
    Simple change of the status of the host. Idempotent.

    .INPUTS
    This function accepts ZabbixHost objects or host IDs from the pipe. Equivalent to using -HostId parameter.

    .OUTPUTS
    The ID of the changed objects.

    .EXAMPLE
    Enable all hosts
    PS> Get-ZbxHost | Enable-ZbxHost
    10084
    10085
    #>
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
        Invoke-ZbxZabbixApi $session "host.massupdate" @{hosts=$ids; status=0} | Select-Object -ExpandProperty hostids
    }
}

