#
# Manifeste de module pour le module « PSZabbix »
#
# Généré par : Marc-Antoine Gouillart
#
# Généré le : 21/10/2016
#

@{

# Module de script ou fichier de module binaire associé à ce manifeste
RootModule = 'PSZabbix.psm1'

# Numéro de version de ce module.
ModuleVersion = '1.2.0'

# Éditions PS prises en charge
# CompatiblePSEditions = @()

# ID utilisé pour identifier de manière unique ce module
GUID = 'c1db6c49-8c61-4ca5-811c-3caf15abc53e'

# Auteur de ce module
Author = 'Marc-Antoine Gouillart'

# Société ou fournisseur de ce module
CompanyName = 'Oxymores'

# Déclaration de copyright pour ce module
Copyright = '(c) 2016 Marc-Antoine Gouillart. All rights reserved.'

# Description de la fonctionnalité fournie par ce module
Description = 'PowerShell module for automating Zabbix administration. A simple encapsulation of the Zabbix REST web services.'

# Version minimale du moteur Windows PowerShell requise par ce module
PowerShellVersion = '3.0'

# Nom de l'hôte Windows PowerShell requis par ce module
# PowerShellHostName = ''

# Version minimale de l'hôte Windows PowerShell requise par ce module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Architecture de processeur (None, X86, Amd64) requise par ce module
# ProcessorArchitecture = ''

# Modules qui doivent être importés dans l'environnement global préalablement à l'importation de ce module
# RequiredModules = @()

# Assemblys qui doivent être chargés préalablement à l'importation de ce module
# RequiredAssemblies = @()

# Fichiers de script (.ps1) exécutés dans l’environnement de l’appelant préalablement à l’importation de ce module
# ScriptsToProcess = @()

# Fichiers de types (.ps1xml) à charger lors de l'importation de ce module
TypesToProcess = 'PSZabbix.Types.ps1xml'

# Fichiers de format (.ps1xml) à charger lors de l'importation de ce module
FormatsToProcess = 'PSZabbix.Format.ps1xml'

# Modules à importer en tant que modules imbriqués du module spécifié dans RootModule/ModuleToProcess
# NestedModules = @()

# Fonctions à exporter à partir de ce module. Pour de meilleures performances, n’utilisez pas de caractères génériques et ne supprimez pas l’entrée. Utilisez un tableau vide si vous n’avez aucune fonction à exporter.
FunctionsToExport = @(
    "New-ApiSession",
    "Get-Action",
    "Get-User","New-User","Remove-User",
    "Add-UserGroupMembership","Remove-UserGroupMembership","Add-UserGroupPermission",
    "Get-UserGroup","New-UserGroup","Remove-UserGroup",
    "Enable-UserGroup", "Disable-UserGroup",
    "Get-HostGroup","New-HostGroup","Remove-HostGroup",
    "Get-Template","Remove-Template",
    "Get-Host","New-Host","Remove-Host","Update-Host",
    "Enable-Host", "Disable-Host","Add-HostGroupMembership","Remove-HostGroupMembership",
    "Get-Proxy",
    "Get-Media", "Remove-Media", "Add-UserMail",
    "Get-MediaType")

# Applets de commande à exporter à partir de ce module. Pour de meilleures performances, n’utilisez pas de caractères génériques et ne supprimez pas l’entrée. Utilisez un tableau vide si vous n’avez aucune applet de commande à exporter.
CmdletsToExport = @()

# Variables à exporter à partir de ce module
VariablesToExport = @()

# Alias à exporter à partir de ce module. Pour de meilleures performances, n’utilisez pas de caractères génériques et ne supprimez pas l’entrée. Utilisez un tableau vide si vous n’avez aucun alias à exporter.
AliasesToExport = @()

# Ressources DSC à exporter depuis ce module
# DscResourcesToExport = @()

# Liste de tous les modules empaquetés avec ce module
# ModuleList = @()

# Liste de tous les fichiers empaquetés avec ce module
# FileList = @()

# Données privées à transmettre au module spécifié dans RootModule/ModuleToProcess. Cela peut également inclure une table de hachage PSData avec des métadonnées de modules supplémentaires utilisées par PowerShell.
PrivateData = @{

    PSData = @{

        # Des balises ont été appliquées à ce module. Elles facilitent la découverte des modules dans les galeries en ligne.
        Tags = @("Zabbix", "Automation")

        # URL vers la licence de ce module.
        LicenseUri = 'https://github.com/marcanpilami/PSZabbix/blob/master/LICENSE'

        # URL vers le site web principal de ce projet.
        ProjectUri = 'https://github.com/marcanpilami/PSZabbix'

        # URL vers une icône représentant ce module.
        # IconUri = ''

        # Propriété ReleaseNotes de ce module
        ReleaseNotes = '
1.2.0: 
    * added Update-ZbxHost cmdlet to allow updating all fields without the need of dedicated cmdlets.
    * updated Get-ZbxHost output to include interfaces
1.1.0: new functionalities.
    * added new cmdlets to handle user media
    * added new cmdlets to enable and disable user groups
    * added new option to New-UserGroup to create a disabled user group
    * added new option to New-UserGroup to create a user group without GUI access'

    } # Fin de la table de hachage PSData

} # Fin de la table de hachage PrivateData

# URI HelpInfo de ce module
# HelpInfoURI = ''

# Le préfixe par défaut des commandes a été exporté à partir de ce module. Remplacez le préfixe par défaut à l’aide d’Import-Module -Prefix.
DefaultCommandPrefix = 'Zbx'

}

