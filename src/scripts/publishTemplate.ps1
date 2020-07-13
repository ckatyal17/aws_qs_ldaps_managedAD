[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$CASecParam,
    [Parameter(Mandatory=$true)]
    [string]$certificateTemplateName
)

# Getting CA admin secrets information from AWS Secrets Manager.
$CAAdminPassword = ConvertFrom-Json -InputObject (Get-SECSecretValue -SecretId $CASecParam).SecretString
# Formatting CA admin username for domain join.
$CAAdminUser = 'Domain\User' -replace 'Domain',$DomainNetBIOSName -replace 'User',$CAAdminPassword.UserName
# Creating Credential Object for CA Admin User
$Credentials = (New-Object PSCredential($CAAdminUser,(ConvertTo-SecureString $CAAdminPassword.Password -AsPlainText -Force)))
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

# DSC configuration to publish certificate template on CA.

Configuration configCATempl
{
    param
    (
        [PSCredential] $Credentials
    )
    Import-DscResource -Module ActiveDirectoryCSDsc

    Node localhost
    {
        AdcsTemplate certtmpl
        {
            Name   = $certificateTemplateName
            Ensure = 'Present'
        }
    }
}

configCATempl -OutputPath 'C:\AWSLDAPsConfig\publishCATemplate' -Credentials $Credentials -ConfigurationData $ConfigurationData