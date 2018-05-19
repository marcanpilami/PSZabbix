function ConvertTo-EpochTime
{
    param 
    (
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [DateTime]
        $Date
    )

    # adapted from https://www.epochconverter.com/
    $dateString = Get-Date $Date.touniversaltime() -UFormat %s
    $epochResult = [int][double]::Parse($dateString)
    $epochResult
}

function ConvertFrom-EpochTime
{
    param 
    (
        # Parameter help description
        [Parameter(Mandatory=$true)]
        [int]
        $EpochTime
    )

    # adapted from https://www.epochconverter.com/
    [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($EpochTime))

}