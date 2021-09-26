BeforeAll {
    . ..\src\New-ZbxJsonrpcRequest.ps1
    . ..\src\Get-ZbxApiVersion.ps1    
}

Describe "Get-ZbxApiVersion" {
    BeforeAll {
        function HashVersionFromUri([string]$theUri)
        {
            $bytes = [System.Security.Cryptography.HashAlgorithm]::Create("MD5").ComputeHash([System.Text.Encoding]::UTF8.GetBytes($theUri))
            $version = 0
            $bytes | Foreach-Object { $version += $_ }
            $version
        }
    
        $uri_1 = "http://1.1.1.1/"
        $ver_1 = HashVersionFromUri $uri_1
        $uri_2 = "http://2.2.2.2/"
        $ver_2 = HashVersionFromUri $uri_2
    
        Mock Invoke-RestMethod {
            param($Uri, $Method, $ContentType, $Body)
            $version = HashVersionFromUri $Uri
            @{jsonrpc=2.0; result=$version; id=1}
        }
    
    }

    BeforeEach {
        $script:LatestSession = @{Uri = $uri_1; Auth = "dummy_token"}            
    }
    
    AfterEach {
        Remove-Variable -Scope script -Name LatestSession
    }

    Context "Session parameter set" {
           
        It "Defaults to Session parameter set by position" {
            $version = Get-ZbxApiVersion  @{Uri = $uri_2; Auth = "dummy_token"}
            $version | should -Be $ver_2
        }

        It "Session parameter is specified explicitly" {
            $version = Get-ZbxApiVersion -Session @{Uri = $uri_2; Auth = "dummy_token"}
            $version | should -Be $ver_2
        }

        It "Session is picked up implicitly from the environment" {
            $version = Get-ZbxApiVersion
            $version | should -Be $ver_1
        }

    }

    Context "Direct parameter set" {
        
        It "Ignores existing session variable when the direct parameter is used" {
            $version = Get-ZbxApiVersion -Uri $uri_2
            $version | should -Be $ver_2    
        }
    }
}