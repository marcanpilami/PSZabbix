[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()
BeforeAll {
    Try {
        $moduleName = 'PSZabbix'
        $moduleRoot = "$PSScriptRoot/../../"
        Import-Module $moduleRoot/$moduleName.psd1 -Force

        $global:baseUrl = "http://tools/zabbix/api_jsonrpc.php"
        $secpasswd = ConvertTo-SecureString "zabbix" -AsPlainText -Force
        $global:admin = New-Object System.Management.Automation.PSCredential ("Admin", $secpasswd)
        
        $wrongsecpasswd = ConvertTo-SecureString "wrong" -AsPlainText -Force
        $global:admin2 = New-Object System.Management.Automation.PSCredential ("Admin", $wrongsecpasswd)
        
        $s = New-ZbxApiSession $baseUrl $global:admin -silent
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
        $session | should Not Be $null
        $session["Uri"] | should Not Be $null
        $session["Auth"] | should Not Be $null
    }

    It "fails when URL is wrong" {
        { New-ZbxApiSession "http://localhost:12345/zabbix" $admin } | Should Throw
    } -Skip

    It "fails when login/password is wrong" {
        { New-ZbxApiSession $baseUrl $admin2 } | Should Throw
    }
}

Describe "New-ZbxHost" {
    It "can create an enabled host from explicit ID parameters" {
        $h = New-ZbxHost -Name "pestertesthost$(Get-Random)" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost
        $h | should not be $null
        $h.status | should be 0
    }
    It "can create an disabled host from explicit ID parameters" {
        $h = New-ZbxHost -Name "pestertesthost$(Get-Random)" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost -status disabled
        $h | should not be $null
        $h.status | should be 1
    }
}

Describe "Get-ZbxHost" {
    It "can return all hosts" {
        Get-ZbxHost | Should Not BeNullOrEmpty
    }
    It "can filter by name with wildcard (explicit parameter)" {
        Get-ZbxHost "pestertesthost*" | Should Not BeNullOrEmpty
        Get-ZbxHost "pestertesthostXXX*" | Should BeNullOrEmpty
    }
    It "can filter by ID (explicit parameter)" {
        $h = (Get-ZbxHost "pestertesthost*")[0]
        (Get-ZbxHost -Id $h.hostid).host | Should Be $h.host
    }
    It "can filter by group membership (explicit parameter)" {
        $h = (Get-ZbxHost "pestertesthost*")[0]
        (Get-ZbxHost -Id $h.hostid -ZbxHostGroupId 2).host | Should Be $h.host
    }
}

Describe "Remove-ZbxHost" {
    It "can delete from one explicit ID parameter" {
        New-ZbxHost -Name "pestertesthostrem" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        $h = Get-ZbxHost pestertesthostrem
        remove-ZbxHost $h.hostid | should be $h.hostid
    }
    It "can delete from multiple explicit ID parameters" {
        $h1 = New-ZbxHost -Name "pestertesthostrem" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost
        $h2 = New-ZbxHost -Name "pestertesthostrem2" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        remove-ZbxHost $h1.hostid, $h2.hostid | should be @($h1.hostid, $h2.hostid)
    }
    It "can delete from multiple piped IDs" {
        $h1 = New-ZbxHost -Name "pestertesthostrem" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost
        $h2 = New-ZbxHost -Name "pestertesthostrem2" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost
        $h1.hostid, $h2.hostid | remove-ZbxHost | should be @($h1.hostid, $h2.hostid)
    }
    It "can delete from one piped object parameter" {
        $h = New-ZbxHost -Name "pestertesthostrem" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost
        $h | remove-ZbxHost | should be $h.hostid
    }
    It "can delete from multiple piped objects" {
        $h1 = New-ZbxHost -Name "pestertesthostrem" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost
        $h2 = New-ZbxHost -Name "pestertesthostrem2" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost
        $h1, $h2 | remove-ZbxHost | should be @($h1.hostid, $h2.hostid)
    }
}

Describe "Disable-ZbxHost" {
    BeforeAll {
        New-ZbxHost -Name "pestertesthost1" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        New-ZbxHost -Name "pestertesthost2" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        $h1 = Get-ZbxHost pestertesthost1
        $h2 = Get-ZbxHost pestertesthost2
    }

    It "can enable multiple piped objects" {
        $h1, $h2 | Disable-ZbxHost | should be @($h1.hostid, $h2.hostid)
        (Get-ZbxHost pestertesthost1).status | should be 1
    }
    It "can enable multiple piped IDs" {
        $h1.hostid, $h2.hostid | Disable-ZbxHost | should be @($h1.hostid, $h2.hostid)
        (Get-ZbxHost pestertesthost1).status | should be 1
    }
    It "can enable multiple explicit parameter IDs" {
        Disable-ZbxHost $h1.hostid, $h2.hostid | should be @($h1.hostid, $h2.hostid)
        (Get-ZbxHost pestertesthost1).status | should be 1
    }
}

Describe "Enable-ZbxHost" {
    BeforeAll {
        New-ZbxHost -Name "pestertesthost1" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        New-ZbxHost -Name "pestertesthost2" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        $h1 = Get-ZbxHost pestertesthost1
        $h2 = Get-ZbxHost pestertesthost2
    }

    It "can enable multiple piped objects" {
        $h1, $h2 | Enable-ZbxHost | should be @($h1.hostid, $h2.hostid)
        (Get-ZbxHost pestertesthost1).status | should be 0
    }
    It "can enable multiple piped IDs" {
        $h1.hostid, $h2.hostid | Enable-ZbxHost | should be @($h1.hostid, $h2.hostid)
        (Get-ZbxHost pestertesthost1).status | should be 0
    }
    It "can enable multiple explicit parameter IDs" {
        Enable-ZbxHost $h1.hostid, $h2.hostid | should be @($h1.hostid, $h2.hostid)
        (Get-ZbxHost pestertesthost1).status | should be 0
    }
}

Describe "Add-ZbxHostGroupMembership" {
    BeforeAll {
        New-ZbxHost -Name "pestertesthost1" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        New-ZbxHost -Name "pestertesthost2" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        $h1 = Get-ZbxHost pestertesthost1
        $h2 = Get-ZbxHost pestertesthost2
        New-ZbxHostGroup "pestertest1" -errorAction silentlycontinue
        New-ZbxHostGroup "pestertest2" -errorAction silentlycontinue
        $g1 = Get-ZbxHostGroup pestertest1
        $g2 = Get-ZbxHostGroup pestertest2
    }

    It "adds a set of groups given as a parameter to multiple piped hosts" {
        $h1, $h2 | Add-ZbxHostGroupMembership $g1, $g2
        (Get-ZbxHostGroup pestertest1).hosts.Count | should be 2
    }
}

Describe "Remove-ZbxHostGroupMembership" {
    BeforeAll {
        New-ZbxHost -Name "pestertesthost1" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        New-ZbxHost -Name "pestertesthost2" -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        $h1 = Get-ZbxHost pestertesthost1
        $h2 = Get-ZbxHost pestertesthost2
        New-ZbxHostGroup "pestertest1" -errorAction silentlycontinue
        New-ZbxHostGroup "pestertest2" -errorAction silentlycontinue
        $g1 = Get-ZbxHostGroup pestertest1
        $g2 = Get-ZbxHostGroup pestertest2
    }

    It "removes a set of groups given as a parameter to multiple piped hosts" {
        $h1, $h2 | Remove-ZbxHostGroupMembership $g1, $g2
        (Get-ZbxHostGroup pestertest1).hosts.Count | should be 0
    }
}

Describe "Get-ZbxTemplate" {
    It "can return all templates" {
        Get-ZbxTemplate | Should Not BeNullOrEmpty
    }
    It "can filter by name with wildcard (explicit parameter)" {
        Get-ZbxTemplate "Template OS Lin*" | Should Not BeNullOrEmpty
        Get-ZbxTemplate "XXXXXXXXXXXXXX" | Should BeNullOrEmpty
    }
    It "can filter by ID (explicit parameter)" {
        $h = (Get-ZbxTemplate "Template OS Lin*")[0]
        (Get-ZbxTemplate -Id $h.templateid).host | Should Be $h.host
    }      
}

Describe "New-ZbxHostGroup" {
    It "creates a new group with explicit name parameter" {
        $g = New-ZbxHostGroup "pestertest$(Get-Random)", "pestertest$(Get-Random)"
        $g.count | should be 2
        $g[0].name | should match "pestertest"
    }
    It "creates a new group with piped names" {
        $g = "pestertest$(Get-Random)", "pestertest$(Get-Random)" | New-ZbxHostGroup
        $g.count | should be 2
        $g[0].name | should match "pestertest"
    }
    It "creates a new group with piped objects" {
        $g = (New-Object -TypeName PSCustomObject -Property @{name = "pestertest$(Get-Random)" }), (New-Object -TypeName PSCustomObject -Property @{name = "pestertest$(Get-Random)" }) | New-ZbxHostGroup
        $g.count | should be 2
        $g[0].name | should match "pestertest"
    }
}

Describe "Get-ZbxHostGroup" {
    It "can return all groups" {
        Get-ZbxHostGroup | Should Not BeNullOrEmpty
    }
    It "can filter by name with wildcard (explicit parameter)" {
        Get-ZbxHostGroup "pestertest*" | Should Not BeNullOrEmpty
        Get-ZbxHostGroup "XXXXXXXXXXXXXX" | Should BeNullOrEmpty
    }
    It "can filter by ID (explicit parameter)" {
        $h = (Get-ZbxHostGroup "pestertest*")[0]
        (Get-ZbxHostGroup -Id $h.groupid).name | Should Be $h.name
    }      
}

Describe "Remove-ZbxHostGroup" {
    It "can delete from one explicit ID parameter" {
        New-ZbxHostGroup -Name "pestertestrem" -errorAction silentlycontinue
        $h = Get-ZbxHostGroup pestertestrem
        remove-ZbxHostGroup $h.groupid | should be $h.groupid
        Get-ZbxHostGroup pestertestrem | should Throw
    }
    It "can delete from multiple explicit ID parameters" {
        $h1 = New-ZbxHostGroup -Name "pestertestrem"
        $h2 = New-ZbxHostGroup -Name "pestertestrem2" -errorAction silentlycontinue
        $h2 = Get-ZbxHostgroup pestertestrem2
        remove-ZbxHostgroup $h1.groupid, $h2.groupid | should be @($h1.groupid, $h2.groupid)
        Get-ZbxHostGroup pestertestrem | should Throw
        Get-ZbxHostGroup pestertestrem2 | should Throw
    }
    It "can delete from multiple piped IDs" {
        $h1 = New-ZbxHostGroup -Name "pestertestrem"
        $h2 = New-ZbxHostGroup -Name "pestertestrem2"
        $h1.groupid, $h2.groupid | remove-ZbxHostgroup | should be @($h1.groupid, $h2.groupid)
    }
    It "can delete from one piped object parameter" {
        $h = New-ZbxHostGroup -Name "pestertestrem"
        $h | remove-ZbxHostgroup | should be $h.groupid
    }
    It "can delete from multiple piped objects" {
        $h1 = New-ZbxHostGroup -Name "pestertestrem"
        $h2 = New-ZbxHostGroup -Name "pestertestrem2"
        $h1, $h2 | remove-ZbxHostgroup | should be @($h1.groupid, $h2.groupid)
    }
}

Describe "Get-ZbxUserGroup" {
    It "can return all groups" {
        Get-ZbxUserGroup | Should Not BeNullOrEmpty
    }
    It "can filter by name with wildcard (explicit parameter)" {
        Get-ZbxUserGroup "Zabbix*" | Should Not BeNullOrEmpty
        Get-ZbxUserGroup "XXXXXXXXXXXXXX" | Should BeNullOrEmpty
    }
    It "can filter by ID (explicit parameter)" {
        $h = (Get-ZbxUserGroup "Zabbix*")[0]
        (Get-ZbxUserGroup -Id $h.usrgrpid).name | Should Be $h.name
    }      
}

Describe "New-ZbxUserGroup" {
    It "creates a new group with explicit name parameter" {
        $g = New-ZbxUserGroup "pestertest$(Get-Random)", "pestertest$(Get-Random)"
        $g.count | should be 2
        $g[0].name | should match "pestertest"
    }
    It "creates a new group with piped names" {
        $g = "pestertest$(Get-Random)", "pestertest$(Get-Random)" | New-ZbxUserGroup
        $g.count | should be 2
        $g[0].name | should match "pestertest"
    }
    It "creates a new group with piped objects" {
        $g = (New-Object -TypeName PSCustomObject -Property @{name = "pestertest$(Get-Random)" }), (New-Object -TypeName PSCustomObject -Property @{name = "pestertest$(Get-Random)" }) | New-ZbxUserGroup
        $g.count | should be 2
        $g[0].name | should match "pestertest"
    }
}

Describe "Remove-ZbxUserGroup" {
    It "can delete from one explicit ID parameter" {
        New-ZbxUserGroup -Name "pestertestrem" -errorAction silentlycontinue
        $h = Get-ZbxUserGroup pestertestrem
        Remove-ZbxUserGroup $h.usrgrpid | should be $h.usrgrpid
        Get-ZbxUserGroup pestertestrem | should Throw
    }
    It "can delete from multiple explicit ID parameters" {
        $h1 = New-ZbxUserGroup -Name "pestertestrem"
        $h2 = New-ZbxUserGroup -Name "pestertestrem2" -errorAction silentlycontinue
        $h2 = Get-ZbxUserGroup pestertestrem2
        remove-ZbxUserGroup $h1.usrgrpid, $h2.usrgrpid | should be @($h1.usrgrpid, $h2.usrgrpid)
        Get-ZbxUserGroup pestertestrem | should Throw
        Get-ZbxUserGroup pestertestrem2 | should Throw
    }
    It "can delete from multiple piped IDs" {
        $h1 = New-ZbxUserGroup -Name "pestertestrem"
        $h2 = New-ZbxUserGroup -Name "pestertestrem2"
        $h1.usrgrpid, $h2.usrgrpid | remove-ZbxUserGroup | should be @($h1.usrgrpid, $h2.usrgrpid)
    }
    It "can delete from one piped object parameter" {
        $h = New-ZbxUserGroup -Name "pestertestrem"
        $h | remove-ZbxUserGroup | should be $h.usrgrpid
    }
    It "can delete from multiple piped objects" {
        $h1 = New-ZbxUserGroup -Name "pestertestrem"
        $h2 = New-ZbxUserGroup -Name "pestertestrem2"
        $h1, $h2 | remove-ZbxUserGroup | should be @($h1.usrgrpid, $h2.usrgrpid)
    }
}

Describe "Get-ZbxUser" {
    It "can return all users" {
        Get-ZbxUser | Should Not BeNullOrEmpty
    }
    It "can filter by name with wildcard (explicit parameter)" {
        Get-ZbxUser "Admi*" | Should Not BeNullOrEmpty
        Get-ZbxUser "XXXXXXXXXXXXXX" | Should BeNullOrEmpty
    }
    It "can filter by ID (explicit parameter)" {
        $h = (Get-ZbxUser "Admin")[0]
        (Get-ZbxUser -Id $h.userid).alias | Should Be $h.alias
    }      
}

Describe "New-ZbxUser" {
    It "creates a new user with explicit parameters" {
        $g = @(New-ZbxUser -Alias "pestertest$(Get-random)" -name "marsu" -ZbxUserGroupId 8)
        $g.count | should be 1
        $g[0].name | should match "marsu"
    }
    It "creates a new user from another user (copy)" {
        $u = @(New-ZbxUser -Alias "pestertest$(Get-random)" -name "marsu" -ZbxUserGroupId 8)
        $g = $u | New-ZbxUser -alias "pestertest$(Get-random)"
        $g.userid | should Not Be $null
        $g.name | should match "marsu"
        $g.usrgrps.usrgrpid | should be 8
    }
}

Describe "Remove-ZbxUser" {
    It "can delete from one explicit ID parameter" {
        New-ZbxUser -Alias "pestertestrem" -ZbxUserGroupId 8 -errorAction silentlycontinue
        $h = Get-ZbxUser pestertestrem
        Remove-ZbxUser $h.userid | should be $h.userid
        Get-ZbxUser pestertestrem | should Throw
    }
    It "can delete from multiple explicit ID parameters" {
        $h1 = New-ZbxUser -Alias "pestertestrem" -ZbxUserGroupId 8 
            $h1 = New-ZbxUser -Alias "pestertestrem" -ZbxUserGroupId 8 
        $h1 = New-ZbxUser -Alias "pestertestrem" -ZbxUserGroupId 8 
        $h2 = New-ZbxUser -Alias "pestertestrem2" -ZbxUserGroupId 8  -errorAction silentlycontinue
        $h2 = Get-ZbxUser pestertestrem2
        Remove-ZbxUser $h1.userid, $h2.userid | should be @($h1.userid, $h2.userid)
        Get-ZbxUser pestertestrem | should Throw
        Get-ZbxUser pestertestrem2 | should Throw
    }
    It "can delete from multiple piped IDs" {
        $h1 = New-ZbxUser -Alias "pestertestrem" -ZbxUserGroupId 8 
            $h1 = New-ZbxUser -Alias "pestertestrem" -ZbxUserGroupId 8 
        $h1 = New-ZbxUser -Alias "pestertestrem" -ZbxUserGroupId 8 
        $h2 = New-ZbxUser -Alias "pestertestrem2" -ZbxUserGroupId 8 
        $h1.userid, $h2.userid | Remove-ZbxUser | should be @($h1.userid, $h2.userid)
    }
    It "can delete from one piped object parameter" {
        $h = New-ZbxUser -Alias "pestertestrem" -ZbxUserGroupId 8 
        $h | Remove-ZbxUser | should be $h.userid
    }
    It "can delete from multiple piped objects" {
        $h1 = New-ZbxUser -Alias "pestertestrem" -ZbxUserGroupId 8 
            $h1 = New-ZbxUser -Alias "pestertestrem" -ZbxUserGroupId 8 
        $h1 = New-ZbxUser -Alias "pestertestrem" -ZbxUserGroupId 8 
        $h2 = New-ZbxUser -Alias "pestertestrem2" -ZbxUserGroupId 8 
        $h1, $h2 | Remove-ZbxUser | should be @($h1.userid, $h2.userid)
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

        $u1 = New-ZbxUser -Alias "pestertestrem" -ZbxUserGroupId 8
        $u2 = New-ZbxUser -Alias "pestertestrem2" -ZbxUserGroupId 8
        $u1 = Get-ZbxUser pestertestrem
        $u2 = Get-ZbxUser pestertestrem2

        $u1, $u2 | Add-ZbxUserGroupMembership $g1, $g2 | should be @($u1.userid, $u2.userid)
        $u1 = Get-ZbxUser pestertestrem
        $u2 = Get-ZbxUser pestertestrem2
        $u1.usrgrps | select -ExpandProperty usrgrpid | Should Be @(8, $g1.usrgrpid, $g2.usrgrpid)
    }
    It "same with ID instead of objects" {
        Get-ZbxUser "pester*" | Remove-ZbxUser
        Get-ZbxUserGroup "pester*" | remove-ZbxUserGroup

        $g1 = New-ZbxUserGroup -Name "pestertestmembers3"
        $g2 = New-ZbxUserGroup -Name "pestertestmembers4"
        $g1 = Get-ZbxUserGroup pestertestmembers3
        $g2 = Get-ZbxUserGroup pestertestmembers4

        $u1 = New-ZbxUser -Alias "pestertestrem3" -ZbxUserGroupId 8
        $u2 = New-ZbxUser -Alias "pestertestrem4" -ZbxUserGroupId 8
        $u1 = Get-ZbxUser pestertestrem3
        $u2 = Get-ZbxUser pestertestrem4

        $u1.userid, $u2.userid | Add-ZbxUserGroupMembership $g1.usrgrpid, $g2.usrgrpid | should be @($u1.userid, $u2.userid)
        $u1 = Get-ZbxUser pestertestrem3
        $u2 = Get-ZbxUser pestertestrem4
        $u1.usrgrps | select -ExpandProperty usrgrpid | Should Be @(8, $g1.usrgrpid, $g2.usrgrpid)
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

        $u1 = New-ZbxUser -Alias "pestertestrem" -ZbxUserGroupId 8
        $u2 = New-ZbxUser -Alias "pestertestrem2" -ZbxUserGroupId 8
        $u1 = Get-ZbxUser pestertestrem
        $u2 = Get-ZbxUser pestertestrem2

        $u1, $u2 | Add-ZbxUserGroupMembership $g1, $g2 | should be @($u1.userid, $u2.userid)
        $u1, $u2 | Remove-ZbxUserGroupMembership $g1, $g2 | should be @($u1.userid, $u2.userid)
        $u1 = Get-ZbxUser pestertestrem
        $u2 = Get-ZbxUser pestertestrem2
        $u1.usrgrps | select -ExpandProperty usrgrpid | Should Be @(8)
    }
    It "same with ID instead of objects" {
        Get-ZbxUser "pester*" | Remove-ZbxUser
        Get-ZbxUserGroup "pester*" | remove-ZbxUserGroup

        $g1 = New-ZbxUserGroup -Name "pestertestmembers3"
        $g2 = New-ZbxUserGroup -Name "pestertestmembers4"
        $g1 = Get-ZbxUserGroup pestertestmembers3
        $g2 = Get-ZbxUserGroup pestertestmembers4

        $u1 = New-ZbxUser -Alias "pestertestrem3" -ZbxUserGroupId 8
        $u2 = New-ZbxUser -Alias "pestertestrem4" -ZbxUserGroupId 8
        $u1 = Get-ZbxUser pestertestrem3
        $u2 = Get-ZbxUser pestertestrem4

        $u1.userid, $u2.userid | Add-ZbxUserGroupMembership $g1.usrgrpid, $g2.usrgrpid | should be @($u1.userid, $u2.userid)
        $u1 = Get-ZbxUser pestertestrem3
        $u2 = Get-ZbxUser pestertestrem4
        $u1.usrgrps | select -ExpandProperty usrgrpid | Should Be @(8, $g1.usrgrpid, $g2.usrgrpid)
        $u1.userid, $u2.userid | Remove-ZbxUserGroupMembership $g1.usrgrpid, $g2.usrgrpid | should be @($u1.userid, $u2.userid)
        $u1 = Get-ZbxUser pestertestrem3
        $u2 = Get-ZbxUser pestertestrem4
        $u1.usrgrps | select -ExpandProperty usrgrpid | Should Be @(8)
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

        $ug1, $ug2 | Add-ZbxUserGroupPermission $hg1, $hg2 ReadWrite | should be @($ug1.usrgrpid, $ug2.usrgrpid)
        $ug1 = Get-ZbxUserGroup pestertest1
        $ug2 = Get-ZbxUserGroup pestertest2
        $ug1.rights | select -ExpandProperty id | Should Be @($hg1.groupid, $hg2.groupid)
        $ug1.rights | select -ExpandProperty permission | Should Be @(3, 3)
    }
    It "can alter and clear permissions on a host group without touching permissions on other groups" {
        $ug1 = Get-ZbxUserGroup pestertest1
        $ug2 = Get-ZbxUserGroup pestertest2
        $hg1 = Get-ZbxHostGroup pestertest1
        $hg2 = Get-ZbxHostGroup pestertest2

        # Sanity check
        $ug1.rights | select -ExpandProperty id | Should Be @($hg1.groupid, $hg2.groupid)
        $ug1.rights | select -ExpandProperty permission | Should Be @(3, 3)

        # Set HG1 RO.
        $ug1, $ug2 | Add-ZbxUserGroupPermission $hg1 ReadOnly | should be @($ug1.usrgrpid, $ug2.usrgrpid)
        $ug1 = Get-ZbxUserGroup pestertest1
        $ug2 = Get-ZbxUserGroup pestertest2
        $ug1.rights | select -ExpandProperty id | Should Be @($hg1.groupid, $hg2.groupid)
        $ug1.rights | select -ExpandProperty permission | Should Be @(2, 3)

        # Clear HG1
        $ug1, $ug2 | Add-ZbxUserGroupPermission $hg1 Clear | should be @($ug1.usrgrpid, $ug2.usrgrpid)
        $ug1 = Get-ZbxUserGroup pestertest1
        $ug2 = Get-ZbxUserGroup pestertest2
        $ug1.rights | select -ExpandProperty id | Should Be @($hg2.groupid)
        $ug1.rights | select -ExpandProperty permission | Should Be @(3)
    }
}

Describe "Get-MediaType" {
    It "can return all types" {
        Get-MediaType | Should Not BeNullOrEmpty
    }
    It "can filter by technical media type" {
        Get-MediaType -type Email | Should Not BeNullOrEmpty
        Get-MediaType -type EzTexting | Should BeNullOrEmpty
    }         
}

Describe "Add-ZbxUserMail" {
    It "can add a mail to a user without mail" {
        $u = @(New-ZbxUser -Alias "pestertestmedia$(Get-random)" -name "marsu" -ZbxUserGroupId 8)[0]
        $u | Add-ZbxUserMail toto1@company.com | Should Not BeNullOrEmpty
    }
    It "can add a mail with specific severity filter" {
        $u = @(New-ZbxUser -Alias "pestertestmedia$(Get-random)" -name "marsu" -ZbxUserGroupId 8)[0]
        $u | Add-ZbxUserMail toto1@company.com Information, Warning | Should Not BeNullOrEmpty
    }
}

Describe "Get-ZbxMedia" {
    It "can return all media" {
        Get-ZbxMedia |  Should Not BeNullOrEmpty
    }

    It "can filter by media type" {
        Get-ZbxMedia -MediaTypeId (Get-MediaType -Type email).mediatypeid |  Should Not BeNullOrEmpty
    }

    It "can filter actions used by certain users" {
        Get-ZbxMedia -UserId @(Get-ZbxUser -Name "pestertestmedia*")[0].userid |  Should Not BeNullOrEmpty
        Get-ZbxMedia -UserId @(Get-ZbxUser -Name "Admin")[0].userid |  Should BeNullOrEmpty
    }
}

Describe "Remove-ZbxMedia" {
    It "can remove piped media" {
        Get-ZbxMedia | Remove-ZbxMedia |  Should Not BeNullOrEmpty
        Get-ZbxMedia |  Should BeNullOrEmpty
        Get-ZbxUser -Name "pestertestmedia*" | Remove-ZbxUser > $null
    }
}

Describe "Disable-ZbxUserGroup" {
    BeforeAll {
        New-ZbxUserGroup -Name "pestertestenable1" -errorAction silentlycontinue
        $h1 = Get-ZbxUserGroup pestertestenable1
    }

    It "can disable multiple piped objects" {
        $h1 | Disable-ZbxUserGroup | should be @($h1.usrgrpid)
        [int](Get-ZbxUserGroup pestertestenable1).users_status | should be 1
    }
}

Describe "Enable-ZbxUserGroup" {
    BeforeAll {
        New-ZbxUserGroup -Name "pestertestenable1" -errorAction silentlycontinue
        $h1 = Get-ZbxUserGroup pestertestenable1
    }

    It "can enable multiple piped objects" {
        $h1 | Enable-ZbxUserGroup | should be @($h1.usrgrpid)
        [int](Get-ZbxUserGroup pestertestenable1).users_status | should be 0
    }
}

Describe "Update-ZbxHost" {
    BeforeAll {
        $name = "pestertesthost$(Get-Random)"
        Get-ZbxHost -name "perster*" | remove-ZbxHost
        Get-ZbxHost -name "newname" | remove-ZbxHost
        $h = New-ZbxHost -Name $name -ZbxHostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
    }

    It "can update the name of a host" {
        $h.name = "newname"
        $h | Update-ZbxHost 
            $h | Update-ZbxHost 
        $h | Update-ZbxHost 
        Get-ZbxHost -id $h.hostid | select -ExpandProperty name | should be "newname"
    }
}