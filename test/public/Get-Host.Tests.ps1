BeforeAll {
    . $PSScriptRoot/../../src/public/Get-Host.ps1
    . $PSScriptRoot/../../src/public/InternalZabbixTypes.ps1
}


Describe "Get-Host" {
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

            $result = Get-Host -Id 1

            $result.ContainsKey("hostids") | Should -be $true
            $result["method"] | Should -be "host.get"
        }

        It "Is called with HostId alias" {

            $result = Get-Host -HostId 2

            $result.ContainsKey("hostids") | Should -be $true
            $result["method"] | Should -be "host.get"
        }

        It "Is called with HostGroupId parameter" {

            $result = Get-Host -HostGroupId 3

            $result.ContainsKey("groupids") | Should -be $true
            $result["method"] | Should -be "host.get"
        }

        It "Is called with Name parameter" {

            $result = Get-Host -Name "dummyID"

            $result["search"].ContainsKey("name") | Should -be $true
            $result["method"] | Should -be "host.get"
        }

        It "Is called with HostName alias" {

            $result = Get-Host -HostName "dummyID"

            $result["search"].ContainsKey("name") | Should -be $true
            $result["method"] | Should -be "host.get"
        }
    }
}