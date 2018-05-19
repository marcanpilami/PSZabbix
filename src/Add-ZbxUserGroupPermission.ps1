function Add-ZbxUserGroupPermission 
{
    <#
    .SYNOPSIS
    Set permissions for user groups on host groups.
    
    .DESCRIPTION
    Add, modify or remove permissions granted to one or more user groups on one or more host groups.
    This is idempotent.
    This is additional: existing permissions on host groups not mentionned in -HostGroup are not modified.

    .INPUTS
    This function accepts ZabbixUserGroup objects from the pipe. Equivalent to using -UserGroup parameter.

    .OUTPUTS
    The ID of the modified objects.

    .EXAMPLE
    PS> $usergroup11,$usergroup2 | Add-ZbxUserGroupPermission $hostgroup1,$hostgroup2 ReadWrite
    10084
    10085

    .NOTES
    There is no Remove-ZbxUserGroupPermission, as this method with -Permission Clear actually removes a permission.
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$true, Position=0)][ValidateScript({ $_.groupid -ne $null})][ValidateNotNullOrEmpty()]
        # The host group(s) to add to the user group.
        [PSCustomObject[]]$HostGroup,

        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=2)][ValidateScript({ $_.usrgrpid -ne $null})][ValidateNotNullOrEmpty()]
        # The user groups to add permissions to. Can come from the pipe.
        [PSCustomObject[]]$UserGroup,

        [Parameter(Mandatory=$true, Position=1)]
        # The permission to grant on the specified groups. "Clear" means any rule concerning these groups will be removed from the user groups.
        [ZbxPermission] $Permission
    )
    begin
    {
        $newRights = if ($Permission -eq [ZbxPermission]::Clear) {@()} else {@($HostGroup |% {@{id = $_.groupid; permission = [int]$Permission}} )}
        $HostGroupIds = @($HostGroup | select -ExpandProperty groupid) 
        $usrgrpids = @()
        $prms = @()
    }
    process
    {
        $usrgrpids += $UserGroup.usrgrpid
    }
    end
    {
        # Note: there is no usergroup.massremove verb in the API. And the usergroup.massadd method cannot update existing permissions.
        # So we have to use the normal "update" verb. To do so we need to collect existing permissions and alter them.
        # This is done in "end" and not in "process" so as to make a single GET API request to fetch existing rights - much faster.

        if ($usrgrpids.Count -eq 0) { return }

        foreach ($usergroup in (Get-ZbxUserGroup -Id $usrgrpids))
        {
            # First filter existing permissions - do not touch permissions which are not about the $HostGroups
            $rights = @()
            foreach($right in $usergroup.rights)
            {
                if (-not($right.id -in $HostGroupIds))
                {
                    $rights += $right
                }
            }
            # Then add permissions for $HostGroups
            $rights += $newRights

            # Finaly create the update object
            $prms += @{usrgrpid = $usergroup.usrgrpid; rights = $rights}
        }

        Invoke-ZbxZabbixApi $session "usergroup.update" $prms | Select-Object -ExpandProperty usrgrpids
    }   
}
