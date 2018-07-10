# This piece of terraform code launches EC2 instance that has permissions to write to S3 bucket
# specified on the command line. Cloud-init script of EC2 instance creates a file 'a.txt' with 
# internal hostname of EC2 instance and copies the same to S3 bucket

# This code launches EC2 instance in the default VPC instead of creating a new VPC altogether.

# Variable Declarations
variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}
variable "region" {
    default = "us-west-2"
}
variable "bucket_name" {}

# AWS provider configuration
provider "aws" {
    access_key = "${var.aws_access_key_id}"
    secret_key = "${var.aws_secret_access_key}"
    region = "${var.region}"
}

# Create S3 bucket
resource "aws_s3_bucket" "tf-site-demo" {
    bucket = "${var.bucket_name}"
    acl = "public-read"

    tags {
        Name = "${var.bucket_name}"
        Product = "Terraform-Demo"
    }
}

#Set profile for EC2 instance so that it can access S3

resource "aws_iam_role" "ec2_s3_profile_role" {
    name = "ec2_s3_profile_role"
    path = "/"

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
        "Effect": "Allow",
        "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "ec2_s3_profile_role_policy" {
	name = "ec2_s3_profile_role_policy"
	role = "${aws_iam_role.ec2_s3_profile_role.id}"
	policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
	    {
		    "Effect": "Allow",
		    "Action": ["s3:ListBucket"],
		    "Resource": ["arn:aws:s3:::${var.bucket_name}"]
	    },
	    {
		    "Effect": "Allow",
		    "Action": ["s3:*"],
		    "Resource": ["arn:aws:s3:::${var.bucket_name}/*"]
	    }
	]
}
EOF
}

resource "aws_iam_instance_profile" "ec2_s3_instance_profile" {
	name = "ec2_s3_instance_profile"
	role = "${aws_iam_role.ec2_s3_profile_role.name}"
}

# Launch template for EC2 instance that defines the configuration of EC2 instances when they come up

resource "aws_launch_template" "launch_template_tf_demo" {
    name = "launch_template_tf_demo"
    iam_instance_profile {
        name = "${aws_iam_instance_profile.ec2_s3_instance_profile.name}"
    }
    image_id = "ami-a9d09ed1"
    instance_type = "t2.micro"
    tag_specifications {
        resource_type = "instance"
        tags {
            Name = "launch_template_tf_demo"
            Product = "Terraform-Demo"
        }
    }
    lifecycle {
        create_before_destroy = true
    }
    user_data = "${base64encode("#!/usr/bin/env bash \n curl -s http://169.254.169.254/latest/meta-data/local-hostname > /tmp/a.txt \n aws s3 cp /tmp/a.txt s3://${var.bucket_name}/a.txt")}"
}

# Autoscaling group to ensure that desired number of instances are up and running all the time

resource "aws_autoscaling_group" "asg_tf_demo" {
    name = "${aws_launch_template.launch_template_tf_demo.name}-asg"
    availability_zones = ["us-west-2a"]
    desired_capacity = 1
    max_size = 1
    min_size = 1
    launch_template = {
        id = "${aws_launch_template.launch_template_tf_demo.id}"
        version = "$$Latest"
    }
    tags = [
    {
        key                 = "Name"
        value               = "${aws_launch_template.launch_template_tf_demo.name}-asg"
        propagate_at_launch = true
    },
    {
        key                 = "Product"
        value               = "Terraform-Demo"
        propagate_at_launch = true
    },
    ]

}



