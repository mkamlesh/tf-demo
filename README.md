# Terraform Demo

Using terraform, create the following resources in AWS
EC2 instance
S3 Bucket
By making use of userdata, echo some (ie ami-id, hostname etc) instance metadata to a file and copy that file to the s3 bucket.

The terraform command should look as follows
`terraform apply –var 'aws_access_key_id=<your access key>' –var 'aws_secret_access_key=<your secret access key>' -var 'bucket_name=<a globally unique name>'`

### Constraints
  * Do not use the aws_instance resource provided by terraform, rather, make use of autoscaling groups
  * Do not commit any aws credentials to source control of any kind.
  * No aws access key id or secret access key information is to be present on the ec2 instance
  * The whole project should be contained within a single file called site.tf
  * Access to the S3 bucket from the EC2 instance should be done via Instance Roles
  * This should be achievable using the AWS free tier
