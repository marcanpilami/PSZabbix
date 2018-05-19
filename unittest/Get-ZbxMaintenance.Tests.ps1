. ..\src\Get-ZbxMaintenance.ps1
. ..\src\InternalZabbixTypes.ps1

Describe "Get-ZbxMaintenance" {
    function Invoke-ZbxZabbixApi {} # declare it so I can mock it

    Context "Parameter scenarios" {
        Mock Invoke-ZbxZabbixApi { 
            param ($session, $method, [hashtable] $prms)
            #
            # Just return the params for inspection - not a mock Zabbix result
            # Set Status and HostID to avoid exception in the Get-ZbxHost function
            #
            $prms["Status"] = 1
            $prms["hostId"] = 123
            $prms["method"] = $method
            $prms
        }

        It "Is called with Id parameter" {

            $result = Get-ZbxMaintenance -Id 1

            $result.ContainsKey("maintenanceids") | Should -be $true
            $result["method"] | Should -be "maintenance.get"
        }

        It "Is called with MaintenanceId alias" {

            $result = Get-ZbxMaintenance -MaintenanceId 2

            $result.ContainsKey("maintenanceids") | Should -be $true
            $result["method"] | Should -be "maintenance.get"
        }

        It "Is called with HostGroupId parameter" {

            $result = Get-ZbxMaintenance -HostGroupId 3

            $result.ContainsKey("groupids") | Should -be $true
            $result["method"] | Should -be "maintenance.get"
        }

        It "Is called with HostId parameter" {

            $result = Get-ZbxMaintenance -HostId 4

            $result.ContainsKey("hostids") | Should -be $true
            $result["method"] | Should -be "maintenance.get"
        }

    }
}