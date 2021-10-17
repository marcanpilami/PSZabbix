function Remove-Template
{
    <#
    .SYNOPSIS
    Remove one or more templates from Zabbix.

    .DESCRIPTION
    Removal is immediate.

    .INPUTS
    This function accepts ZabbixTemplate objects or template IDs from the pipe. Equivalent to using -TemplateId parameter.

    .OUTPUTS
    The ID of the removed objects.

    .EXAMPLE
    Remove all templates
    PS> Get-Template | Remove-Template
    10084
    10085
    #>
    param
    (
        [Parameter(Mandatory=$False)]
        # A valid Zabbix API session retrieved with New-ApiSession. If not given, the latest opened session will be used, which should be enough in most cases.
        [Hashtable] $Session,

        [parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, Position=0)][ValidateNotNullOrEmpty()][Alias("Template")]
        # The templates to remove. Either template objects (with a templateid property) or directly IDs.
        [int[]]$TemplateId
    )

    begin
    {
        $prms = @()
    }
    process
    {
        $prms += $TemplateId
    }
    end
    {
        if ($prms.Count -eq 0) { return }
        Invoke-ZabbixApi $session "template.delete" $prms | Select-Object -ExpandProperty templateids
    }
}
