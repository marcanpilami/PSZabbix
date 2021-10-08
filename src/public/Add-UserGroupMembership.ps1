function Add-UserGroupMembership
{
    <#
    .SYNOPSIS
    Make a user (or multiple users) member of one or more user groups.

    .DESCRIPTION
    This is additional: existing membership to other groups are not changed.

    .INPUTS
    This function accepts ZabbixUser objects or user IDs from the pipe. Equivalent to using -UserId parameter.

    .OUTPUTS
    The ID of the changed objects.

    .EXAMPLE
    PS> Get-User | Add-UserGroupMembership (Get-UserGroup group1),(Get-UserGroup group2)
    10084
    10085

    Add two groups to all users.

    .NOTES
    Very slow when modifying many users as there is no "mass update" API for this operation in Zabbix.
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$True, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)][Alias("Id", "User")]
        [ValidateNotNullOrEmpty()]
        # User to add to the group
        [int[]] $UserId,

        [Parameter(Mandatory=$True, ParameterSetName="Objects", Position=0)][ValidateScript({ $_.usrgrpid -ne $null})]
        # Group to add the user to
        [PSCustomObject[]] $UserGroup,

        [Parameter(Mandatory=$True, ParameterSetName="Ids",Position=0)]
        # Group to add the user to
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
            $User = Get-User -session $s -id $uid
            $grps = @()
            $existingGid = @($User.usrgrps.usrgrpid)
            $addedGid = @()

            foreach ($gid in $groupids)
            {
                if (-not ($gid -in $existingGid))
                {
                    $addedGid += $gid
                }
            }

            if ($addedGid.count -eq 0)
            {
                # already in requested groups
                continue
            }

            $addedGid += $existingGid
            foreach($gid in $addedGid)
            {
                $grps += @{usrgrpid = $gid}
            }

            $prms = @{
                userid = $User.userid
                usrgrps = $grps
            }
            # Sad, but not mass API.
            Invoke-ZabbixApi $session "user.update"  $prms | Select-Object -ExpandProperty userids
        }
    }
}
