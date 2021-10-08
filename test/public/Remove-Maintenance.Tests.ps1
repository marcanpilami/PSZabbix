BeforeAll {
    . $PSScriptRoot/../../src/public/Remove-Maintenance.ps1
}


Describe "Remove-Maintenance" {
    BeforeAll {
		function Invoke-ZabbixApi {} # declare it so I can mock it
	}

    Context "Parameter scenarios" {
        BeforeAll {
            Mock Invoke-ZabbixApi {
                param ($session, $method, [hashtable] $prms)
                #
                # Just return the params for inspection - not a mock Zabbix result
                # Set Status and HostID to avoid exception in the Get-Host function
                #
                $prms["Status"] = 1
                $prms["hostId"] = 123
                $prms["method"] = $method
                $prms
            }
        }

        It "Is called with Id parameter" {

            $result = Remove-Maintenance -Id 1

            $result["array"][0] | Should -BeExactly 1
            $result["method"] | Should -be "maintenance.delete"
        }

        It "Is called with MaintenanceId alias" {

            $result = Remove-Maintenance -MaintenanceId 2

            $result["array"][0] | Should -BeExactly 2
            $result["method"] | Should -be "maintenance.delete"
        }

        It "Is called with multiple maintenance Ids" {

            $result = Remove-Maintenance -MaintenanceId 1,2,3

            $($result["array"]).Count | Should -BeExactly 3
            $result["method"] | Should -be "maintenance.delete"
        }

        It "Throws if called with empty array of Ids" {

            { Remove-Maintenance -MaintenanceId $() } | Should -Throw

        }
    }
}