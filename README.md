# AWS Cloudformation (CFN) Template to configure LDAPS with AWS Managed Microsoft AD
Configure LDAP over SSL for AWS managed Microsoft using single tier Microsoft Enterprise Certification Authority.


## AWS Resources created by template
- 1 Windows 2019 EC2 instance.
- Instance profile and IAM roles with necessary permissions to access the resorces required to configure CA. 
- SSM document to join EC2 instance to AWS Managed Microsoft AD domain and then configure Microsoft Enterprise CA on the EC2 instance.
- Security group to allow inbound and outbound traffic on EC2 instance.
- 1 Cloudwatch log group for CFN template.
- 1 secret created using AWS Secret Manager to securely store the credentials for CA admin. 
