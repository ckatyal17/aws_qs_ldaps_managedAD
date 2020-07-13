param(
   [Parameter(Mandatory=$true)]
   [string]$CASecParam,
   [Parameter(Mandatory=$true)]
   [string]$DomainNetBIOSName,
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

# DSC configuration to configure a scheduled task which will run at startup

Configuration ScheduledTask
{

    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $Credentials
    )

    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask CreateTemplate
        {
            TaskName            = 'Create Template'
            TaskPath            = '\AWSLDAPsQSs'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ActionArguments     = "C:\AWSLDAPsConfig\temp\createTemplate.ps1 -certificateTemplateName $certificateTemplateName"
            ScheduleType        = 'AtStartup'
            ActionWorkingPath   = 'C:\AWSLDAPsConfig\temp'
            Enable              = $true
            ExecuteAsCredential = $Credentials
            RunLevel            = 'Highest'
        }
    }
}

ScheduledTask -OutputPath 'C:\AWSLDAPsConfig\createTemplateTask' -Credentials $Credentials -ConfigurationData $ConfigurationData