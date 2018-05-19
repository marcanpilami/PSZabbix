function New-ZbxUserGroup 
{
    <#
    .SYNOPSIS
    Create a new user group.
    
    .DESCRIPTION
    Create a new user group. 

    .INPUTS
    This function accepts a ZabbixUserGroup as pipe input, or any object which properties map the function parameters.

    .OUTPUTS
    The ZabbixUserGroup object created.

    .EXAMPLE
    PS> New-ZbxUserGroup "newgroupname1","newgroupname2"
    usrgrpid count name
    -------- ----- ----
           7 1     newgroupname1
           8 1     newgroupname2

    .EXAMPLE
    PS> "newgroupname1","newgroupname2" | New-ZbxUserGroup 
    usrgrpid count name
    -------- ----- ----
           7 1     newgroupname1
           8 1     newgroupname2
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)][ValidateNotNullOrEmpty()][Alias("UserGroupName")]
        # The name of the new group (one or more separated by commas)
        [string[]] $Name,

        [Parameter(Mandatory=$false)]
        # Status of the new group. Default is enabled.
        $Status = [ZbxStatus]::Enabled,

        [Parameter(Mandatory=$false)]
        # If members have access to the GUI. Default is WithDefaultAuthenticationMethod.
        $GuiAccess = [ZbxGuiAccess]::WithDefaultAuthenticationMethod
    )
    begin
    {
        $prms = @()
    }
    process
    {
        $Name |% { $prms += @{name = $_; gui_access = [int]$GuiAccess; users_status = [int]$Status} }
    }
    end
    {
        if ($prms.Count -eq 0) { return }
        $r = Invoke-ZbxZabbixApi $session "usergroup.create" $prms
        Get-ZbxUserGroup -Session $s -Id $r.usrgrpids
    }
}
