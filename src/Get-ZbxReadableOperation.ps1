function Get-ZbxReadableOperation 
{
    param([Parameter(Mandatory=$True, ValueFromPipeline=$true )]$op)
    Process
    {
        $res = New-Object psobject -Property @{
            OperationId = $_.operationid
            OperationType = $ActOpType[[int]$_.operationtype]
            EscalationPeriodSecond = $_.esc_period
            EscalationStartStep = $_.esc_step_from
            EscalationEndStep = $_.esc_step_to
            ConditionEvaluationMethod = $ActConditionEvalMethod[[int]$_.evaltype]
            MessageSubject = if($_.opmessage) {$_.opmessage.subject} else {$null}
            MessageContent = if($_.opmessage) {$_.opmessage.message} else {$null}
            MessageSendToGroups = $_.opmessage_grp | select usrgrpid
            MessageSendToUsers = $_.opmessage_usr | select userid
            CommandType = if($_.opcommand -ne $null) { $ActOpCmd[[int]$_.opcommand.type] } else {$null}
            Command = if($_.opcommand -ne $null) { $_.opcommand.command } else {$null}
            CommandUserName = if($_.opcommand -ne $null) { $_.opcommand.username } else {$null}
            CommandGlobalScriptId = if($_.opcommand -ne $null) { $_.opcommand.scriptid } else {$null}
            CommandExecuteOn = if($_.opcommand -ne $null) { $ActOpExecuteOn[[int]$_.opcommand.execute_on] } else {$null}
        }
        $res.PSTypeNames.Insert(0,"ZabbixActionOperation")
        $res
    }
}

