FROM mcr.microsoft.com/powershell:ubuntu-18.04
RUN pwsh -noprofile -noninteractive -c 'Install-Module PowershellGet -Scope AllUsers -Force'
RUN pwsh -noprofile -noninteractive -c 'Install-Module Pester,PSFramework -Scope AllUsers -Force'
