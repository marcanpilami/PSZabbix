BeforeAll {
    Try {
        $module = 'PSZabbix'
        $moduleRoot = "$PSScriptRoot/../../"
        # Import-Module $PSScriptRoot/../../$module.psd1
    } Catch {
        $e = $_
        Write-Warning "Error setup Tests $e $($_.exception)"
        Throw $e
    }
}
AfterAll {
    Remove-Module $module -ErrorAction SilentlyContinue
}

Describe -Tags ('Unit', 'Acceptance') "$module Module Tests" {

    Context 'Module Setup' {
        It "has the root module $module.psm1" {
            "$moduleRoot/$module.psm1" | Should -Exist
        }

        It "has the a manifest file of $module.psd1" {
            "$moduleRoot/$module.psd1" | Should -Exist
            "$moduleRoot/$module.psd1" | Should -FileContentMatch "$module.psm1"
        }

        It "$module is valid PowerShell code" {
            $psFile = Get-Content -Path "$moduleRoot/$module.psm1" -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
            $errors.Count | Should -Be 0
        }

        It "has every public function exported" {
            Import-Module $moduleRoot/$module.psd1 -ErrorAction Stop
            foreach ($file in Get-ChildItem "$moduleRoot/src/public/*.ps1") {
                # func name must include default module prefix
                $funcName = (Split-Path $file -Leaf) -replace '(\S+)-(\S*).ps1','$1-Zbx$2'
                (Get-Command -Module $module).Name | Should -Contain $funcName
            }
            Remove-Module $module -ErrorAction SilentlyContinue
        }
    }
}