# AWS Cloudformation (CFN) Template to configure LDAPS with AWS Managed Microsoft AD
Configure LDAP over SSL for AWS managed Microsoft AD directory using single tier Microsoft Enterprise Certification Authority.

## AWS Resources created by template
- 1 Windows 2019 EC2 instance.
- Instance profile and IAM roles with necessary permissions to access the resorces required to configure CA. 
- SSM document to join EC2 instance to AWS Managed Microsoft AD domain and then configure Microsoft Enterprise CA on the EC2 instance.
- Security group to allow inbound and outbound traffic on EC2 instance.
- 1 Cloudwatch log group for CFN template.
- 1 secret created using AWS Secret Manager to securely store the credentials for CA admin. 

### Prerequisites:
- Existing AWS Managed Microsoft AD directory or create a new <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_getting_started_create_directory.html">AWS Managed Microsoft AD directory</a>.
- Configure outbound rule (egress) on the AWS Managed Microsoft AD domain security group to allow all outbound communication. Refer to the <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_tutorial_setup_trust_prepare_mad.html#tutorial_setup_trust_open_vpc">AWS Docs</a> on how to find and modify outbound rules on AWS Managed Microsoft AD domain security group.
