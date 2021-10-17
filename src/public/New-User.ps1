function New-User
{
    <#
    .SYNOPSIS
    Create a new user.

    .DESCRIPTION
    Create a new user.

    .INPUTS
    This function accepts a ZabbixUser as pipe input, or any object which properties map the function parameters.

    .OUTPUTS
    The ZabbixUser object created.

    .EXAMPLE
    PS> New-User -Alias "login1" -name "marsu" -UserGroupId (get-group "GROUPNAME*").id
    userid alias           name                 surname              usrgrpsnames
    ------ -----           ----                 -------              ------------
        19 login1          marsu                                     GROUPNAME1,GROUPNAME2,GROUPNAME3

    Create a user from scratch.

    .EXAMPLE
    PS> $u = New-User -Alias "login1" -name "marsu" -UserGroupId (get-group "GROUPNAME*").id
    PS> $u | New-User -alias "login2"
    userid alias           name                 surname              usrgrpsnames
    ------ -----           ----                 -------              ------------
        20 login2          marsu                                     GROUPNAME1,GROUPNAME2,GROUPNAME3

    Copy a user.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUserNameAndPassWordParams", "")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "")]
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$true, ParameterSetName = "login_withgroupid")]
        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$true, ParameterSetName = "login_withgroupobject")]
        [Alias("Login")]
        # Login of the new user. Must be unique.
        [string] $Alias,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true, ParameterSetName = "login_withgroupid")]
        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true, ParameterSetName = "login_withgroupobject")]
        [Alias("Pwd", "passwd")]
        # Password of the new user. If not specified, a long random string is used (useful if authenticated
        # against a LDAP, as in that case the internal Zabbix password is not used).
        [string] $Password = $null,

        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$true, ParameterSetName = "pscred_withgroupid")]
        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$true, ParameterSetName = "pscred_withgroupobject")]
        # A Credential (from Get-Credential or other source) object containing both login and password for the new user.
        [PSCredential][System.Management.Automation.Credential()] $Credential,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true)]
        # Display name of the new user. If not given, the Alias is used.
        [string] $Name,

        [Parameter(Mandatory=$False, ValueFromPipelineByPropertyName=$true )]
        # Type of user. Default is simple user.
        [ZbxUserType] $UserType = [ZbxUserType]::User,

        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$true, ParameterSetName = "login_withgroupid")]
        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$true, ParameterSetName = "pscred_withgroupid")]
        [ValidateNotNullOrEmpty()][Alias("UsrGrpId")]
        # The ID of the groups the new user belongs to.
        [int[]] $UserGroupId,

        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$true, ParameterSetName = "login_withgroupobject")]
        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyName=$true, ParameterSetName = "pscred_withgroupobject")]
        [ValidateNotNullOrEmpty()][ValidateScript({ $_.usrgrpid -ne $null})]
        [Alias("UsrGrps")]
        # The groups the new user belongs to.
        [object[]] $UserGroup,

        [Parameter(Mandatory=$False)]
        # Mail adress to send alerts to
        [string] $MailAddress,

        [Parameter(Mandatory=$False)]
        # A severity mask for alerts. Only used if $MailAdress is specified. Default is Disaster,High
        [ZbxSeverity] $AlertOn = [ZbxSeverity]::Disaster -bor [ZbxSeverity]::High
    )

    begin
    {
        $prms = @{}
        $media = @()
        if ($MailAddress -ne $null)
        {
            $media += @{
                mediatypeid = @(Get-MediaType -Type email)[0].mediatypeid
                sendto = $MailAddress
                active = [int][ZbxStatus]::Enabled
                severity = $AlertOn
                period = "1-7,00:00-24:00"
            }
        }
    }
    process
    {
        $usergrps = @()
        if ($PSCmdlet.ParameterSetName -in "login_withgroupid", "pscred_withgroupid")
        {
            $UserGroupId |% { $usergrps += @{usrgrpid = $_} }
        }
        else
        {
            $usergrps += $UserGroup
        }

        if ($PSCmdlet.ParameterSetName -in "pscred_withgroupid", "pscred_withgroupobject")
        {
            $Alias = $Credential.GetNetworkCredential().UserName
            $Pp = $Credential.GetNetworkCredential().Password
        }

        $prms += @{
            alias = $Alias
            name = if ($Name -ne $null) { $Name } else {$Alias}
            type = [int]$UserType
            passwd = if ($Password -ne $null) {$Password} else { "" + (Get-Random -Maximum ([long]::MaxValue)) }
            usrgrps = $usergrps
            user_medias = $media
        }
    }
    end
    {
        if ($prms.Count -eq 0) { return }
        $id = Invoke-ZabbixApi $session "user.create"  $prms
        Get-User -Session $Session -Id $id.userids
    }
}
