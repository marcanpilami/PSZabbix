. ..\src\Get-ZbxHost.ps1
. ..\src\InternalZabbixTypes.ps1

Describe "Get-ZbxHost" {
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

            $result = Get-ZbxHost -Id 1

            $result.ContainsKey("hostids") | Should -be $true
            $result["method"] | Should -be "host.get"
        }

        It "Is called with HostId alias" {

            $result = Get-ZbxHost -HostId 2

            $result.ContainsKey("hostids") | Should -be $true
            $result["method"] | Should -be "host.get"
        }

        It "Is called with HostGroupId parameter" {

            $result = Get-ZbxHost -HostGroupId 3

            $result.ContainsKey("groupids") | Should -be $true
            $result["method"] | Should -be "host.get"
        }

        It "Is called with Name parameter" {

            $result = Get-ZbxHost -Name "dummyID"

            $result["search"].ContainsKey("name") | Should -be $true
            $result["method"] | Should -be "host.get"
        }

        It "Is called with HostName alias" {

            $result = Get-ZbxHost -HostName "dummyID"

            $result["search"].ContainsKey("name") | Should -be $true
            $result["method"] | Should -be "host.get"
        }
    }
}