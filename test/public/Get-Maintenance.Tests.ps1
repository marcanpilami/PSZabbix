BeforeAll {
    . $PSScriptRoot/../../src/public/Get-Maintenance.ps1
    . $PSScriptRoot/../../src/private/InternalZabbixTypes.ps1
}


Describe "Get-Maintenance" {
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

            $result = Get-Maintenance -Id 1

            $result.ContainsKey("maintenanceids") | Should -be $true
            $result["method"] | Should -be "maintenance.get"
        }

        It "Is called with MaintenanceId alias" {

            $result = Get-Maintenance -MaintenanceId 2

            $result.ContainsKey("maintenanceids") | Should -be $true
            $result["method"] | Should -be "maintenance.get"
        }

        It "Is called with HostGroupId parameter" {

            $result = Get-Maintenance -HostGroupId 3

            $result.ContainsKey("groupids") | Should -be $true
            $result["method"] | Should -be "maintenance.get"
        }

        It "Is called with HostId parameter" {

            $result = Get-Maintenance -HostId 4

            $result.ContainsKey("hostids") | Should -be $true
            $result["method"] | Should -be "maintenance.get"
        }

    }
}