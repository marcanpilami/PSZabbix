
Add-Type -TypeDefinition @"
public enum ZbxStatus
{
   Enabled = 0,
   Disabled = 1    
}
"@


Add-Type -TypeDefinition @"
   public enum ZbxGuiAccess
   {
      WithDefaultAuthenticationMethod = 0,
      WithInternalAuthentication = 1,
      Disabled = 2    
   }
"@

Add-Type -TypeDefinition @"
   public enum ZbxPermission
   {
      Clear = -1,
      Deny = 0,
      ReadOnly = 2,
      ReadWrite = 3    
   }
"@

Add-Type -TypeDefinition @"
   public enum ZbxUserType
   {
      User = 1,
      Admin,
      SuperAdmin      
   }
"@



$ActOpType = @{
    0 = "send message"
    1 = "remote command"
    2 = "add host"
    3 = "remove host"
    4 = "add to host group"
    5 = "moreve from host group"
    6 = "link to template"
    7 = "unlink from template"
    8 = "enable host"
    9 = "disable host"
}

$ActOpCmd = @{
    0 = "custom script"
    1 = "IPMI"
    2 = "SSH"
    3 = "Telnet"
    4 = "global script"
}

$ActConditionEvalMethod = @{
    0 = "AND/OR"
    1 = "AND"
    2 = "OR"
}

$ActOpExecuteOn = @{
    0 = "Zabbix agent"
    1 = "Zabbix server"
}

Add-Type -TypeDefinition @"
   [System.Flags]
   public enum ZbxSeverity
   {
      None = 0,
      NotClassified = 1,
      Information = 2,
      Warning = 4,
      Average = 8,
      High = 16,
      Disaster = 32  
   }
"@


Add-Type -TypeDefinition @"
   public enum ZbxMediaTypeType
   {
      Email = 0,
      Script = 1,
      SMS = 2,
      Jabber = 3,
      EzTexting = 100 
   }
"@

