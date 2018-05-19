. ..\src\New-ZbxJsonrpcRequest.ps1
. ..\src\Get-ZbxApiVersion.ps1
. ..\src\New-ZbxApiSession.ps1

Describe "New-ZbxApiSession" {
    
    $PhonyUser = "nonUser"
    $PhonyPassword = "nonPassword" | ConvertTo-SecureString -AsPlainText -Force
    $PhonyCreds = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $PhonyUser,$PhonyPassword
    $PhonyUri = "http://myserver/zabbix/api_jsonrpc.php"
    $PhonyAuth = "2cce0ad0fac0a5da348fdb70ae9b233b"

    Context "Web Exceptions" {
        Mock Invoke-RestMethod {
            throw "The remote name could not be resolved: 'myserver'"
        }

        It "Bubbles up exceptions from Rest calls" {
            { New-ZbxApiSession "http://myserver" $PhonyCreds } | should throw
        }
    }

    Context "Supported version of Zabbix" {
        Mock Invoke-RestMethod {
            @{jsonrpc=2.0; result=$PhonyAuth; id=1}
        }
        Mock Get-ZbxApiVersion {
            "3.2"
        }
        Mock Write-Information {}
        Mock Write-Warning {}

        It "Checks Zabbix version and writes a success message" {
            
            $session = New-ZbxApiSession $PhonyUri $PhonyCreds

            $session["Uri"] | should Be $PhonyUri
            $session["Auth"] | should Be $PhonyAuth
            Assert-MockCalled Write-Information -Times 1 -Exactly
            Assert-MockCalled Write-Warning -Times 0 -Exactly    
        }

        It "Writes no information messages if the silent switch is specified" {
            
            $session = New-ZbxApiSession $PhonyUri $PhonyCreds -silent

            Assert-MockCalled Write-Information -Times 1 -Exactly  # no increment in call count since last test
        }

    }

    Context "Successful connection - unsupported version" {
        Mock Invoke-RestMethod {
            @{jsonrpc=2.0; result=$PhonyAuth; id=1}
        }
        Mock Get-ZbxApiVersion {
            "1.2"
        }
        Mock Write-Information {}
        Mock Write-Warning {}

        It "Checks Zabbix version and writes a warning message if the version is unsupported" {

            $session = New-ZbxApiSession $PhonyUri $PhonyCreds

            $session["Uri"] | should Be $PhonyUri
            $session["Auth"] | should Be $PhonyAuth
            Assert-MockCalled Write-Information -Times 1 -Exactly
            Assert-MockCalled Write-Warning -Times 1 -Exactly    
        }
    }
}
