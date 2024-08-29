/*
 The terraform {} block contains Terraform settings, including the required providers Terraform will use to provision infrastructure.
 Terraform installs providers from the Terraform Registry by default.
 In this example configuration, the aws provider's source is defined as hashicorp/aws,
*/
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.64.0"
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


resource "aws_s3_bucket" "main-bucket" {
  bucket = "danielms-tf-main-s3-${var.region}"
  force_destroy = true
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

resource "aws_key_pair" "deployer" {
  key_name   = "${var.owner}-ec2-key-${var.region}"
  public_key = var.sshPubKey
}

# variable "awsKEY" {
#   type = string
# }
#
# variable "awsSECRET" {
#   type = string
# }

module "poly_ecr" {
  source = "./poly_ecr"
}

module "yolo_ecr" {
  source = "./yolo_ecr"
}

module "polybot" {
  source = "./polybot"

  pb-env             = var.env
  pb-token           = var.botToken
  pb-owner           = var.owner
#   cert_arn           = aws_acm_certificate.cert.arn
#   dns_name           = aws_lb.main-lb.dns_name
  dynamo_table_name  = module.dynamodb_table.dynamodb_table_id
  dynamodb_table_arn = module.dynamodb_table.dynamodb_table_arn
#   lb_sg_id           = aws_security_group.lb-sg.id
  public_subnets     = [module.app_vpc.public_subnets[0], module.app_vpc.public_subnets[1]]
  pb-region          = var.region
  s3_arn             = aws_s3_bucket.main-bucket.arn
  s3_name            = aws_s3_bucket.main-bucket.bucket
  sqs_arn            = aws_sqs_queue.polybot-sqs.arn
  sqs_name           = aws_sqs_queue.polybot-sqs.name
  vpc_id             = module.app_vpc.vpc_id
#   pb-keyName         = var.keyName
  ssh-key            = aws_key_pair.deployer.key_name
  ecr_arn            = module.poly_ecr.ecr_arn
  ecr_name           = module.poly_ecr.ecr_name
  ecr_id             = module.poly_ecr.ecr_registry
}


module "yolo5" {
  source = "./yolo5"

  dns_name           = module.polybot.dns_name
  dynamo_table_name  = module.dynamodb_table.dynamodb_table_id
  dynamodb_table_arn = module.dynamodb_table.dynamodb_table_arn
  y5-env             = var.env
  y5-owner           = var.owner
  y5-region          = var.region
  public_subnets     = [module.app_vpc.public_subnets[0], module.app_vpc.public_subnets[1]]
  s3_arn             = aws_s3_bucket.main-bucket.arn
  s3_name            = aws_s3_bucket.main-bucket.bucket
  sqs_arn            = aws_sqs_queue.polybot-sqs.arn
  sqs_name           = aws_sqs_queue.polybot-sqs.name
  vpc_id             = module.app_vpc.vpc_id
#   y5-keyName         = var.keyName
  ssh-key            = aws_key_pair.deployer.key_name
  ecr_arn            = module.yolo_ecr.ecr_arn
  ecr_id             = module.yolo_ecr.ecr_registry
  ecr_name           = module.yolo_ecr.ecr_name
}
