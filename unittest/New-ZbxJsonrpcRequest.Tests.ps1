BeforeAll {
    . $PSScriptRoot/../src/New-ZbxJsonrpcRequest.ps1
}

Describe "New-ZbxJsonrpcRequest" {
    It "Assembles a fully specified jsonrpc body" {
        $resultJSON = New-ZbxJsonrpcRequest -method "maintenance.get" -params @{ "output" = "extend"; "selectGroups" = "extend"; "selectTimeperiods" = "extend" } -auth "038e1d7b1735c6a5436ee9eae095879e"

        $resultHash = ConvertFrom-Json $resultJSON

        $resultHash.method | Should -Be "maintenance.get"
        $resultHash.params.output | Should -Be "extend"
        $resultHash.params.selectGroups | Should -Be "extend"
        $resultHash.params.selectTimeperiods | Should -Be "extend"
        $resultHash.auth | Should -Be "038e1d7b1735c6a5436ee9eae095879e"
    }

    It "Defaults the output param to 'extend' on '*.get' methods" {
        $resultJSON = New-ZbxJsonrpcRequest -method "maintenance.get" -params @{ "selectGroups" = "extend"; "selectTimeperiods" = "extend" } -auth "038e1d7b1735c6a5436ee9eae095879e"

        $resultHash = ConvertFrom-Json $resultJSON

        $resultHash.params.output | Should -Be "extend"
    }

    It "Handles auth as an optional parameter" {
        $resultJSON = New-ZbxJsonrpcRequest -method "apiinfo.version" -params @{ "selectGroups" = "extend"; "selectTimeperiods" = "extend" }

        $resultObj = ConvertFrom-Json $resultJSON

        $resultObj.psobject.properties.Name -contains "auth" | should -be $false
    }

    It "Contructs the params element as an array instead of hashtable, if instructed" {
        $resultJSON = New-ZbxJsonrpcRequest -method "maintenance.delete" -params @{ "array" = @(1,2)}

        $resultObj = ConvertFrom-Json $resultJSON

        $resultObj.params[0] | Should -BeExactly 1
        $resultObj.params.Count | Should -BeExactly 2
    }
}