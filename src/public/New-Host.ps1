function New-Host
{
    <#
    .SYNOPSIS
    Create a new host.

    .DESCRIPTION
    Create a new host.

    .INPUTS
    This function does not take pipe input.

    .OUTPUTS
    The ZabbixHost object created.

    .EXAMPLE
    PS> New-Host -Name "mynewhostname$(Get-Random)" -HostGroupId 2 -TemplateId 10108 -Dns localhost
    hostid host                    name                                        status
    ------ ----                    ----                                        ------
    10084  mynewhostname321        mynewhostname                               Enabled

    .NOTES
    Contrary to other New-* functions inside this module, this method does not take pipe input.
    This is inconsistent and needs to be changed.
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [parameter(Mandatory=$true)][Alias("HostName")]
        # The name of the new host (not the visible name)
        [string] $Name,

        [parameter(Mandatory=$false)][Alias("DisplayName")]
        # The name as displayed in the interface. Defaults to Name.
        [string] $VisibleName,

        [parameter(Mandatory=$false)]
        # A description of the new host.
        [string] $Description = $null,

        [parameter(Mandatory=$true, ParameterSetName="Ids")]
        # The groups the new host should belong to.
        [int[]] $HostGroupId,

        [parameter(Mandatory=$true, ParameterSetName="Objects")]
        # The groups the new host should belong to.
        [PSCustomObject[]] $HostGroup,

        [parameter(Mandatory=$true, ParameterSetName="Ids")]
        # The templates the new host should belong to.
        [int[]] $TemplateId,

        [parameter(Mandatory=$true, ParameterSetName="Objects")]
        # The templates the new host should belong to.
        [PSCustomObject[]] $Template,

        [parameter(Mandatory=$false)]
        # An optional map of inventory properties
        $Inventory = @{},

        [parameter(Mandatory=$true)]
        # The DNS or IP address to use to contact the host
        [string] $Dns,

        [parameter(Mandatory=$false)]
        # The port to use to use to contact the host. Default is 10050.
        [int] $Port = 10050,

        [parameter(Mandatory=$false)]
        # Should the newly created host be enabled? Default is true.
        [ZbxStatus] $Status = [ZbxStatus]::Enabled,

        [parameter(Mandatory=$false)]
        # The ID of the proxy to use. Default is no proxy.
        [int] $ProxyId
    )

    $isIp = 0
    try { [ipaddress]$Dns; $isIp = 1} catch {}

    if ($Hostgroupid -ne $null)
    {
        $HostGroup = @()
        $HostGroupId |% { $HostGroup += @{"groupid" = $_} }
    }
    if ($TemplateId -ne $null)
    {
        $Template = @()
        $TemplateId |% { $Template += @{"templateid" = $_} }
    }

    $prms = @{
        host = $Name
        name = if ([string]::IsNullOrWhiteSpace($VisibleName)) { $null } else { $VisibleName }
        description = $Description
        interfaces = @( @{
            type = 1
            main = 1
            useip = $isIp
            dns = if ($isIp -eq 1) { "" } else { $Dns }
            ip = if ($isIp -eq 0) { "" } else { $Dns }
            port = $Port
        })
        groups = $HostGroup
        templates = $Template
        inventory_mode = 0
        inventory = $Inventory
        status = [int]$Status
        proxy_hostid = if ($ProxyId -eq $null) { "" } else { $ProxyId }
    }

    $r = Invoke-ZabbixApi $session "host.create" $prms
    Get-Host -session $s -Id $r.hostids
}

