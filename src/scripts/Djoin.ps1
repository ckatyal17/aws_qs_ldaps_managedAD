[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$CAServerNetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]$DomainNetBIOSName,

    [Parameter(Mandatory=$true)]
    [string]$DomainDNSName,

    [Parameter(Mandatory=$true)]
    [string]$DomainDNSIpAddress,

    [Parameter(Mandatory=$true)]
    [string]$CASecParam
)

# IP address formatting required by DSC Resource
$IPADDR = 'IP/CIDR' -replace 'IP',(Get-NetIPConfiguration).IPv4Address.IpAddress -replace 'CIDR',(Get-NetIPConfiguration).IPv4Address.PrefixLength
# Fetching Mac Address for Primary Interface to Rename It
$MacAddress = (Get-NetAdapter).MacAddress
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

# DSC configuration to rename the machine and join it to the domain

Configuration Djoin {
    param
    (
        [PSCredential] $Credentials
    )
    
    # Importing DSC Modules 
    Import-Module -Name PSDesiredStateConfiguration
    Import-Module -Name NetworkingDsc
    Import-Module -Name ComputerManagementDsc
    
    # Importing DSC Resources
    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module NetworkingDsc
    Import-DscResource -Module ComputerManagementDsc
    
    # Configuring Node
    Node 'localhost' {

        # Renaming Primary Adapter
        NetAdapterName RenameNetAdapterPrimary {
            NewName    = 'Primary'
            MacAddress = $MacAddress
        }


        # Modifying DNS Server on Primary Interface to point to Domain DNS
        DnsServerAddress DnsServerAddress {
            Address = $DomainDNSIpAddress
            InterfaceAlias = 'Primary'
            AddressFamily  = 'IPv4'
            DependsOn = '[NetAdapterName]RenameNetAdapterPrimary'
        }
            
        
        # Rename Computer and Join it to Domain
        Computer DomainJoin {
            Name = $CAServerNetBIOSName
            DomainName = $DomainDnsName
            Credential = $Credentials
            DependsOn = "[DnsServerAddress]DnsServerAddress"
        }
        

    }
}

# Generating MOF File
Djoin -OutputPath 'C:\AWSLDAPsConfig\Djoin' -Credentials $Credentials -ConfigurationData $ConfigurationData