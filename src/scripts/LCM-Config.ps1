# Set LCM configuration
[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node 'localhost' {
        Settings {
            RefreshMode = 'Push'
            ActionAfterReboot = 'StopConfiguration'                      
            RebootNodeIfNeeded = $false
            CertificateId = $DscCertThumbprint  
        }
    }
}

$DscCertThumbprint = (Get-ChildItem -path cert:\LocalMachine\My | Where-Object { $_.subject -eq "CN=AWSLDAPsDscCert" }).Thumbprint
    
#Generates MOF File for LCM
LCMConfig -OutputPath 'C:\AWSLDAPsConfig\LCMConfig'
    
# Sets LCM Configuration to MOF generated in previous command
Set-DscLocalConfigurationManager -Path 'C:\AWSLDAPsConfig\LCMConfig' 
