BeforeAll {
    . $PSScriptRoot/../../src/private/New-JsonrpcRequest.ps1
    . $PSScriptRoot/../../src/private/Get-ApiVersion.ps1
    . $PSScriptRoot/../../src/public/New-ApiSession.ps1
}


Describe "New-ApiSession" {
    BeforeAll {
        $PhonyUser = "nonUser"
        $PhonyPassword = "nonPassword" | ConvertTo-SecureString -AsPlainText -Force
        $PhonyCreds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $PhonyUser,$PhonyPassword
        $PhonyUri = "http://myserver/zabbix/api_jsonrpc.php"
        $PhonyAuth = "2cce0ad0fac0a5da348fdb70ae9b233b"
    }

    Context "Web Exceptions" {
        BeforeAll {
            Mock Invoke-RestMethod {
                throw "The remote name could not be resolved: 'myserver'"
            }
        }

        It "Bubbles up exceptions from Rest calls" {
            { New-ApiSession "http://myserver" $PhonyCreds } | Should -Throw
        }
    }

    Context "Supported version of Zabbix" {
        BeforeAll {
            Mock Invoke-RestMethod {
                @{jsonrpc=2.0; result=$PhonyAuth; id=1}
            }
            Mock Get-ApiVersion {
                "3.2"
            }
            Mock Write-Information {}
            Mock Write-Warning {}
        }

        It "Checks Zabbix version and writes a success message" {

            $session = New-ApiSession $PhonyUri $PhonyCreds

            $session["Uri"] | Should -Be $PhonyUri
            $session["Auth"] | Should -Be $PhonyAuth
            Should -Invoke Write-Information -Times 1 -Exactly -Scope It
            Should -Invoke Write-Warning     -Times 0 -Exactly -Scope It
        }

        It "Writes no information messages if the silent switch is specified" {

            $session = New-ApiSession $PhonyUri $PhonyCreds -silent

            Should -Invoke Write-Information -Times 0 -Exactly -Scope It # no increment in call count since last test
        }

    }

    Context "Successful connection - unsupported version" {
        BeforeAll {
            Mock Invoke-RestMethod {
                @{jsonrpc=2.0; result=$PhonyAuth; id=1}
            }
            Mock Get-ApiVersion {
                "1.2"
            }
            Mock Write-Information {}
            Mock Write-Warning {}
        }

        It "Checks Zabbix version and writes a warning message if the version is unsupported" {

            $session = New-ApiSession $PhonyUri $PhonyCreds

            $session["Uri"] | Should -Be $PhonyUri
            $session["Auth"] | Should -Be $PhonyAuth
            Should -Invoke Write-Information -Times 1 -Exactly -Scope It
            Should -Invoke Write-Warning -Times 1 -Exactly -Scope It
        }
    }
}
