BeforeAll {
    . $PSScriptRoot\..\src\New-ZbxJsonrpcRequest.ps1
    . $PSScriptRoot\..\src\Invoke-ZbxZabbixApi.ps1
}

Describe "Invoke-ZabbixApi" {
    BeforeEach {
        $script:LatestSession = @{Uri = "LatestSession"; Auth = "dummy_token"}            
    }
    
    AfterEach {
        Remove-Variable -Scope script -Name LatestSession
    }

    Context "Web Exceptions" {
        BeforeAll {
            Mock Invoke-RestMethod {
                throw "The remote name could not be resolved: 'myserver'"
            }
        }
        It "Bubbles up exceptions from Rest calls" {
            { Invoke-ZbxZabbixApi "http://myserver" $PhonyCreds } | Should -Throw
        }
    }

    Context "Session variable situations" {
        BeforeAll {
            Mock Invoke-RestMethod {
                param($Uri, $Method, $ContentType, $Body)
                @{jsonrpc=2.0; result=$Uri; id=1} # hack - pass the uri back as auth so we can see which session varible was used.
            }
            Mock New-ZbxJsonrpcRequest {}    
        }

        It "Uses the session parameter if provided" {
            $result = Invoke-ZbxZabbixApi -Session @{Uri = "ParamSession"} -method "some.method" -parameters @{"dummy" = "parameters"}
            $result | Should -Be "ParamSession"
        }

        It "Uses the lastsession global if session parameter is null" {
            $result = Invoke-ZbxZabbixApi -Session $null -method "some.method" -parameters @{"dummy" = "parameters"}
            $result | Should -Be "LatestSession"
        }

        It "Throws if both session and lastsession are null" {
            Remove-Variable -Scope script -Name LatestSession
            { Invoke-ZbxZabbixApi -Session $null -method "some.method" -parameters @{"dummy" = "parameters"}} | Should -Throw
            $script:LatestSession = @{Uri = "LatestSession"; Auth = "dummy_token"} # put it back to appease test cleanup
        }
    }

    Context "Zabbix errors" {
        BeforeAll {
            Mock Invoke-RestMethod {
                @{"error"=@{"message"="error message"; "data"="error data";"code"="error code"}}
            }
            Mock New-ZbxJsonrpcRequest {}
            Mock Write-Error {}    
        }

        It "Writes an error and returns null if a Zabbix error is encountered" {
            $result = Invoke-ZbxZabbixApi -Session $null -method "some.method" -parameters @{"dummy" = "parameters"}
            $result | Should -Be $null
            Should -Invoke Write-Error -Times 1 -Exactly -Scope It
        } 
    }
}