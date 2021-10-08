
function Get-ApiVersion
{
    <#
    .SYNOPSIS
    Retrieves the Zabbix API version from either an API session or a specific server

    .PARAMETER Session
    A session hashtable created by calling New-ApiSession. If not specified, the function will look for $script:latestSession

    .PARAMETER Uri
    Path to the Zabbix API endpoint on a specific Zabbix server

    .EXAMPLE
    Get-ApiVersion
    Gets the API version of the server used for the current API session

    .EXAMPLE
    Get-ApiVersion $(New-ApiSession "http://myserver/zabbix/api_jsonrpc.php" (Get-Credentials MyAdminLogin))
    Gets the API version of the server while setting up a new API session.

    .EXAMPLE
    Get-ApiVersion http://myZabbix.myNet.org/zabbix/api_jsonrpc.php
    Gets the API version of a specific Zabbix server.

    #>
    param(
        [cmdletbinding(DefaultParameterSetName='Session')]

        [Parameter(ParameterSetName = 'Session', Position=0)]
        [System.Collections.Hashtable] $Session = $script:LatestSession,

        [Parameter(ParameterSetName = 'Direct', Mandatory=$true)]
        [string] $Uri
    )

    $targetURI = ""
    switch($PSCmdlet.ParameterSetName)
    {
        'Session' {$targetURI = $Session.uri}
        'Direct' {$targetURI = $Uri}
    }

    $requestBody = New-JsonrpcRequest "apiinfo.version" @{}
    $httpResult = ""
    try
    {
        $httpResult = Invoke-RestMethod -Uri $targetURI -Method Post -ContentType "application/json" -Body $requestBody
    }
    catch
    {
        Write-Error "Invoke-RestMethod failed. Error: $($error[0])"
        return $null
    }

    $apiVersion = $httpResult.result
    $apiVersion
}