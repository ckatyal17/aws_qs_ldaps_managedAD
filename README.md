# AWS Cloudformation (CFN) Template to configure LDAPS with AWS Managed Microsoft AD
This CFN template configures LDAP over SSL for AWS managed Microsoft AD directory using single tier Microsoft Enterprise Certification Authority.

## AWS Resources created by template
- 1 Windows 2019 EC2 instance.
- Instance profile and IAM roles with necessary permissions to access the resources required to configure CA. 
- SSM document to join EC2 instance to AWS Managed Microsoft AD domain and then configure Microsoft Enterprise CA on the EC2 instance.
- Security group to allow inbound and outbound traffic on EC2 instance.
- 1 Cloudwatch log group for CFN template.
- 1 secret created using AWS Secret Manager to securely store the credentials for CA admin. 

### Prerequisites:
- Existing AWS Managed Microsoft AD directory or create a new <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_getting_started_create_directory.html">AWS Managed Microsoft AD directory</a>.
- Configure outbound rule (egress) on the AWS Managed Microsoft AD domain security group to allow all outbound communication. Refer to the <a href="https://docs.aws.amazon.com/directoryservice/latest/admin-guide/ms_ad_tutorial_setup_trust_prepare_mad.html#tutorial_setup_trust_open_vpc">AWS Docs</a> on how to find and modify outbound rules on AWS Managed Microsoft AD domain security group.

### How to use "AWS_QS_LDAPS_managedAD" CloudFormation template:
- Download the CloudFormation template (src/CFN/AWS-QS-LDAPS-managedAD-templ.yml) file to your local computer.
- Log in to the <a href="https://console.aws.amazon.com/cloudformation">AWS Management Console</a> and select CloudFormation in the Services menu.
- <a href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-using-console-create-stack-template.html">Create a new stack</a> by uploading the CloudFormation (AWS-QS-LDAPS-managedAD-templ.yml). 
- Specify the required <a href="https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-using-console-create-stack-parameters.html">stack parameters</a> and launch the stack.

Note: AWS_QS_LDAPS_managedAD CloudFormation template takes about 40 minutes to deploy the required resources. There is no charge for using AWS CloudFormation, however, you will be charged for the resources created by AWS CloudFormation template. 
