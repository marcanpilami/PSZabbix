function Invoke-ZbxZabbixApi($session, $method, $parameters = @{})
{
    if ($session -eq $null -and $script:latestSession -eq $null)
    {
        throw "No session is opened. Call New-ZabbixApiSession before or pass a previously retrieved session object as a parameter."
    }
    if ($session -eq $null) 
    { 
        $session = $script:latestSession
    }

    $r = Invoke-RestMethod -Uri $session.Uri -Method Post -ContentType "application/json" -Body (New-ZbxJsonrpcRequest $method $parameters $session.Auth)
    if ($r.error -ne $null)
    {
        Write-Error -Message "$($r.error.message) $($r.error.data)" -ErrorId $r.error.code
        return $null
    }
    return $r.result
}