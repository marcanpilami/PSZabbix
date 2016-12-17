[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingConvertToSecureStringWithPlainText", "")]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1", ".psm1")

$global:baseUrl = "http://tools/zabbix/api_jsonrpc.php"
$secpasswd = ConvertTo-SecureString "zabbix" -AsPlainText -Force
$global:admin = New-Object System.Management.Automation.PSCredential ("Admin", $secpasswd)

$wrongsecpasswd = ConvertTo-SecureString "wrong" -AsPlainText -Force
$global:admin2 = New-Object System.Management.Automation.PSCredential ("Admin", $wrongsecpasswd)

Import-Module $here/$sut -Force

InModuleScope PSZabbix {    
    $s = New-ApiSession $baseUrl $global:admin -silent
    
    Describe "New-ApiSession" {
        $session = New-ApiSession $baseUrl $admin -silent

        It "connects to zabbix and returns a non-empty session object" {
            $session | should Not Be $null
            $session["Uri"] | should Not Be $null
            $session["Auth"] | should Not Be $null
        }

        It "fails when URL is wrong" {
            {New-ApiSession "http://localhost:12345/zabbix" $admin} | Should Throw
        } -Skip

        It "fails when login/password is wrong" {
            {New-ApiSession $baseUrl $admin2} | Should Throw
        }
    }

    Describe "New-Host" {
        It "can create an enabled host from explicit ID parameters" {
            $h = New-Host -Name "pestertesthost$(Get-Random)" -HostGroupId 2 -TemplateId 10108 -Dns localhost
            $h | should not be $null
            $h.status | should be 0
        }
        It "can create an disabled host from explicit ID parameters" {
            $h = New-Host -Name "pestertesthost$(Get-Random)" -HostGroupId 2 -TemplateId 10108 -Dns localhost -status disabled
            $h | should not be $null
            $h.status | should be 1
        }
    }

    Describe "Get-Host" {
        It "can return all hosts" {
            Get-Host | Should Not BeNullOrEmpty
        }
        It "can filter by name with wildcard (explicit parameter)" {
            Get-Host "pestertesthost*" | Should Not BeNullOrEmpty
            Get-Host "pestertesthostXXX*" | Should BeNullOrEmpty
        }
        It "can filter by ID (explicit parameter)" {
            $h = (Get-Host "pestertesthost*")[0]
            (Get-Host -Id $h.hostid).host | Should Be $h.host
        }
        It "can filter by group membership (explicit parameter)" {
            $h = (Get-Host "pestertesthost*")[0]
            (Get-Host -Id $h.hostid -HostGroupId 2).host | Should Be $h.host
        }
    }

    Describe "Remove-Host" {
        It "can delete from one explicit ID parameter" {
            New-Host -Name "pestertesthostrem" -HostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
            $h = Get-Host pestertesthostrem
            remove-Host $h.hostid | should be $h.hostid
        }
        It "can delete from multiple explicit ID parameters" {
            $h1 = New-Host -Name "pestertesthostrem" -HostGroupId 2 -TemplateId 10108 -Dns localhost
            $h2 = New-Host -Name "pestertesthostrem2" -HostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
            remove-Host $h1.hostid,$h2.hostid | should be @($h1.hostid, $h2.hostid)
        }
        It "can delete from multiple piped IDs" {
            $h1 = New-Host -Name "pestertesthostrem" -HostGroupId 2 -TemplateId 10108 -Dns localhost
            $h2 = New-Host -Name "pestertesthostrem2" -HostGroupId 2 -TemplateId 10108 -Dns localhost
            $h1.hostid,$h2.hostid | remove-Host | should be @($h1.hostid, $h2.hostid)
        }
        It "can delete from one piped object parameter" {
            $h = New-Host -Name "pestertesthostrem" -HostGroupId 2 -TemplateId 10108 -Dns localhost
            $h | remove-Host | should be $h.hostid
        }
        It "can delete from multiple piped objects" {
            $h1 = New-Host -Name "pestertesthostrem" -HostGroupId 2 -TemplateId 10108 -Dns localhost
            $h2 = New-Host -Name "pestertesthostrem2" -HostGroupId 2 -TemplateId 10108 -Dns localhost
            $h1,$h2 | remove-Host | should be @($h1.hostid, $h2.hostid)
        }
    }

    Describe "Disable-Host"  {
        New-Host -Name "pestertesthost1" -HostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        New-Host -Name "pestertesthost2" -HostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        $h1 = get-host pestertesthost1
        $h2 = get-host pestertesthost2

        It "can enable multiple piped objects" {
            $h1,$h2 | Disable-host | should be @($h1.hostid, $h2.hostid)
            (get-host pestertesthost1).status | should be 1
        }
        It "can enable multiple piped IDs" {
            $h1.hostid,$h2.hostid | Disable-host | should be @($h1.hostid, $h2.hostid)
            (get-host pestertesthost1).status | should be 1
        }
        It "can enable multiple explicit parameter IDs" {
            Disable-host $h1.hostid,$h2.hostid | should be @($h1.hostid, $h2.hostid)
            (get-host pestertesthost1).status | should be 1
        }
    }

    Describe "Enable-Host"  {
        New-Host -Name "pestertesthost1" -HostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        New-Host -Name "pestertesthost2" -HostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        $h1 = get-host pestertesthost1
        $h2 = get-host pestertesthost2

        It "can enable multiple piped objects" {
            $h1,$h2 | enable-host | should be @($h1.hostid, $h2.hostid)
            (get-host pestertesthost1).status | should be 0
        }
        It "can enable multiple piped IDs" {
            $h1.hostid,$h2.hostid | enable-host | should be @($h1.hostid, $h2.hostid)
            (get-host pestertesthost1).status | should be 0
        }
        It "can enable multiple explicit parameter IDs" {
            enable-host $h1.hostid,$h2.hostid | should be @($h1.hostid, $h2.hostid)
            (get-host pestertesthost1).status | should be 0
        }
    }

    Describe "Add-HostGroupMembership" {
        New-Host -Name "pestertesthost1" -HostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        New-Host -Name "pestertesthost2" -HostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        $h1 = get-host pestertesthost1
        $h2 = get-host pestertesthost2
        New-HostGroup "pestertest1" -errorAction silentlycontinue
        New-HostGroup "pestertest2" -errorAction silentlycontinue
        $g1 = get-HostGroup pestertest1
        $g2 = get-HostGroup pestertest2

        It "adds a set of groups given as a parameter to multiple piped hosts" {
            $h1,$h2 | Add-HostGroupMembership $g1,$g2
            (get-HostGroup pestertest1).hosts.Count | should be 2
        }
    }

    Describe "Remove-HostGroupMembership" {
        New-Host -Name "pestertesthost1" -HostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        New-Host -Name "pestertesthost2" -HostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue
        $h1 = get-host pestertesthost1
        $h2 = get-host pestertesthost2
        New-HostGroup "pestertest1" -errorAction silentlycontinue
        New-HostGroup "pestertest2" -errorAction silentlycontinue
        $g1 = get-HostGroup pestertest1
        $g2 = get-HostGroup pestertest2

        It "removes a set of groups given as a parameter to multiple piped hosts" {
            $h1,$h2 | Remove-HostGroupMembership $g1,$g2
            (get-HostGroup pestertest1).hosts.Count | should be 0
        }
    }

    Describe "Get-Template" {
        It "can return all templates" {
            Get-Template | Should Not BeNullOrEmpty
        }
        It "can filter by name with wildcard (explicit parameter)" {
            Get-Template "Template OS Lin*" | Should Not BeNullOrEmpty
            Get-Template "XXXXXXXXXXXXXX" | Should BeNullOrEmpty
        }
        It "can filter by ID (explicit parameter)" {
            $h = (Get-Template "Template OS Lin*")[0]
            (Get-Template -Id $h.templateid).host | Should Be $h.host
        }      
    }

    Describe "New-HostGroup" {
        It "creates a new group with explicit name parameter" {
            $g = New-HostGroup "pestertest$(Get-Random)","pestertest$(Get-Random)"
            $g.count | should be 2
            $g[0].name | should match "pestertest"
        }
        It "creates a new group with piped names" {
            $g = "pestertest$(Get-Random)","pestertest$(Get-Random)" | New-HostGroup
            $g.count | should be 2
            $g[0].name | should match "pestertest"
        }
        It "creates a new group with piped objects" {
            $g = (New-Object -TypeName PSCustomObject -Property @{name = "pestertest$(Get-Random)"}),(New-Object -TypeName PSCustomObject -Property @{name = "pestertest$(Get-Random)"}) | New-HostGroup
            $g.count | should be 2
            $g[0].name | should match "pestertest"
        }
    }

    Describe "Get-HostGroup" {
        It "can return all groups" {
            Get-HostGroup | Should Not BeNullOrEmpty
        }
        It "can filter by name with wildcard (explicit parameter)" {
            Get-HostGroup "pestertest*" | Should Not BeNullOrEmpty
            Get-HostGroup "XXXXXXXXXXXXXX" | Should BeNullOrEmpty
        }
        It "can filter by ID (explicit parameter)" {
            $h = (Get-HostGroup "pestertest*")[0]
            (Get-HostGroup -Id $h.groupid).name | Should Be $h.name
        }      
    }

    Describe "Remove-HostGroup" {
        It "can delete from one explicit ID parameter" {
            New-HostGroup -Name "pestertestrem" -errorAction silentlycontinue
            $h = Get-HostGroup pestertestrem
            remove-HostGroup $h.groupid | should be $h.groupid
            Get-HostGroup pestertestrem | should Throw
        }
        It "can delete from multiple explicit ID parameters" {
            $h1 = New-HostGroup -Name "pestertestrem"
            $h2 =  New-HostGroup -Name "pestertestrem2" -errorAction silentlycontinue
            $h2 = get-Hostgroup pestertestrem2
            remove-Hostgroup $h1.groupid,$h2.groupid | should be @($h1.groupid, $h2.groupid)
            Get-HostGroup pestertestrem | should Throw
            Get-HostGroup pestertestrem2 | should Throw
        }
        It "can delete from multiple piped IDs" {
            $h1 = New-HostGroup -Name "pestertestrem"
            $h2 =  New-HostGroup -Name "pestertestrem2"
            $h1.groupid,$h2.groupid | remove-Hostgroup | should be @($h1.groupid, $h2.groupid)
        }
        It "can delete from one piped object parameter" {
            $h =  New-HostGroup -Name "pestertestrem"
            $h | remove-Hostgroup | should be $h.groupid
        }
        It "can delete from multiple piped objects" {
            $h1 = New-HostGroup -Name "pestertestrem"
            $h2 =  New-HostGroup -Name "pestertestrem2"
            $h1,$h2 | remove-Hostgroup | should be @($h1.groupid, $h2.groupid)
        }
    }

    Describe "Get-UserGroup" {
        It "can return all groups" {
            Get-UserGroup | Should Not BeNullOrEmpty
        }
        It "can filter by name with wildcard (explicit parameter)" {
            Get-UserGroup "Zabbix*" | Should Not BeNullOrEmpty
            Get-UserGroup "XXXXXXXXXXXXXX" | Should BeNullOrEmpty
        }
        It "can filter by ID (explicit parameter)" {
            $h = (Get-UserGroup "Zabbix*")[0]
            (Get-UserGroup -Id $h.usrgrpid).name | Should Be $h.name
        }      
    }

    Describe "New-UserGroup" {
        It "creates a new group with explicit name parameter" {
            $g = New-UserGroup "pestertest$(Get-Random)","pestertest$(Get-Random)"
            $g.count | should be 2
            $g[0].name | should match "pestertest"
        }
        It "creates a new group with piped names" {
            $g = "pestertest$(Get-Random)","pestertest$(Get-Random)" | New-UserGroup
            $g.count | should be 2
            $g[0].name | should match "pestertest"
        }
        It "creates a new group with piped objects" {
            $g = (New-Object -TypeName PSCustomObject -Property @{name = "pestertest$(Get-Random)"}),(New-Object -TypeName PSCustomObject -Property @{name = "pestertest$(Get-Random)"}) | New-UserGroup
            $g.count | should be 2
            $g[0].name | should match "pestertest"
        }
    }

    Describe "Remove-UserGroup" {
        It "can delete from one explicit ID parameter" {
            New-UserGroup -Name "pestertestrem" -errorAction silentlycontinue
            $h = Get-UserGroup pestertestrem
            Remove-UserGroup $h.usrgrpid | should be $h.usrgrpid
            Get-UserGroup pestertestrem | should Throw
        }
        It "can delete from multiple explicit ID parameters" {
            $h1 = New-UserGroup -Name "pestertestrem"
            $h2 =  New-UserGroup -Name "pestertestrem2" -errorAction silentlycontinue
            $h2 = get-Usergroup pestertestrem2
            remove-usergroup $h1.usrgrpid,$h2.usrgrpid | should be @($h1.usrgrpid, $h2.usrgrpid)
            Get-UserGroup pestertestrem | should Throw
            Get-UserGroup pestertestrem2 | should Throw
        }
        It "can delete from multiple piped IDs" {
            $h1 = New-UserGroup -Name "pestertestrem"
            $h2 =  New-UserGroup -Name "pestertestrem2"
            $h1.usrgrpid,$h2.usrgrpid | remove-usergroup | should be @($h1.usrgrpid, $h2.usrgrpid)
        }
        It "can delete from one piped object parameter" {
            $h =  New-UserGroup -Name "pestertestrem"
            $h | remove-Usergroup | should be $h.usrgrpid
        }
        It "can delete from multiple piped objects" {
            $h1 = New-UserGroup -Name "pestertestrem"
            $h2 =  New-UserGroup -Name "pestertestrem2"
            $h1,$h2 | remove-Usergroup | should be @($h1.usrgrpid, $h2.usrgrpid)
        }
    }

    Describe "Get-User" {
        It "can return all users" {
            Get-User | Should Not BeNullOrEmpty
        }
        It "can filter by name with wildcard (explicit parameter)" {
            Get-User "Admi*" | Should Not BeNullOrEmpty
            Get-User "XXXXXXXXXXXXXX" | Should BeNullOrEmpty
        }
        It "can filter by ID (explicit parameter)" {
            $h = (Get-User "Admin")[0]
            (Get-User -Id $h.userid).alias | Should Be $h.alias
        }      
    }

    Describe "New-User" {
        It "creates a new user with explicit parameters" {
            $g = @(New-User -Alias "pestertest$(get-random)" -name "marsu" -UserGroupId 8)
            $g.count | should be 1
            $g[0].name | should match "marsu"
        }
        It "creates a new user from another user (copy)" {
            $u = @(New-User -Alias "pestertest$(get-random)" -name "marsu" -UserGroupId 8)
            $g = $u | new-user -alias "pestertest$(get-random)"
            $g.userid | should Not Be $null
            $g.name | should match "marsu"
            $g.usrgrps.usrgrpid | should be 8
        }
    }

    Describe "Remove-User" {
        It "can delete from one explicit ID parameter" {
            New-User -Alias "pestertestrem" -UserGroupId 8 -errorAction silentlycontinue
            $h = Get-User pestertestrem
            Remove-User $h.userid | should be $h.userid
            Get-User pestertestrem | should Throw
        }
        It "can delete from multiple explicit ID parameters" {
            $h1 = New-User -Alias "pestertestrem" -UserGroupId 8 
            $h2 =  New-User -Alias "pestertestrem2" -UserGroupId 8  -errorAction silentlycontinue
            $h2 = get-User pestertestrem2
            remove-user $h1.userid,$h2.userid | should be @($h1.userid, $h2.userid)
            Get-User pestertestrem | should Throw
            Get-User pestertestrem2 | should Throw
        }
        It "can delete from multiple piped IDs" {
            $h1 = New-User -Alias "pestertestrem" -UserGroupId 8 
            $h2 =  New-User -Alias "pestertestrem2" -UserGroupId 8 
            $h1.userid,$h2.userid | remove-user | should be @($h1.userid, $h2.userid)
        }
        It "can delete from one piped object parameter" {
            $h =  New-User -Alias "pestertestrem" -UserGroupId 8 
            $h | remove-User | should be $h.userid
        }
        It "can delete from multiple piped objects" {
            $h1 = New-User -Alias "pestertestrem" -UserGroupId 8 
            $h2 =  New-User -Alias "pestertestrem2" -UserGroupId 8 
            $h1,$h2 | remove-User | should be @($h1.userid, $h2.userid)
        }
    }

    Describe "Add-UserGroupMembership" {
        It "can add two user groups (explicit parameter) to piped users" {
            Get-User "pester*" | remove-User
            Get-UserGroup "pester*" | remove-UserGroup

            $g1 = New-UserGroup -Name "pestertestmembers"
            $g2 =  New-UserGroup -Name "pestertestmembers2"
            $g1 = get-Usergroup pestertestmembers
            $g2 = get-Usergroup pestertestmembers2

            $u1 = New-User -Alias "pestertestrem" -UserGroupId 8
            $u2 =  New-User -Alias "pestertestrem2" -UserGroupId 8
            $u1 = get-User pestertestrem
            $u2 = get-User pestertestrem2

            $u1,$u2 | Add-UserGroupMembership $g1,$g2 | should be @($u1.userid, $u2.userid)
            $u1 = get-User pestertestrem
            $u2 = get-User pestertestrem2
            $u1.usrgrps | select -ExpandProperty usrgrpid | Should Be @(8, $g1.usrgrpid, $g2.usrgrpid)
        }
        It "same with ID instead of objects" {
            Get-User "pester*" | remove-User
            Get-UserGroup "pester*" | remove-UserGroup

            $g1 = New-UserGroup -Name "pestertestmembers3"
            $g2 =  New-UserGroup -Name "pestertestmembers4"
            $g1 = get-Usergroup pestertestmembers3
            $g2 = get-Usergroup pestertestmembers4

            $u1 = New-User -Alias "pestertestrem3" -UserGroupId 8
            $u2 =  New-User -Alias "pestertestrem4" -UserGroupId 8
            $u1 = get-User pestertestrem3
            $u2 = get-User pestertestrem4

            $u1.userid,$u2.userid | Add-UserGroupMembership $g1.usrgrpid,$g2.usrgrpid | should be @($u1.userid, $u2.userid)
            $u1 = get-User pestertestrem3
            $u2 = get-User pestertestrem4
            $u1.usrgrps | select -ExpandProperty usrgrpid | Should Be @(8, $g1.usrgrpid, $g2.usrgrpid)
        }
    }

    Describe "Remove-UserGroupMembership" {
        It "can remove two user groups (explicit parameter) to piped users" {
            Get-User "pester*" | remove-User
            Get-UserGroup "pester*" | remove-UserGroup

            $g1 = New-UserGroup -Name "pestertestmembers"
            $g2 =  New-UserGroup -Name "pestertestmembers2"
            $g1 = get-Usergroup pestertestmembers
            $g2 = get-Usergroup pestertestmembers2

            $u1 = New-User -Alias "pestertestrem" -UserGroupId 8
            $u2 =  New-User -Alias "pestertestrem2" -UserGroupId 8
            $u1 = get-User pestertestrem
            $u2 = get-User pestertestrem2

            $u1,$u2 | Add-UserGroupMembership $g1,$g2 | should be @($u1.userid, $u2.userid)
            $u1,$u2 | Remove-UserGroupMembership $g1,$g2 | should be @($u1.userid, $u2.userid)
            $u1 = get-User pestertestrem
            $u2 = get-User pestertestrem2
            $u1.usrgrps | select -ExpandProperty usrgrpid | Should Be @(8)
        }
        It "same with ID instead of objects" {
            Get-User "pester*" | remove-User
            Get-UserGroup "pester*" | remove-UserGroup

            $g1 = New-UserGroup -Name "pestertestmembers3"
            $g2 =  New-UserGroup -Name "pestertestmembers4"
            $g1 = get-Usergroup pestertestmembers3
            $g2 = get-Usergroup pestertestmembers4

            $u1 = New-User -Alias "pestertestrem3" -UserGroupId 8
            $u2 =  New-User -Alias "pestertestrem4" -UserGroupId 8
            $u1 = get-User pestertestrem3
            $u2 = get-User pestertestrem4

            $u1.userid,$u2.userid | Add-UserGroupMembership $g1.usrgrpid,$g2.usrgrpid | should be @($u1.userid, $u2.userid)
            $u1 = get-User pestertestrem3
            $u2 = get-User pestertestrem4
            $u1.usrgrps | select -ExpandProperty usrgrpid | Should Be @(8, $g1.usrgrpid, $g2.usrgrpid)
            $u1.userid,$u2.userid | Remove-UserGroupMembership $g1.usrgrpid,$g2.usrgrpid | should be @($u1.userid, $u2.userid)
            $u1 = get-User pestertestrem3
            $u2 = get-User pestertestrem4
            $u1.usrgrps | select -ExpandProperty usrgrpid | Should Be @(8)
        }
    }

    Describe "Add-UserGroupPermission" {
        It "can add a Read permission to two piped user groups on two host groups" {
            Get-HostGroup "pester*" | remove-HostGroup
            Get-UserGroup "pester*" | remove-UserGroup

            New-UserGroup -Name "pestertest1","pestertest2"
            $ug1 = get-Usergroup pestertest1
            $ug2 = get-Usergroup pestertest2

            New-HostGroup "pestertest1","pestertest2"
            $hg1 = get-HostGroup pestertest1
            $hg2 = get-HostGroup pestertest2

            $ug1,$ug2 | Add-UserGroupPermission $hg1,$hg2 ReadWrite | should be @($ug1.usrgrpid, $ug2.usrgrpid)
            $ug1 = get-Usergroup pestertest1
            $ug2 = get-Usergroup pestertest2
            $ug1.rights | select -ExpandProperty id | Should Be @($hg1.groupid, $hg2.groupid)
            $ug1.rights | select -ExpandProperty permission | Should Be @(3, 3)
        }
        It "can alter and clear permissions on a host group without touching permissions on other groups" {
            $ug1 = get-Usergroup pestertest1
            $ug2 = get-Usergroup pestertest2
            $hg1 = get-HostGroup pestertest1
            $hg2 = get-HostGroup pestertest2

            # Sanity check
            $ug1.rights | select -ExpandProperty id | Should Be @($hg1.groupid, $hg2.groupid)
            $ug1.rights | select -ExpandProperty permission | Should Be @(3, 3)

            # Set HG1 RO.
            $ug1,$ug2 | Add-UserGroupPermission $hg1 ReadOnly | should be @($ug1.usrgrpid, $ug2.usrgrpid)
            $ug1 = get-Usergroup pestertest1
            $ug2 = get-Usergroup pestertest2
            $ug1.rights | select -ExpandProperty id | Should Be @($hg1.groupid, $hg2.groupid)
            $ug1.rights | select -ExpandProperty permission | Should Be @(2, 3)

            # Clear HG1
            $ug1,$ug2 | Add-UserGroupPermission $hg1 Clear | should be @($ug1.usrgrpid, $ug2.usrgrpid)
            $ug1 = get-Usergroup pestertest1
            $ug2 = get-Usergroup pestertest2
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

    Describe "Add-UserMail" {
        It "can add a mail to a user without mail" {
            $u = @(New-User -Alias "pestertestmedia$(get-random)" -name "marsu" -UserGroupId 8)[0]
            $u | Add-UserMail toto1@company.com | Should Not BeNullOrEmpty
        }
        It "can add a mail with specific severity filter" {
            $u = @(New-User -Alias "pestertestmedia$(get-random)" -name "marsu" -UserGroupId 8)[0]
            $u | Add-UserMail toto1@company.com Information,Warning | Should Not BeNullOrEmpty
        }
    }

    Describe "Get-Media" {
        It "can return all media" {
            Get-Media |  Should Not BeNullOrEmpty
        }

        It "can filter by media type" {
            Get-Media -MediaTypeId (Get-MediaType -Type email).mediatypeid |  Should Not BeNullOrEmpty
        }

        It "can filter actions used by certain users" {
            Get-Media -UserId @(Get-User -Name "pestertestmedia*")[0].userid |  Should Not BeNullOrEmpty
            Get-Media -UserId @(Get-User -Name "Admin")[0].userid |  Should BeNullOrEmpty
        }
    }

    Describe "Remove-Media" {
        It "can remove piped media" {
            Get-Media | Remove-Media |  Should Not BeNullOrEmpty
            Get-Media |  Should BeNullOrEmpty
            Get-User -Name "pestertestmedia*" | Remove-User > $null
        }
    }

    Describe "Disable-UserGroup"  {
        New-UserGroup -Name "pestertestenable1" -errorAction silentlycontinue
        $h1 = get-usergroup pestertestenable1

        It "can disable multiple piped objects" {
            $h1 | Disable-UserGroup | should be @($h1.usrgrpid)
            [int](get-usergroup pestertestenable1).users_status | should be 1
        }
    }

    Describe "Enable-UserGroup"  {
        New-UserGroup -Name "pestertestenable1" -errorAction silentlycontinue
        $h1 = get-usergroup pestertestenable1

        It "can enable multiple piped objects" {
            $h1 | Enable-UserGroup | should be @($h1.usrgrpid)
            [int](get-usergroup pestertestenable1).users_status | should be 0
        }
    }

    Describe "Update-Host" {
        $name = "pestertesthost$(Get-Random)"
        Get-Host -name "perster*" | remove-host
        Get-Host -name "newname" | remove-host
        $h = New-Host -Name $name -HostGroupId 2 -TemplateId 10108 -Dns localhost -errorAction silentlycontinue

        It "can update the name of a host" {
            $h.name = "newname"
            $h | update-host 
            get-host -id $h.hostid | select -ExpandProperty name | should be "newname"
        }
    }
}