[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$CAServerNetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]$DomainNetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]$DomainDNSName,

    [Parameter(Mandatory=$true)]
    [string]$CASecParam
)

# Getting CA admin secrets information from AWS Secrets Manager.
$CAAdminPassword = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $CASecParam).SecretString
# Formatting CA admin username for domain join.
$CAAdminUser = 'Domain\User' -replace 'Domain',$DomainNetBIOSName -replace 'User',$CAAdminPassword.UserName
# Creating Credential Object for CA Admin User
$Credentials = (New-Object PSCredential($CAAdminUser,(ConvertTo-SecureString $CAAdminPassword.Password -AsPlainText -Force)))
# Adding CA Admin to local administrators group
Add-LocalGroupMember -Group "Administrators" -Member $CAAdminUser
# Fetching the DSC Encryption certificate thumbprint to Secure the domain join MOF File
$DscCertThumbprint = (Get-ChildItem -path cert:\LocalMachine\My | Where-Object { $_.subject -eq "CN=AWSLDAPsDscCert" }).Thumbprint

# Configuration Data Block with Certificate Information for DSC processing
$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName="*"
            CertificateFile = "C:\AWSLDAPsConfig\cert\AWSLDAPsDscCert.cer"
            Thumbprint = $DscCertThumbprint
            PSDscAllowDomainUser = $true
        },
        @{
            NodeName = 'localhost'
        }
    )
}

# DSC configuration to install ADCS role and perform post configuration for the CA.

Configuration ConfigCA {
    # Credential Objects being passed in
    param
    (
        [PSCredential] $Credentials
    )
    
    # Importing DSC Modules needed for Configuration
    Import-Module -Name PSDesiredStateConfiguration
    Import-Module -Name ActiveDirectoryCSDsc
    Import-Module -Name ComputerManagementDsc
    
    # Importing All DSC Resources needed for Configuration
    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module ActiveDirectoryCSDsc
    Import-DscResource -Module ComputerManagementDsc
    
    # Node Configuration block
    Node 'localhost' {
       
        # Adding ADCS roles and RSAT tools feature
        WindowsFeature ADCS-Cert-Authority { 
               Ensure = 'Present' 
               Name = 'ADCS-Cert-Authority'
        }

        ADCSCertificationAuthority ADCS { 
            Ensure = 'Present'
            IsSingleInstance = 'Yes' 
            Credential = $Credentials
            CAType = 'EnterpriseRootCA' 
            DependsOn = '[WindowsFeature]ADCS-Cert-Authority'               
        }

        WindowsFeature RSAT-ADCS { 
            Ensure = 'Present' 
            Name = 'RSAT-ADCS' 
            DependsOn = '[WindowsFeature]ADCS-Cert-Authority' 
        } 
        
        WindowsFeature RSAT-ADCS-Mgmt { 
            Ensure = 'Present' 
            Name = 'RSAT-ADCS-Mgmt' 
            DependsOn = '[WindowsFeature]ADCS-Cert-Authority' 
        }

        WindowsFeature RSAT-AD-Tools { 
            Ensure = 'Present' 
            Name = 'RSAT-AD-Tools' 
            DependsOn = '[WindowsFeature]RSAT-ADCS-Mgmt' 
        }

        WindowsFeature RSAT-AD-PowerShell { 
            Ensure = 'Present' 
            Name = 'RSAT-AD-PowerShell' 
            DependsOn = '[WindowsFeature]RSAT-AD-Tools' 
        }
    }
}

# Generating MOF File
ConfigCA -OutputPath 'C:\AWSLDAPsConfig\ConfigCA' -Credentials $Credentials -ConfigurationData $ConfigurationData