function New-ZbxJsonrpcRequest
{
    <#
    .SYNOPSIS
    Generates the jsonrpc body of the Zabbix API call

    .PARAMETER method
    The Zabbix API method.

    .PARAMETER params
    Arguments to the jsonrpc method as a hash table

    .PARAMETER auth
    Authentication token from calling user.login method

    .EXAMPLE
    New-ZbxJsonrpcRequest -method "maintenance.get" -params @{ "output" = "extend"; "selectGroups" = "extend"; "selectTimeperiods" = "extend" } -auth "038e1d7b1735c6a5436ee9eae095879e"
    Prepares the body for a call to Zabix method maintenance.get

    .LINK
    Zabbix API reference
    https://www.zabbix.com/documentation/3.4/manual/api/reference
    #>
    param (
        [Parameter(Mandatory=$true)][string] $method, 
        [Parameter(Mandatory=$true)][hashtable] $params, 
        [string] $auth
        )
    
    $bodyHash = @{ jsonrpc = "2.0"; id = 1 }
    
    $bodyHash["method"] = $method

    if ($params.output -eq $null -and $method -like "*.get")
    {
        $params["output"] = "extend"
    }

    #
    # For some API, the params member is an array - not a hash
    # Use "array" key to indicate this case and pass along the array
    #
    if($params.ContainsKey("array"))
    {
        $bodyHash["params"] = $params["array"]
    }
    else 
    {
        $bodyHash["params"] = $params
    }

    if(-not [string]::IsNullOrEmpty($auth))
    {
        $bodyHash["auth"] = $auth
    }

    return ConvertTo-Json $bodyHash -Depth 20
}