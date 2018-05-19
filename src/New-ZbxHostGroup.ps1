function New-ZbxHostGroup 
{
    <#
    .SYNOPSIS
    Create a new host group.
    
    .DESCRIPTION
    Create a new host group. 

    .INPUTS
    This function accepts a ZabbixHostGroup as pipe input, or any object which properties map the function parameters.

    .OUTPUTS
    The ZabbixHostGroup object created.

    .EXAMPLE
    PS> New-ZbxHostGroup "newgroupname1","newgroupname2"
    groupid internal flags name
    ------- -------- ----- ----
         13 0        0     newgroupname1
         14 0        0     newgroupname2

    .EXAMPLE
    PS> "newgroupname1","newgroupname2" | New-ZbxHostGroup 
    groupid internal flags name
    ------- -------- ----- ----
         13 0        0     newgroupname1
         14 0        0     newgroupname2
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)][ValidateNotNullOrEmpty()][Alias("HostGroupName")]
        # The name of the new group (one or more separated by commas)
        [string[]] $Name
    )
    begin
    {
        $prms = @()
    }
    process
    {
        $Name |% { $prms += @{name = $_} }
    }
    end
    {
        if ($prms.Count -eq 0) { return }
        $r = Invoke-ZbxZabbixApi $session "hostgroup.create" $prms
        Get-ZbxHostGroup -Session $s -Id $r.groupids
    }
}
