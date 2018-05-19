function Get-ZbxAction 
{
    <#
    .SYNOPSIS
    Retrieve and filter users.
    
    .DESCRIPTION
    Query all actions with many filters, or get all actions. 

    .INPUTS
    This function does not take pipe input.

    .OUTPUTS
    The ZabbixAction objects corresponding to the filter.

    .EXAMPLE
    PS> Get-ZbxAction
    Actionid Name                           def_shortdata        OperationsReadable
    -------- ----                           -------------        ------------------
           2 Auto discovery. Linux servers.                      {@{ConditionEvaluat...
           3 Report problems to Zabbix a... {TRIGGER.STATUS}:... {@{ConditionEvaluat...
           4 Report not supported items     {ITEM.STATE}: {HO... {@{ConditionEvaluat...
           5 Report not supported low le... {LLDRULE.STATE}: ... {@{ConditionEvaluat...
           6 Report unknown triggers        {TRIGGER.STATE}: ... {@{ConditionEvaluat...
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ZbxApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [Parameter(Mandatory=$False)][Alias("ActionId")]
        # Only retrieve the action with the given ID
        [int[]] $Id,
        
        [Parameter(Mandatory=$False)]
        # Only retrieve actions which use the following hosts in their conditions
        [int[]] $HostId,

        [Parameter(Mandatory=$False)]
        # Only retrieve actions which use the following groups in their conditions
        [int[]] $HostGroupId,

        [Parameter(Mandatory=$False)]
        # Only retrieve actions which use the following triggers in their conditions
        [int[]] $TriggerId,

        [Parameter(Mandatory=$False)]
        # Only retrieve actions which send messages to these users
        [int[]] $UserId,

        [Parameter(Mandatory=$False)][Alias("UsergrpId")]
        # Only retrieve actions which send messages to these user groups
        [int[]] $UserGroupId,

        [Parameter(Mandatory=$False, Position=0)][Alias("ActionName")]
        # Filter by name
        [string] $Name
    )
    $prms = @{searchWildcardsEnabled=1; selectConditions = "extend"; selectOperations = "extend"; search= @{}}
    if ($Id.Length -gt 0) {$prms["actionids"] = $Id}
    if ($HostId.Length -gt 0) {$prms["hostids"] = $HostId}
    if ($HostGroupId.Length -gt 0) {$prms["groupids"] = $HostGroupId}
    if ($TriggerId.Length -gt 0) {$prms["triggerids"] = $TriggerId}
    if ($UserId.Length -gt 0) {$prms["userids"] = $UserId}
    if ($UserGroupId.Length -gt 0) {$prms["usrgrpids"] = $UserGroupId}
    if ($Name -ne $null) {$prms["search"]["name"] = $Name}
    $res = Invoke-ZbxZabbixApi $session "action.get"  $prms
    $res |% { $action = $_; $action | Add-Member -NotePropertyName "OperationsReadable" -notepropertyvalue @($action.operations | Get-ZbxReadableOperation) }
    $res |% {$_.PSTypeNames.Insert(0,"ZabbixAction")}
    $res
}
