[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()
BeforeAll {
    Try {
        $moduleName = 'PSZabbix'
        $moduleRoot = "$PSScriptRoot/../../"
        Import-Module $moduleRoot/$moduleName.psd1 -Force

        $global:baseUrl = $env:DEV_ZABBIX_API_URL
        if ('' -eq $global:baseUrl) {
            $global:baseUrl = "http://tools/zabbix/api_jsonrpc.php"
        }
        $secpasswd = ConvertTo-SecureString "zabbix" -AsPlainText -Force
        $global:admin = New-Object System.Management.Automation.PSCredential ("Admin", $secpasswd)
        
        $wrongsecpasswd = ConvertTo-SecureString "wrong" -AsPlainText -Force
        $global:admin2 = New-Object System.Management.Automation.PSCredential ("Admin", $wrongsecpasswd)
        
        $s = New-ZbxApiSession $baseUrl $global:admin -silent

        $testTemplate = Get-ZbxTemplate | Select-Object -First 1
        $testTemplateId = $testTemplate.templateid
    } Catch {
        $e = $_
        Write-Warning "Error setup Tests $e $($_.exception)"
        Throw $e
    }
    
}
AfterAll {
    Remove-Module $moduleName
}

Describe "New-ZbxApiSession" {
    BeforeAll {
        $session = New-ZbxApiSession $baseUrl $admin -silent        
    }

    It "connects to zabbix and returns a non-empty session object" {
        $session | Should -Not -Be $null
        $session["Uri"] | Should -Not -Be $null
        $session["Auth"] | Should -Not -Be $null
    }

    It "fails when URL is wrong" {
        { New-ZbxApiSession "http://localhost:12345/zabbix" $admin } | Should -Throw
    }

    It "fails when login/password is wrong" {
        { New-ZbxApiSession $baseUrl $admin2 } | Should -Throw
    }
}

Describe "New-ZbxHost" {
    It "can create an enabled host from explicit ID parameters" {
        $h = New-ZbxHost -Name "pestertesthost$(Get-Random)" -HostGroupId 2 -TemplateId $testTemplateId -Dns localhost
        $h | Should -Not -Be $null
        $h.status | Should -Be 0
    }
    It "can create an disabled host from explicit ID parameters" {
        $h = New-ZbxHost -Name "pestertesthost$(Get-Random)" -HostGroupId 2 -TemplateId $testTemplateId -Dns localhost -status disabled
        $h | Should -Not -Be $null
        $h.status | Should -Be 1
    }
    It "should throw if invalid Group or template Id" {
        { New-ZbxHost -Name "pestertesthost$(Get-Random)" -HostGroupId 2 -TemplateId 9999 -Dns localhost -status disabled } | Should -Throw
        { New-ZbxHost -Name "pestertesthost$(Get-Random)" -HostGroupId 9999 -TemplateId $testTemplateId -Dns localhost -status disabled } | Should -Throw
    }
}

Describe "Get-ZbxHost" {
    It "can return all hosts" {
        Get-ZbxHost | Should -Not -BeNullOrEmpty
    }
    It "can filter by name with wildcard (explicit parameter)" {
        Get-ZbxHost "pestertesthost*" | Should -Not -BeNullOrEmpty
        Get-ZbxHost "pestertesthostXXX*" | Should -BeNullOrEmpty
    }
    It "can filter by ID (explicit parameter)" {
        $h = (Get-ZbxHost "pestertesthost*")[0]
        (Get-ZbxHost -Id $h.hostid).host | Should -Be $h.host
    }
    It "can filter by group membership (explicit parameter)" {
        $h = (Get-ZbxHost "pestertesthost*")[0]
        (Get-ZbxHost -Id $h.hostid -HostGroupId 2).host | Should -Be $h.host
    }
}

Describe "Remove-ZbxHost" {
    BeforeEach {
        $h1 = New-ZbxHost -Name "pestertesthostrem" -HostGroupId 2 -TemplateId $testTemplateId -Dns localhost -errorAction silentlycontinue
        $h2 = New-ZbxHost -Name "pestertesthostrem2" -HostGroupId 2 -TemplateId $testTemplateId -Dns localhost -errorAction silentlycontinue
        # if the test before failed e.g. because the host already exists, New-Host returns $null
        if ($null -eq $h1) { $h1 = Get-ZbxHost "pestertesthostrem" }
        if ($null -eq $h2) { $h2 = Get-ZbxHost "pestertesthostrem2" }
    }
    AfterAll {
        remove-ZbxHost $h1.hostid, $h2.hostid -ErrorAction silentlycontinue
    }
    It "can delete from one explicit ID parameter" {
        remove-ZbxHost $h1.hostid | Should -Be $h1.hostid
    }
    It "can delete from multiple explicit ID parameters" {
        remove-ZbxHost $h1.hostid, $h2.hostid | Should -Be @($h1.hostid, $h2.hostid)
    }
    It "can delete from multiple piped IDs" {
        $h1.hostid, $h2.hostid | remove-ZbxHost | Should -Be @($h1.hostid, $h2.hostid)
    }
    It "can delete from one piped object parameter" {
        $h1 | remove-ZbxHost | Should -Be $h1.hostid
    }
    It "can delete from multiple piped objects" {
        $h1, $h2 | remove-ZbxHost | Should -Be @($h1.hostid, $h2.hostid)
    }
}

Describe "Disable-ZbxHost" {
    BeforeAll {
        New-ZbxHost -Name "pestertesthost1" -HostGroupId 2 -TemplateId $testTemplateId -Dns localhost -errorAction silentlycontinue
        New-ZbxHost -Name "pestertesthost2" -HostGroupId 2 -TemplateId $testTemplateId -Dns localhost -errorAction silentlycontinue
        $h1 = Get-ZbxHost pestertesthost1
        $h2 = Get-ZbxHost pestertesthost2
    }
    AfterAll {
        Remove-ZbxHost $h1.HostId,$h2.HostId
    }

    It "can enable multiple piped objects" {
        $h1, $h2 | Disable-ZbxHost | Should -Be @($h1.hostid, $h2.hostid)
        (Get-ZbxHost pestertesthost1).status | Should -Be 1
    }
    It "can enable multiple piped IDs" {
        $h1.hostid, $h2.hostid | Disable-ZbxHost | Should -Be @($h1.hostid, $h2.hostid)
        (Get-ZbxHost pestertesthost1).status | Should -Be 1
    }
    It "can enable multiple explicit parameter IDs" {
        Disable-ZbxHost $h1.hostid, $h2.hostid | Should -Be @($h1.hostid, $h2.hostid)
        (Get-ZbxHost pestertesthost1).status | Should -Be 1
    }
}

Describe "Enable-ZbxHost" {
    BeforeAll {
        New-ZbxHost -Name "pestertesthost1" -HostGroupId 2 -TemplateId $testTemplateId -Dns localhost -errorAction silentlycontinue
        New-ZbxHost -Name "pestertesthost2" -HostGroupId 2 -TemplateId $testTemplateId -Dns localhost -errorAction silentlycontinue
        $h1 = Get-ZbxHost pestertesthost1
        $h2 = Get-ZbxHost pestertesthost2
    }
    BeforeEach {
        Disable-ZbxHost $h1.hostid, $h2.hostid
    }
    AfterAll {
        Remove-ZbxHost $h1.HostId,$h2.HostId
    }

    It "can enable multiple piped objects" {
        $h1, $h2 | Enable-ZbxHost | Should -Be @($h1.hostid, $h2.hostid)
        (Get-ZbxHost pestertesthost1).status | Should -Be 0
    }
    It "can enable multiple piped IDs" {
        $h1.hostid, $h2.hostid | Enable-ZbxHost | Should -Be @($h1.hostid, $h2.hostid)
        (Get-ZbxHost pestertesthost1).status | Should -Be 0
    }
    It "can enable multiple explicit parameter IDs" {
        Enable-ZbxHost $h1.hostid, $h2.hostid | Should -Be @($h1.hostid, $h2.hostid)
        (Get-ZbxHost pestertesthost1).status | Should -Be 0
    }
}

Describe "Add-ZbxHostGroupMembership" {
    BeforeAll {
        New-ZbxHost -Name "pestertesthost1" -HostGroupId 2 -TemplateId $testTemplateId -Dns localhost -errorAction silentlycontinue
        New-ZbxHost -Name "pestertesthost2" -HostGroupId 2 -TemplateId $testTemplateId -Dns localhost -errorAction silentlycontinue
        $h1 = Get-ZbxHost pestertesthost1
        $h2 = Get-ZbxHost pestertesthost2
        New-ZbxHostGroup "pestertest1" -errorAction silentlycontinue
        New-ZbxHostGroup "pestertest2" -errorAction silentlycontinue
        $g1 = Get-ZbxHostGroup pestertest1
        $g2 = Get-ZbxHostGroup pestertest2
    }

    It "adds a set of groups given as a parameter to multiple piped hosts" {
        $h1, $h2 | Add-ZbxHostGroupMembership $g1, $g2
        (Get-ZbxHostGroup pestertest1).hosts.Count | Should -Be 2
    }
}

Describe "Remove-ZbxHostGroupMembership" {
    BeforeAll {
        New-ZbxHost -Name "pestertesthost1" -HostGroupId 2 -TemplateId $testTemplateId -Dns localhost -errorAction silentlycontinue
        New-ZbxHost -Name "pestertesthost2" -HostGroupId 2 -TemplateId $testTemplateId -Dns localhost -errorAction silentlycontinue
        $h1 = Get-ZbxHost pestertesthost1
        $h2 = Get-ZbxHost pestertesthost2
        New-ZbxHostGroup "pestertest1" -errorAction silentlycontinue
        New-ZbxHostGroup "pestertest2" -errorAction silentlycontinue
        $g1 = Get-ZbxHostGroup pestertest1
        $g2 = Get-ZbxHostGroup pestertest2
    }

    It "removes a set of groups given as a parameter to multiple piped hosts" {
        $h1, $h2 | Remove-ZbxHostGroupMembership $g1, $g2
        (Get-ZbxHostGroup pestertest1).hosts.Count | Should -Be 0
    }
}

Describe "Get-ZbxTemplate" {
    It "can return all templates" {
        Get-ZbxTemplate | Should -Not -BeNullOrEmpty
    }
    It "can filter by name with wildcard (explicit parameter)" {
        Get-ZbxTemplate "Template OS Lin*" | Should -Not -BeNullOrEmpty
        Get-ZbxTemplate "XXXXXXXXXXXXXX" | Should -BeNullOrEmpty
    }
    It "can filter by ID (explicit parameter)" {
        $h = (Get-ZbxTemplate "Template OS Lin*")[0]
        (Get-ZbxTemplate -Id $h.templateid).host | Should -Be $h.host
    }      
}

Describe "New-ZbxHostGroup" {
    It "creates a new group with explicit name parameter" {
        $g = New-ZbxHostGroup "pestertest$(Get-Random)", "pestertest$(Get-Random)"
        $g.count | Should -Be 2
        $g[0].name | Should -Match "pestertest"
    }
    It "creates a new group with piped names" {
        $g = "pestertest$(Get-Random)", "pestertest$(Get-Random)" | New-ZbxHostGroup
        $g.count | Should -Be 2
        $g[0].name | Should -Match "pestertest"
    }
    It "creates a new group with piped objects" {
        $g = (New-Object -TypeName PSCustomObject -Property @{name = "pestertest$(Get-Random)" }), (New-Object -TypeName PSCustomObject -Property @{name = "pestertest$(Get-Random)" }) | New-ZbxHostGroup
        $g.count | Should -Be 2
        $g[0].name | Should -Match "pestertest"
    }
}

Describe "Get-ZbxHostGroup" {
    It "can return all groups" {
        $ret = Get-ZbxHostGroup
        $ret | Should -Not -BeNullOrEmpty
        $ret.Count | Should -BeGreaterThan 1
    }
    It "can filter by name with wildcard (explicit parameter)" {
        $ret = Get-ZbxHostGroup "pestertest*"
        $ret | Should -Not -BeNullOrEmpty
        $ret.name | Should -BeLike 'pestertest*'
        $ret = Get-ZbxHostGroup "XXXXXXXXXXXXXX"
        $ret | Should -BeNullOrEmpty
    }
    It "can filter by ID (explicit parameter)" {
        $h = (Get-ZbxHostGroup "pestertest*")[0]
        (Get-ZbxHostGroup -Id $h.groupid).name | Should -Be $h.name
    }      
}

Describe "Remove-ZbxHostGroup" {
    It "can delete from one explicit ID parameter" {
        New-ZbxHostGroup -Name "pestertestrem" -errorAction silentlycontinue
        $h = Get-ZbxHostGroup pestertestrem
        remove-ZbxHostGroup $h.groupid | Should -Be $h.groupid
        Get-ZbxHostGroup pestertestrem | Should -Throw
    }
    It "can delete from multiple explicit ID parameters" {
        $h1 = New-ZbxHostGroup -Name "pestertestrem"
        $h2 = New-ZbxHostGroup -Name "pestertestrem2" -errorAction silentlycontinue
        $h2 = Get-ZbxHostgroup pestertestrem2
        remove-ZbxHostgroup $h1.groupid, $h2.groupid | Should -Be @($h1.groupid, $h2.groupid)
        Get-ZbxHostGroup pestertestrem | Should -Throw
        Get-ZbxHostGroup pestertestrem2 | Should -Throw
    }
    It "can delete from multiple piped IDs" {
        $h1 = New-ZbxHostGroup -Name "pestertestrem"
        $h2 = New-ZbxHostGroup -Name "pestertestrem2"
        $h1.groupid, $h2.groupid | remove-ZbxHostgroup | Should -Be @($h1.groupid, $h2.groupid)
    }
    It "can delete from one piped object parameter" {
        $h = New-ZbxHostGroup -Name "pestertestrem"
        $h | remove-ZbxHostgroup | Should -Be $h.groupid
    }
    It "can delete from multiple piped objects" {
        $h1 = New-ZbxHostGroup -Name "pestertestrem"
        $h2 = New-ZbxHostGroup -Name "pestertestrem2"
        $h1, $h2 | remove-ZbxHostgroup | Should -Be @($h1.groupid, $h2.groupid)
    }
}

Describe "Get-ZbxUserGroup" {
    It "can return all groups" {
        Get-ZbxUserGroup | Should -Not -BeNullOrEmpty
    }
    It "can filter by name with wildcard (explicit parameter)" {
        Get-ZbxUserGroup "Zabbix*" | Should -Not -BeNullOrEmpty
        Get-ZbxUserGroup "XXXXXXXXXXXXXX" | Should -BeNullOrEmpty
    }
    It "can filter by ID (explicit parameter)" {
        $h = (Get-ZbxUserGroup "Zabbix*")[0]
        (Get-ZbxUserGroup -Id $h.usrgrpid).name | Should -Be $h.name
    }      
}

Describe "New-ZbxUserGroup" {
    It "creates a new group with explicit name parameter" {
        $g = New-ZbxUserGroup "pestertest$(Get-Random)", "pestertest$(Get-Random)"
        $g.count | Should -Be 2
        $g[0].name | Should -Match "pestertest"
    }
    It "creates a new group with piped names" {
        $g = "pestertest$(Get-Random)", "pestertest$(Get-Random)" | New-ZbxUserGroup
        $g.count | Should -Be 2
        $g[0].name | Should -Match "pestertest"
    }
    It "creates a new group with piped objects" {
        $g = (New-Object -TypeName PSCustomObject -Property @{name = "pestertest$(Get-Random)" }), (New-Object -TypeName PSCustomObject -Property @{name = "pestertest$(Get-Random)" }) | New-ZbxUserGroup
        $g.count | Should -Be 2
        $g[0].name | Should -Match "pestertest"
    }
}

Describe "Remove-ZbxUserGroup" {
    It "can delete from one explicit ID parameter" {
        New-ZbxUserGroup -Name "pestertestrem" -errorAction silentlycontinue
        $h = Get-ZbxUserGroup pestertestrem
        Remove-ZbxUserGroup $h.usrgrpid | Should -Be $h.usrgrpid
        Get-ZbxUserGroup pestertestrem | Should -BeNullOrEmpty
    }
    It "can delete from multiple explicit ID parameters" {
        $h1 = New-ZbxUserGroup -Name "pestertestrem"
        $h2 = New-ZbxUserGroup -Name "pestertestrem2" -errorAction silentlycontinue
        $h2 = Get-ZbxUserGroup pestertestrem2
        remove-ZbxUserGroup $h1.usrgrpid, $h2.usrgrpid | Should -Be @($h1.usrgrpid, $h2.usrgrpid)
        Get-ZbxUserGroup pestertestrem | Should -BeNullOrEmpty
        Get-ZbxUserGroup pestertestrem2 | Should -BeNullOrEmpty
    }
    It "can delete from multiple piped IDs" {
        $h1 = New-ZbxUserGroup -Name "pestertestrem"
        $h2 = New-ZbxUserGroup -Name "pestertestrem2"
        $h1.usrgrpid, $h2.usrgrpid | remove-ZbxUserGroup | Should -Be @($h1.usrgrpid, $h2.usrgrpid)
    }
    It "can delete from one piped object parameter" {
        $h = New-ZbxUserGroup -Name "pestertestrem"
        $h | remove-ZbxUserGroup | Should -Be $h.usrgrpid
    }
    It "can delete from multiple piped objects" {
        $h1 = New-ZbxUserGroup -Name "pestertestrem"
        $h2 = New-ZbxUserGroup -Name "pestertestrem2"
        $h1, $h2 | remove-ZbxUserGroup | Should -Be @($h1.usrgrpid, $h2.usrgrpid)
    }
}

Describe "Get-ZbxUser" {
    It "can return all users" {
        $ret = Get-ZbxUser
        $ret | Should -Not -BeNullOrEmpty
    }
    It "can filter by name with wildcard (explicit parameter)" {
        $ret = Get-ZbxUser "Admi*"
        $ret | Should -Not -BeNullOrEmpty
        $ret | Should -HaveCount 1
        $ret.Alias | Should -Be 'Admin'
        $ret.Name | Should -Be 'Zabbix'
    }
    It "can filter by ID (explicit parameter)" {
        $h = Get-ZbxUser "Admin"
        $h | Should -HaveCount 1
        (Get-ZbxUser -Id $h.userid).alias | Should -Be $h.alias
    }
    It "returns nothing on unknown user" {
        $ret = Get-ZbxUser "XXXXXXXXXXXXXX"
        $ret | Should -BeNullOrEmpty
        $ret = Get-ZbxUser -Id 9999999
        $ret | Should -BeNullOrEmpty
    }
}

Describe "New-ZbxUser" {
    BeforeAll {
        $userToCopy = "pestertest$(Get-random)"
    }
    It "creates a new user with explicit parameters" {
        $g = @(New-ZbxUser -Alias $userToCopy -name "marsu" -UserGroupId 8)
        $g.count | Should -Be 1
        $g[0].name | Should -Match "marsu"
    }
    It "create user with Media Email" {
        $username = "pestertest$(Get-random)-withmail"
        $g = @(New-ZbxUser -Alias $username -name "marsu" -UserGroupId 8 -MailAddress 'huhu@example.com')
        $g.count | Should -Be 1
        $g[0].name | Should -Match "marsu"
        Remove-ZbxUser $g.UserId
    }
    #TODO: fix example
    It "creates a new user from another user (copy)" -Skip {
        $u = Get-ZbxUser -Name $userToCopy
        #        $u = @(New-ZbxUser -Alias "pestertest$(Get-random)" -name "marsu" -UserGroupId 8)
        $g = $u | New-ZbxUser -alias "pestertest$(Get-random)"
        $g.userid | Should -Not -Be $null
        $g.name | Should -Match "marsu"
        $g.usrgrps.usrgrpid | Should -Be 8
    }
}

Describe "Remove-ZbxUser" {
    BeforeEach {
        New-ZbxUser -Alias "pestertestrem" -UserGroupId 8 -errorAction silentlycontinue | Should -Not -BeNullOrEmpty
        New-ZbxUser -Alias "pestertestrem2" -UserGroupId 8 -errorAction silentlycontinue  | Should -Not -BeNullOrEmpty
        $user1 = Get-ZbxUser -Name 'pestertestrem'
        $user2 = Get-ZbxUser -Name 'pestertestrem2'
    }
    AfterEach {
        Remove-ZbxUser $user1.userid -ErrorAction silentlycontinue
        Remove-ZbxUser $user2.userid -ErrorAction silentlycontinue
    }
    It "can delete from one explicit ID parameter" {
        Remove-ZbxUser $user1.userid | Should -Be $user1.userid
        Get-ZbxUser pestertestrem | Should -BeNullOrEmpty
    }
    It "can delete from multiple explicit ID parameters" {
        Remove-ZbxUser $user1.userid, $user2.userid | Should -Be @($User1.userid, $User2.userid)
        Get-ZbxUser pestertestrem  | Should -BeNullOrEmpty
        Get-ZbxUser pestertestrem2 | Should -BeNullOrEmpty
    }
    It "can delete from multiple piped IDs" {
        $user1.userid, $user2.userid | Remove-ZbxUser | Should -Be @($user1.userid, $user2.userid)
    }
    It "can delete from one piped object parameter" {
        $user1 | Remove-ZbxUser | Should -Be $user1.userid
    }
    It "can delete from multiple piped objects" {
        $user1, $user2 | Remove-ZbxUser | Should -Be @($user1.userid, $user2.userid)
    }
}

Describe "Add-ZbxUserGroupMembership" {
    It "can add two user groups (explicit parameter) to piped users" {
        Get-ZbxUser "pester*" | Remove-ZbxUser
        Get-ZbxUserGroup "pester*" | remove-ZbxUserGroup

        $g1 = New-ZbxUserGroup -Name "pestertestmembers"
        $g2 = New-ZbxUserGroup -Name "pestertestmembers2"
        $g1 = Get-ZbxUserGroup pestertestmembers
        $g2 = Get-ZbxUserGroup pestertestmembers2

        $u1 = New-ZbxUser -Alias "pestertestrem" -UserGroupId 8
        $u2 = New-ZbxUser -Alias "pestertestrem2" -UserGroupId 8
        $u1 = Get-ZbxUser pestertestrem
        $u2 = Get-ZbxUser pestertestrem2

        $u1, $u2 | Add-ZbxUserGroupMembership $g1, $g2 | Should -Be @($u1.userid, $u2.userid)
        $u1 = Get-ZbxUser pestertestrem
        $u2 = Get-ZbxUser pestertestrem2
        $u1.usrgrps | select -ExpandProperty usrgrpid | Should -Be @(8, $g1.usrgrpid, $g2.usrgrpid)
    }
    It "same with ID instead of objects" {
        Get-ZbxUser "pester*" | Remove-ZbxUser
        Get-ZbxUserGroup "pester*" | remove-ZbxUserGroup

        $g1 = New-ZbxUserGroup -Name "pestertestmembers3"
        $g2 = New-ZbxUserGroup -Name "pestertestmembers4"
        $g1 = Get-ZbxUserGroup pestertestmembers3
        $g2 = Get-ZbxUserGroup pestertestmembers4

        $u1 = New-ZbxUser -Alias "pestertestrem3" -UserGroupId 8
        $u2 = New-ZbxUser -Alias "pestertestrem4" -UserGroupId 8
        $u1 = Get-ZbxUser pestertestrem3
        $u2 = Get-ZbxUser pestertestrem4

        $u1.userid, $u2.userid | Add-ZbxUserGroupMembership $g1.usrgrpid, $g2.usrgrpid | Should -Be @($u1.userid, $u2.userid)
        $u1 = Get-ZbxUser pestertestrem3
        $u2 = Get-ZbxUser pestertestrem4
        $u1.usrgrps | select -ExpandProperty usrgrpid | Should -Be @(8, $g1.usrgrpid, $g2.usrgrpid)
    }
}

Describe "Remove-ZbxUserGroupMembership" {
    It "can remove two user groups (explicit parameter) to piped users" {
        Get-ZbxUser "pester*" | Remove-ZbxUser
        Get-ZbxUserGroup "pester*" | remove-ZbxUserGroup

        $g1 = New-ZbxUserGroup -Name "pestertestmembers"
        $g2 = New-ZbxUserGroup -Name "pestertestmembers2"
        $g1 = Get-ZbxUserGroup pestertestmembers
        $g2 = Get-ZbxUserGroup pestertestmembers2

        $u1 = New-ZbxUser -Alias "pestertestrem" -UserGroupId 8
        $u2 = New-ZbxUser -Alias "pestertestrem2" -UserGroupId 8
        $u1 = Get-ZbxUser pestertestrem
        $u2 = Get-ZbxUser pestertestrem2

        $u1, $u2 | Add-ZbxUserGroupMembership $g1, $g2 | Should -Be @($u1.userid, $u2.userid)
        $u1, $u2 | Remove-ZbxUserGroupMembership $g1, $g2 | Should -Be @($u1.userid, $u2.userid)
        $u1 = Get-ZbxUser pestertestrem
        $u2 = Get-ZbxUser pestertestrem2
        $u1.usrgrps | select -ExpandProperty usrgrpid | Should -Be @(8)
    }
    It "same with ID instead of objects" {
        Get-ZbxUser "pester*" | Remove-ZbxUser
        Get-ZbxUserGroup "pester*" | remove-ZbxUserGroup

        $g1 = New-ZbxUserGroup -Name "pestertestmembers3"
        $g2 = New-ZbxUserGroup -Name "pestertestmembers4"
        $g1 = Get-ZbxUserGroup pestertestmembers3
        $g2 = Get-ZbxUserGroup pestertestmembers4

        $u1 = New-ZbxUser -Alias "pestertestrem3" -UserGroupId 8
        $u2 = New-ZbxUser -Alias "pestertestrem4" -UserGroupId 8
        $u1 = Get-ZbxUser pestertestrem3
        $u2 = Get-ZbxUser pestertestrem4

        $u1.userid, $u2.userid | Add-ZbxUserGroupMembership $g1.usrgrpid, $g2.usrgrpid | Should -Be @($u1.userid, $u2.userid)
        $u1 = Get-ZbxUser pestertestrem3
        $u2 = Get-ZbxUser pestertestrem4
        $u1.usrgrps | select -ExpandProperty usrgrpid | Should -Be @(8, $g1.usrgrpid, $g2.usrgrpid)
        $u1.userid, $u2.userid | Remove-ZbxUserGroupMembership $g1.usrgrpid, $g2.usrgrpid | Should -Be @($u1.userid, $u2.userid)
        $u1 = Get-ZbxUser pestertestrem3
        $u2 = Get-ZbxUser pestertestrem4
        $u1.usrgrps | select -ExpandProperty usrgrpid | Should -Be @(8)
    }
}

Describe "Add-ZbxUserGroupPermission" {
    It "can add a Read permission to two piped user groups on two host groups" {
        Get-ZbxHostGroup "pester*" | remove-ZbxHostGroup
        Get-ZbxUserGroup "pester*" | remove-ZbxUserGroup

        New-ZbxUserGroup -Name "pestertest1", "pestertest2"
        $ug1 = Get-ZbxUserGroup pestertest1
        $ug2 = Get-ZbxUserGroup pestertest2

        New-ZbxHostGroup "pestertest1", "pestertest2"
        $hg1 = Get-ZbxHostGroup pestertest1
        $hg2 = Get-ZbxHostGroup pestertest2

        $ug1, $ug2 | Add-ZbxUserGroupPermission $hg1, $hg2 ReadWrite | Should -Be @($ug1.usrgrpid, $ug2.usrgrpid)
        $ug1 = Get-ZbxUserGroup pestertest1
        $ug2 = Get-ZbxUserGroup pestertest2
        $ug1.rights | select -ExpandProperty id | Should -Be @($hg1.groupid, $hg2.groupid)
        $ug1.rights | select -ExpandProperty permission | Should -Be @(3, 3)
    }
    It "can alter and clear permissions on a host group without touching permissions on other groups" {
        $ug1 = Get-ZbxUserGroup pestertest1
        $ug2 = Get-ZbxUserGroup pestertest2
        $hg1 = Get-ZbxHostGroup pestertest1
        $hg2 = Get-ZbxHostGroup pestertest2

        # Sanity check
        $ug1.rights | select -ExpandProperty id | Should -Be @($hg1.groupid, $hg2.groupid)
        $ug1.rights | select -ExpandProperty permission | Should -Be @(3, 3)

        # Set HG1 RO.
        $ug1, $ug2 | Add-ZbxUserGroupPermission $hg1 ReadOnly | Should -Be @($ug1.usrgrpid, $ug2.usrgrpid)
        $ug1 = Get-ZbxUserGroup pestertest1
        $ug2 = Get-ZbxUserGroup pestertest2
        $ug1.rights | select -ExpandProperty id | Should -Be @($hg1.groupid, $hg2.groupid)
        $ug1.rights | select -ExpandProperty permission | Should -Be @(2, 3)

        # Clear HG1
        $ug1, $ug2 | Add-ZbxUserGroupPermission $hg1 Clear | Should -Be @($ug1.usrgrpid, $ug2.usrgrpid)
        $ug1 = Get-ZbxUserGroup pestertest1
        $ug2 = Get-ZbxUserGroup pestertest2
        $ug1.rights | select -ExpandProperty id | Should -Be @($hg2.groupid)
        $ug1.rights | select -ExpandProperty permission | Should -Be @(3)
    }
}

Describe "Get-MediaType" {
    It "can return all types" {
        Get-MediaType | Should -Not -BeNullOrEmpty
    }
    It "can filter by technical media type" {
        Get-MediaType -type Email | Should -Not -BeNullOrEmpty
        Get-MediaType -type EzTexting | Should -BeNullOrEmpty
    }         
}

Describe "Add-ZbxUserMail" {
    It "can add a mail to a user without mail" {
        $u = @(New-ZbxUser -Alias "pestertestmedia$(Get-random)" -name "marsu" -UserGroupId 8)[0]
        $u | Add-ZbxUserMail toto1@company.com | Should -Not -BeNullOrEmpty
    }
    It "can add a mail with specific severity filter" {
        $u = @(New-ZbxUser -Alias "pestertestmedia$(Get-random)" -name "marsu" -UserGroupId 8)[0]
        $u | Add-ZbxUserMail toto1@company.com Information, Warning | Should -Not -BeNullOrEmpty
    }
}

Describe "Get-ZbxMedia" {
    It "can return all media" {
        Get-ZbxMedia |  Should -Not -BeNullOrEmpty
    }

    It "can filter by media type" {
        Get-ZbxMedia -MediaTypeId (Get-ZbxMediaType -Type email).mediatypeid |  Should -Not -BeNullOrEmpty
    }

    It "can filter actions used by certain users" {
        Get-ZbxMedia -UserId @(Get-ZbxUser -Name "pestertestmedia*")[0].userid |  Should -Not -BeNullOrEmpty
        Get-ZbxMedia -UserId @(Get-ZbxUser -Name "Admin")[0].userid |  Should -BeNullOrEmpty
    }
}

Describe "Remove-ZbxMedia" {
    It "can remove piped media" {
        Get-ZbxMedia | Remove-ZbxMedia |  Should -Not -BeNullOrEmpty
        Get-ZbxMedia |  Should -BeNullOrEmpty
        Get-ZbxUser -Name "pestertestmedia*" | Remove-ZbxUser > $null
    }
}

Describe "Disable-ZbxUserGroup" {
    BeforeAll {
        New-ZbxUserGroup -Name "pestertestenable1" -errorAction silentlycontinue
        $h1 = Get-ZbxUserGroup pestertestenable1
    }

    It "can disable multiple piped objects" {
        $h1 | Disable-ZbxUserGroup | Should -Be @($h1.usrgrpid)
        [int](Get-ZbxUserGroup pestertestenable1).users_status | Should -Be 1
    }
}

Describe "Enable-ZbxUserGroup" {
    BeforeAll {
        New-ZbxUserGroup -Name "pestertestenable1" -errorAction silentlycontinue
        $h1 = Get-ZbxUserGroup pestertestenable1
    }

    It "can enable multiple piped objects" {
        $h1 | Enable-ZbxUserGroup | Should -Be @($h1.usrgrpid)
        [int](Get-ZbxUserGroup pestertestenable1).users_status | Should -Be 0
    }
}

Describe "Update-ZbxHost" {
    BeforeAll {
        $name = "pestertesthost$(Get-Random)"
        Get-ZbxHost -name "perster*" | remove-ZbxHost
        Get-ZbxHost -name "newname" | remove-ZbxHost
        $h = New-ZbxHost -Name $name -HostGroupId 2 -TemplateId $testTemplateId -Dns localhost -errorAction silentlycontinue
    }

    It "can update the name of a host" {
        $h.name = "newname"
        $h | Update-ZbxHost 
            $h | Update-ZbxHost 
        $h | Update-ZbxHost 
        Get-ZbxHost -id $h.hostid | select -ExpandProperty name | Should -Be "newname"
    }
}