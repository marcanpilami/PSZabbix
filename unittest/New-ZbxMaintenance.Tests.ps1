BeforeAll {
    . $PSScriptRoot\..\src\InternalTimeHelpers.ps1
    . $PSScriptRoot\..\src\New-ZbxMaintenance.ps1
}


Describe "New-ZbxMaintenance" {
    function Invoke-ZbxZabbixApi {} # declare it so I can mock it

    Context "Parameter scenarios" {
        Mock Invoke-ZbxZabbixApi { 
            param ($session, $method, [hashtable] $prms)
            #
            # Just return the params for inspection - not a mock Zabbix result
            #
            $prms["method"] = $method
            $prms
        }

        It "Is called with HostGroupId parameter" {

            $result = New-ZbxMaintenance -HostGroupId 3 -Name "Patch Tuesday"

            $result.ContainsKey("groupids") | Should -be $true
            $result["groupids"][0] | Should -BeExactly 3 
            $result["method"] | Should -be "maintenance.create"
            $result["method"] | Should -be "maintenance.create"
        }

        It "Check that the Name parameter is populated" {

            { New-ZbxMaintenance -HostGroupId 3 -Name "" } | Should -Throw
        }

        It "Populates the Name parameter" {

            $result = New-ZbxMaintenance -HostGroupId 3 -Name "Patch Tuesday"

            $result.ContainsKey("name") | Should -be $true
            $result["method"] | Should -be "maintenance.create"
            $result["name"] | Should -be "Patch Tuesday"
        }

        It "Is called with HostId parameter" {

            $result = New-ZbxMaintenance -HostId 4 -Name "Patch Tuesday"

            $result.ContainsKey("hostids") | Should -be $true
            $result["hostids"][0] | Should -BeExactly 4
            $result["method"] | Should -be "maintenance.create"
        }

        It "Is called with multiple HostId parameters" {

            $result = New-ZbxMaintenance -HostId 4,5,6 -Name "Patch Tuesday"

            $result.ContainsKey("hostids") | Should -be $true
            $result["hostids"].Count | Should -BeExactly 3
            $result["method"] | Should -be "maintenance.create"
        }

        It "requires one or the other of the -HostId and -HostGroupId parameters" {

            { New-ZbxMaintenance  -Name "Patch Tuesday" } | Should -Throw
        
        }

        It "is called with the -StartTime parameter" {

            $thisTime = Get-Date -Year 2000 -Month 1 -Day 1
            $thisEpoch = ConvertTo-EpochTime $thisTime

            $result = New-ZbxMaintenance -HostId 4 -Name "Patch Tuesday" -StartTime $thisTime

            $StartTime = $result["active_since"]
            $StartTime | should -be $thisEpoch
        }

        It "is called with the -Duration parameter" {
            $thisTime = Get-Date -Year 2000 -Month 1 -Day 1
            $thisDurationInSeconds = 123
            $thisDuration = New-TimeSpan -Seconds $thisDurationInSeconds

            $result = New-ZbxMaintenance -HostId 4 -Name "Patch Tuesday" -StartTime $thisTime -Duration $thisDuration

            $StopTime = $result["active_till"]
            $StartTime = $result["active_since"]
            $TimeDelta = $StopTime - $StartTime
            $TimeDelta | Should -be $thisDurationInSeconds
        }

        It "Defaults the StartTime parameter to now" {

            $NowStamp = Get-Date

            $result = New-ZbxMaintenance -HostId 4 -Name "Patch Tuesday"

            $result.ContainsKey("timeperiods") | Should -be $true
            $result.ContainsKey("active_till") | Should -be $true
            $result.ContainsKey("active_since") | Should -be $true

            $StartTimeEpoch = $result["active_since"]
            $NowStampEpoch = ConvertTo-EpochTime $NowStamp
            $StartTimeEpoch | Should -BeExactly $NowStampEpoch
        }

        It "Defaults the -Duration parameter to one hour" {

            $result = New-ZbxMaintenance -HostId 4 -Name "Patch Tuesday"

            $StopTime = $result["active_till"]
            $StartTime = $result["active_since"]
            $TimeDelta = $StopTime - $StartTime
            $AnHoursWorthOfSeconds = $(New-TimeSpan -Hours 1).TotalSeconds
            $TimeDelta | Should -be $AnHoursWorthOfSeconds
        }

    }
}