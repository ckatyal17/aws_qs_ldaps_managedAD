[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$certificateTemplateName
)

try{
$certtemplname = 'CN=ldaps' -replace 'ldaps', $certificateTemplateName

# Duplicate a template
$ConfigContext = ([ADSI]"LDAP://RootDSE").ConfigurationNamingContext
$ADSI = [ADSI]"LDAP://CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext"

# Generate Random Template OID
Function Get-RandomHex {
	param ([int]$Length)
		$Hex = '0123456789ABCDEF'
		[string]$Return = $null
		For ($i=1;$i -le $length;$i++) {
			$Return += $Hex.Substring((Get-Random -Minimum 0 -Maximum 16),1)
		}
		Return $Return
	}
	
Function checkOID {
	param ($cn,$TemplateOID,$ConfigContext)
		$Search = Get-ADObject -SearchBase "CN=OID,CN=Public Key Services,CN=Services,$ConfigContext" -Filter {cn -eq $cn -and msPKI-Cert-Template-OID -eq $TemplateOID}
		If ($Search) {$False} Else {$True}
}
	
Function New-TemplateOID {
	Param($ConfigContext)
		do {
			$OID_1 = Get-Random -Minimum 10000000 -Maximum 99999999
			$OID_2 = Get-Random -Minimum 10000000 -Maximum 99999999
			$OID_3 = Get-RandomHex -Length 32
			$OID_Existing = Get-ADObject -Identity "CN=OID,CN=Public Key Services,CN=Services,$ConfigContext" -Properties msPKI-Cert-Template-OID | Select-Object -ExpandProperty msPKI-Cert-Template-OID
			$msPKICertTemplateOID = "$OID_Existing.$OID_1.$OID_2"
			$Name = "$OID_2.$OID_3"
		} until (checkOID -cn $Name -TemplateOID $msPKICertTemplateOID -ConfigContext $ConfigContext)
		Return @{
			TemplateOID  = $msPKICertTemplateOID
			TemplateName = $Name
		}
} 
# Finish Generating Random Template OID 

# Create a new object in OID container
$OID_New = New-TemplateOID -ConfigContext $ConfigContext
$TemplateOIDPath = "CN=OID,CN=Public Key Services,CN=Services,$ConfigContext"
$oa = @{
        'DisplayName' = $certificateTemplateName
        'flags' = [System.Int32]'1'
        'msPKI-Cert-Template-OID' = $OID_New.TemplateOID
}
New-ADObject -Path $TemplateOIDPath -OtherAttributes $oa -Name OID_New.TemplateName -Type 'msPKI-Enterprise-Oid'

# Add required attributes to template
$NewTempl = $ADSI.Create("pKICertificateTemplate", $certtemplname)
$NewTempl.put("distinguishedName","$certtemplname,CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigContext")
$NewTempl.put("flags","131680")
$NewTempl.put("displayName",$certificateTemplateName)
$NewTempl.put("revision","100")
$NewTempl.put("pKIDefaultKeySpec","1")
$NewTempl.SetInfo()

# Add other Attributes to template
$NewTempl.put("pKIMaxIssuingDepth","0")
$NewTempl.put("pKICriticalExtensions","2.5.29.15")
$NewTempl.put("pKIExtendedKeyUsage","1.3.6.1.5.5.7.3.1")
$NewTempl.put("pKIDefaultCSPs","1,Microsoft RSA SChannel Cryptographic Provider")
$NewTempl.put("msPKI-RA-Signature","0")
$NewTempl.put("msPKI-Enrollment-Flag","0")
$NewTempl.put("msPKI-Private-Key-Flag","16842752")
$NewTempl.put("msPKI-Certificate-Name-Flag","134217728")
$NewTempl.put("msPKI-Minimal-Key-Size","2048")
$NewTempl.put("msPKI-Template-Schema-Version","2")
$NewTempl.put("msPKI-Template-Minor-Revision","0")
#$NewTempl.put("msPKI-Cert-Template-OID","1.3.6.1.4.1.311.21.8.14865712.6640054.4476569.14547573.3852325.170.5117346.10961021")
$NewTempl.put("msPKI-Cert-Template-OID", $OID_New.TemplateOID)
$NewTempl.put("msPKI-Certificate-Application-Policy","1.3.6.1.5.5.7.3.1")
$NewTempl.SetInfo()

# Getting required information from Default Domain Controller Certificate template
$WATempl = $ADSI.psbase.children | where {$_.displayName -match "Workstation Authentication"}

# Setting the attributes on new template using existing "Workstation Authentication" template
$NewTempl.pKIKeyUsage = $WATempl.pKIKeyUsage
$NewTempl.pKIExpirationPeriod = $WATempl.pKIExpirationPeriod
$NewTempl.pKIOverlapPeriod = $WATempl.pKIOverlapPeriod
$NewTempl.SetInfo()


# Change Permission on the Template
if ($NewTempl -ne $null) {                     
	$objUser = New-Object System.Security.Principal.NTAccount("Domain Controllers")                                       
	$objectGuid = New-Object Guid 0e10c968-78fb-11d2-90d4-00c04f79dc55 # Enroll Permission
    $objectGuid1 = New-Object Guid a05b8cc2-17bc-4802-a710-e7c15ab866a2 # Auto-Enroll https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-crtd/211ab1e3-bad6-416d-9d56-8480b42617a4    
	$ADRight = [System.DirectoryServices.ActiveDirectoryRights]"ExtendedRight"                    
	$ACEType = [System.Security.AccessControl.AccessControlType]"Allow"                     
	$ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule -ArgumentList $objUser,$ADRight,$ACEType,$objectGuid                 
	$NewTempl.ObjectSecurity.AddAccessRule($ACE)                     
	$NewTempl.commitchanges()  
	$ACE1 = New-Object System.DirectoryServices.ActiveDirectoryAccessRule -ArgumentList $objUser,$ADRight,$ACEType,$objectGuid1                 
	$NewTempl.ObjectSecurity.AddAccessRule($ACE1)                     
	$NewTempl.commitchanges()                        
}
}catch{
	$_ | Out-File "C:\AWSLDAPsConfig\logs\scripts\createTemplate.txt" -Append
	$_.ScriptStackTrace | Out-File "C:\AWSLDAPsConfig\logs\scripts\createTemplate_ScriptStackTrace.txt" -Append
	$_.Exception | Out-File "C:\AWSLDAPsConfig\logs\scripts\createTemplate_Exception.txt" -Append
	$_.ErrorDetails | Out-File "C:\AWSLDAPsConfig\logs\scripts\scripts_createTemplate_ErrDetails.txt" -Append
}