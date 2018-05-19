function New-ZbxApiSession
{
    <#
    .SYNOPSIS
    Create a new authenticated session which can be used to call the Zabbix REST API.
    
    .DESCRIPTION
    It must be called all other functions. It returns the actual session object, but usually
    this object is not needed as the module caches and reuses the latest successful session.

    The validity of the credentials is checked and an error is thrown if not.

    .INPUTS
    This function does not take pipe input.

    .OUTPUTS
    The session object.

    .EXAMPLE
    PS> New-ZbxApiSession "http://myserver/zabbix/api_jsonrpc.php" (Get-Credentials MyAdminLogin)
    Name                           Value
    ----                           -----
    Auth                           2cce0ad0fac0a5da348fdb70ae9b233b
    Uri                            http://myserver/zabbix/api_jsonrpc.php
    WARNING : Connected to Zabbix version 3.2.1
    #>
    param(
        # The Zabbix REST endpoint. It should be like "http://myserver/zabbix/api_jsonrpc.php".
        [uri] $ApiUri, 
        
        # The credentials used to authenticate. Use Get-Credential to create this object.
        [PSCredential]$auth, 
        
        # If this switch is used, the information message "connected to..." will not be displayed.
        [switch]$Silent
    )

    $bodyJson = new-ZbxJsonrpcRequest "user.login" @{user = $auth.UserName; password = $auth.GetNetworkCredential().Password}
    $r = Invoke-RestMethod -Uri $ApiUri -Method Post -ContentType "application/json" -Body $bodyJson
    if ($r -eq $null -or $r.result -eq $null -or [string]::IsNullOrWhiteSpace($r.result))
    {
        Write-Error -Message "Session could not be opened"
    }
    $script:latestSession = @{Uri = $ApiUri; Auth = $r.result}
    $script:latestSession

    $ver = Get-ZbxApiVersion -Session $script:latestSession
    $vers = $ver.split(".")
    if ( ($vers[0] -lt 2) -or ($vers[0] -eq 2 -and $vers[1] -lt 4))
    {
        Write-Warning "PSZabbix has not been tested with this version of Zabbix ${ver}. Tested version are >= 2.4. It should still work but be warned."
    }
    if (-not $Silent)
    {
        Write-Information "Connected to Zabbix version ${ver}"
    }
}