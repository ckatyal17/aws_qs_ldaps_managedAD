<# Download createTemplate.ps1 script from S3 bucket
createTemplate.ps1 script is required to create a new certificate template and give domain controllers group enroll and auto-enroll permission on the new template.
#>

[CmdletBinding()]
param()

Start-BitsTransfer -Source "https://raw.githubusercontent.com/ckatyal17/qs_ldaps/master/src/scripts/createTemplate.ps1" -Destination "C:\AWSLDAPsConfig\temp\createTemplate.ps1"
