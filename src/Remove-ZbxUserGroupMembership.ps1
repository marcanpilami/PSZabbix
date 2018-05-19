function Remove-ZbxUserGroupMembership 
{
    <#
    .SYNOPSIS
    Remove a user (or multiple users) as a member of one or more user groups. 
    
    .DESCRIPTION
    This is additional: existing membership to other groups are not changed. 

    .INPUTS
    This function accepts ZabbixUser objects or user IDs from the pipe. Equivalent to using -UserId parameter.

    .OUTPUTS
    The ID of the changed objects.

    .EXAMPLE
    PS> Get-ZbxUser | Remove-ZbxUserGroupMembership (Get-ZbxUserGroup group1),(Get-ZbxUserGroup group2)
    10084
    10085

    Make sure no user is member of two specified groups.
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$True, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Alias("Id", "User")]
        [ValidateNotNullOrEmpty()]
        # User to remove from the groups
        [int[]] $UserId,

        [Parameter(Mandatory=$True, ParameterSetName="Objects", Position=0)][ValidateScript({ $_.usrgrpid -ne $null})]
        # Groups to remove the users from
        [PSCustomObject[]] $UserGroup,
        
        [Parameter(Mandatory=$True, ParameterSetName="Ids",Position=0)]
        # Groups to remove the users from
        [int[]] $UserGroupId
    )

    begin
    {
        $prms = @()
        $groupids = @()
        if ($PSCmdlet.ParameterSetName -eq "Objects")
        {
            $UserGroup |% { $groupids += $_.usrgrpid}
        }
        else 
        {
             $groupids += $UserGroupId
        }
    }
    process
    {
        foreach ($uid in $UserId)
        {
            $User = Get-ZbxUser -session $s -id $uid
            $grps = @()
            $existingGid = @($User.usrgrps.usrgrpid)
            $removedGid = @()
            $remainingGid = @()

            foreach ($gid in $existingGid)
            {
                if (($gid -in $groupids))
                {
                    $removedGid += $gid
                }
                else 
                {
                    $remainingGid += $gid
                }
            }

            if ($removedGid.count -eq 0)
            {
                # already absent from requested groups
                continue
            }

            foreach($gid in $remainingGid)
            {
                $grps += @{usrgrpid = $gid}
            }

            $prms = @{
                userid = $User.userid
                usrgrps = $grps
            }
            # Sad, but not mass API.
            Invoke-ZbxZabbixApi $session "user.update"  $prms | Select-Object -ExpandProperty userids
        }
    }
}

