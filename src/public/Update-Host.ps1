function Update-Host
{
    <#
    .SYNOPSIS
    Update the attributes of one or more existing Zabbix Hosts.

    .DESCRIPTION
    Please note that this method actually updates all attributes of the host, even if they were not changed.

    This is first and foremost made to update direct attributes. To update linked linked objects like templates or interfaces, it is often more practical to use the dedicated cmdlets.

    .INPUTS
    This function accepts ZabbixHost objects, on pipe or as argument.

    .OUTPUTS
    The ID of the changed objects.

    .EXAMPLE
    Sets a new description for all hosts.
    PS> Get-Host |% { $_.name = "toto"; $_ } | Update-Host
    10084
    10085
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [ValidateScript({ $_.PSObject.TypeNames[0] -eq 'ZabbixHost'})][ValidateNotNullOrEmpty()]
        # One or more hosts to update.
        [PSObject[]] $HostObject
    )
    begin
    {
        $Hosts = @()
    }
    process
    {
        $Hosts += $HostObject
    }
    end
    {
        if ($Hosts.Count -eq 0) { return }
        $prms = @{ array = $Hosts }
        Invoke-ZabbixApi $session "host.update" $prms | Select-Object -ExpandProperty hostids
    }
}


