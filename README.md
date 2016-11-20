# What is PSZabbix

A powershell module for automating Zabbix administration.

# Goals

This module aims at making it easy to automate the creation of standard 
objects inside Zabbix. That way, Zabbix can be included inside fully 
automated workflows like server provisioning. It may for example be used 
inside a script task of SCVMM to reference a new VM inside Zabbix after 
creation, or to add a newly created user (by your preferred provisioning 
tool) to a set of user groups.

The objects which can be managed are only the basic objects: hosts, host 
groups, users, user groups, templates and a few others. The module does not
expose the full Zabbix API. We actually expect administrators to use the
Zabbix UI to do complex operations like adding monitored items to hosts or
templates (moreover, these operations being rare, there is little value in
automating them). 

This module is tested on Zabbix 2.4 and later, 3.2 and later. It should 
also work and other versions but without any guarantee.

# Installation

The module is published on the PowerShell gallery, so download and installation is simply (powershell 5+):

```
PS> Install-Module PSZabbix -scope CurrentUser
```

If using an older version of PowerShell, you must download the release from the releases page, unzip it 
and put the PSZabbix folder inside MyDocuments/WindowsPowerShell/Modules or any other folder in the module 
search path.

# Usage

All cmdlets have a "get-help" documentation. Here are the basics:

```
# Import the module (if old powershell version)
PS> Import-Module PSZabbix

# You must first create a session against a Zabbix server - only needed once per work session.
PS> $s = New-ZbxApiSession "http://myserver/zabbix/api_jsonrpc.php" (Get-Credential MyAdminLogin)

# Then call any cmdlet
PS> Get-ZbxHost
hostid host                    name                                        status
------ ----                    ----                                        ------
 10084 Zabbix server           Zabbix server                               Enabled
 10105 Agent Mongo 1           Agent Mongo 1                               Enabled
...

# List of cmdlets (the Zbx prefix can be changed on import if needed):
PS> Get-Command -Module PSZabbix
CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Add-ZbxHostGroupMembership                         1.0.0      PSZabbix
Function        Add-ZbxUserGroupMembership                         1.0.0      PSZabbix
Function        Add-ZbxUserGroupPermission                         1.0.0      PSZabbix
Function        Add-ZbxUserMail                                    1.0.0      PSZabbix
Function        Disable-ZbxHost                                    1.0.0      PSZabbix
Function        Disable-ZbxUserGroup                               1.0.0      PSZabbix
Function        Enable-ZbxHost                                     1.0.0      PSZabbix
Function        Enable-ZbxUserGroup                                1.0.0      PSZabbix
Function        Get-ZbxAction                                      1.0.0      PSZabbix
Function        Get-ZbxHost                                        1.0.0      PSZabbix
Function        Get-ZbxHostGroup                                   1.0.0      PSZabbix
Function        Get-ZbxMedia                                       1.0.0      PSZabbix
Function        Get-ZbxMediaType                                   1.0.0      PSZabbix
Function        Get-ZbxProxy                                       1.0.0      PSZabbix
Function        Get-ZbxTemplate                                    1.0.0      PSZabbix
Function        Get-ZbxUser                                        1.0.0      PSZabbix
Function        Get-ZbxUserGroup                                   1.0.0      PSZabbix
Function        New-ZbxApiSession                                  1.0.0      PSZabbix
Function        New-ZbxHost                                        1.0.0      PSZabbix
Function        New-ZbxHostGroup                                   1.0.0      PSZabbix
Function        New-ZbxUser                                        1.0.0      PSZabbix
Function        New-ZbxUserGroup                                   1.0.0      PSZabbix
Function        Remove-ZbxHost                                     1.0.0      PSZabbix
Function        Remove-ZbxHostGroup                                1.0.0      PSZabbix
Function        Remove-ZbxHostGroupMembership                      1.0.0      PSZabbix
Function        Remove-ZbxMedia                                    1.0.0      PSZabbix
Function        Remove-ZbxTemplate                                 1.0.0      PSZabbix
Function        Remove-ZbxUser                                     1.0.0      PSZabbix
Function        Remove-ZbxUserGroup                                1.0.0      PSZabbix
Function        Remove-ZbxUserGroupMembership                      1.0.0      PSZabbix
```

# Misc

The module is tested with Pester. If you want to run the tests you will have to modify the login chain inside the test file
and have a working Zabbix server to test against.