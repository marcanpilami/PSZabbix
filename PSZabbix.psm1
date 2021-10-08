$ErrorActionPreference = "Stop"
$latestSession = $null

$Private = @( Get-ChildItem -Path $PSScriptRoot/src/Private/*.ps1 -ErrorAction SilentlyContinue )
$Public = @( Get-ChildItem -Path $PSScriptRoot/src/Public/*.ps1 -ErrorAction SilentlyContinue )


#Dot source the files
Foreach ($import in @($Public + $Private)) {
    Try {
        . $import.fullname
    } Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}