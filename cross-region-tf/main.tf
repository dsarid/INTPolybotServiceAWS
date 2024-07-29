/*
 The terraform {} block contains Terraform settings, including the required providers Terraform will use to provision infrastructure.
 Terraform installs providers from the Terraform Registry by default.
 In this example configuration, the aws provider's source is defined as hashicorp/aws,
*/
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.52"
    }
  }

  backend "s3" {
    bucket = "danielms-tf-backup"
    key    = "tfstate.json"
    region = "eu-central-1"
    # optional: dynamodb_table = "<table-name>"
  }

  required_version = ">= 1.2.0"
}


/*
 The provider block configures the specified provider, in this case aws.
 You can use multiple provider blocks in your Terraform configuration to manage resources from different providers.
*/
provider "aws" {
  region  = "eu-central-1"
}

resource "aws_iam_role" "polybot-role" {
  name                = "dsarid-polybot-tf-role"
  assume_role_policy  = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
  })
  managed_policy_arns = [aws_iam_policy.policy_one.arn, aws_iam_policy.policy_two.arn]
}

resource "aws_iam_policy" "policy_one" {
  name = "policy-618033"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": [
                "arn:aws:secretsmanager:eu-central-1:019273956931:secret:cert_public_key-K5bN0T",
                "arn:aws:secretsmanager:eu-central-1:019273956931:secret:telegram_bot_token-ILCci7"
            ]
        }
    ]
  })
}

resource "aws_iam_policy" "policy_two" {
  name = "danielms-ecr-tf-policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:DescribeImages"
            ],
            "Resource": [
                "arn:aws:ecr:eu-central-1:019273956931:repository/aws-project-polybot"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "ecr:GetAuthorizationToken",
            "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "danielms-polybot-iam"

  role = aws_iam_role.polybot-role.name  // Reference to the IAM role name
}
