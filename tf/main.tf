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
# provider "aws" {
#   alias  = "perm"
#   region  = "eu-central-1"
# }

provider "tls" {
#   algorithm = "ECDSA"
}

provider "aws" {
  region  = var.region
}

/*
 Use resource blocks to define components of your infrastructure.
 A resource might be a physical or virtual component such as an EC2 instance.
 A resource block declares a resource of a given type ("aws_instance") with a given local name ("app_server").
 The name is used to refer to this resource from elsewhere in the same Terraform module, but has no significance outside that module's scope.
 The resource type and name together serve as an identifier for a given resource and so must be unique within a module.

 For full description of this resource: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
*/

data "aws_availability_zones" "available_azs"{
  state = "available"
}
data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical owner ID for Ubuntu AMIs

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_s3_bucket" "main-bucket" {
  bucket = "danielms-tf-main-s3-${var.region}"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

# resource "aws_s3_bucket" "main-bucket" {
#     bucket = "shared-services"
#
#   tags = {
#     Name        = "My bucket"
#     Environment = "Dev"
#   }
# }


module "app_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  map_public_ip_on_launch = true

  name = "module-vpc"
  cidr = "10.0.0.0/16"

  azs             = [data.aws_availability_zones.available_azs.names[0], data.aws_availability_zones.available_azs.names[1]]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  enable_nat_gateway = false

  tags = {
    Name        = "${var.owner}-tf-project-vpc"
    Env         = var.env
    Terraform   = true
  }
}



resource "aws_sqs_queue" "polybot-sqs" {
  name                      = "${var.owner}-tf-queue"
  delay_seconds             = 0
  max_message_size          = 8192
  message_retention_seconds = 86400
  visibility_timeout_seconds = 60
  receive_wait_time_seconds = 0

  tags = {
    Environment = var.env
  }
}


resource "aws_security_group" "polybot-ec2-sg" {
  name        = "polybot-ec2-sg"
  description = "example"
  vpc_id      = module.app_vpc.vpc_id
  tags = {
    Name = "example"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh-polybot-in" {
  security_group_id = aws_security_group.polybot-ec2-sg.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  to_port   = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "lb-in" {
  security_group_id = aws_security_group.polybot-ec2-sg.id
  referenced_security_group_id = aws_security_group.lb-sg.id
  from_port   = 8443
  to_port   = 8443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "internet_access" {
  security_group_id = aws_security_group.polybot-ec2-sg.id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}

# import {
#   id = "arn:aws:sqs:eu-central-1:019273956931:dms-aws-project-queue"
#   to = aws_sqs_queue.polybot-sqs
# }



resource "aws_secretsmanager_secret" "telegram_token" {
  name = "tf-telegram-token-tf-new"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.telegram_token.id
  secret_string = jsonencode({
    TELEGRAM_BOT_TOKEN = var.botToken
  })
}

resource "aws_instance" "my_ec2" {
  for_each = tomap({"a" = module.app_vpc.public_subnets[0], "b" = module.app_vpc.public_subnets[1]})
  depends_on = [aws_iam_instance_profile.ec2_instance_profile_poly, module.app_vpc, local_file.compose_user_data_poly]
#   ami = "ami-0e872aee57663ae2d"
  ami = data.aws_ami.ubuntu_ami.id
  instance_type = "t2.micro"

  key_name = "dsarid-frankfurt-key"
  user_data = file("./polybot-user-data")
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile_poly.name
#   availability_zone = each.key
  subnet_id = each.value
  vpc_security_group_ids = [aws_security_group.polybot-ec2-sg.id]
  lifecycle {
    ignore_changes = [ami]
    replace_triggered_by = [local_file.generate-env-vars, local_file.compose_user_data_poly]
  }
#   provisioner "file" {
#     source = "./tf-env-vars.env"
#     destination = "/home/ubuntu/.env"
#   }
#
#   connection {
#     type = "ssh"
#     user = "ubuntu"
#     private_key = file("./")
#   }
  tags = {
    Name = "dsarid-webserver"
  }
}
