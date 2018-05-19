
function Remove-ZbxMaintenance
{
    <#
    .SYNOPSIS
    Retrieve maintenance windows for a specific window, specific set of hosts or host group
    
    .DESCRIPTION
    If called with no parameters, the function will return all maintenance windows configured on the Zabbix server
    

    .INPUTS
    This function does not take pipe input.

    .OUTPUTS
    Zabbix maintenance objects

    .EXAMPLE
    PS> Remove-ZbxMaintenance -MaintenanceId 2


    .EXAMPLE
    PS> Remove-ZbxMaintenance -MaintenanceId 1,2,3


    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False)][Alias("MaintenanceId")]
        # Only retrieve the items with the given ID(s).
        [int[]] $Id
    )
    $prms = @{}
    if ($Id.Length -gt 0) 
    {
        $prms["array"] = $Id  # "array" key is an instruction to New-ZbxJsonrpcRequest - not a body element
    }
    else 
    {
        throw "Invalid input array of maintenance Ids"
    }

    $result = Invoke-ZbxZabbixApi $session "maintenance.delete" $prms 
    $result
}

