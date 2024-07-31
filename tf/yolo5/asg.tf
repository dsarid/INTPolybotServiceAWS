#
#
# module "asg" {
#   source  = "terraform-aws-modules/autoscaling/aws"
#
#   # Autoscaling group
#   name = "yolo-tf-asg"
#
#   min_size                  = 0
#   max_size                  = 2
#   desired_capacity          = 0
#   wait_for_capacity_timeout = 0
#   health_check_type         = "EC2"
#   vpc_zone_identifier       = var.public_subnets
#
#   instance_refresh = {
#     strategy = "Rolling"
#     preferences = {
#       checkpoint_delay       = 600
#       checkpoint_percentages = [35, 70, 100]
#       instance_warmup        = 300
#       min_healthy_percentage = 50
#       max_healthy_percentage = 100
#     }
#     triggers = ["tag"]
#   }
#
#   # Launch template
#   launch_template_name        = "yolo5-tf-template"
#   launch_template_description = "Launch template example"
#   update_default_version      = true
#
#   image_id          = data.aws_ami.ubuntu_ami
#   instance_type     = "t2.medium"
#   ebs_optimized     = true
#   enable_monitoring = true
#
#   # IAM role & instance profile
#   create_iam_instance_profile = true
#   iam_role_name               = "example-asg"
#   iam_role_path               = "/ec2/"
#   iam_role_description        = "IAM role example"
#   iam_role_tags = {
#     CustomIamRole = "Yes"
#   }
#   iam_role_policies = {
#     AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   }
#
#   network_interfaces = [
#     {
#       delete_on_termination = true
#       description           = "eth0"
#       device_index          = 0
#       security_groups       = ["sg-12345678"]
#     },
#     {
#       delete_on_termination = true
#       description           = "eth1"
#       device_index          = 1
#       security_groups       = ["sg-12345678"]
#     }
#   ]
#
#   placement = {
#     availability_zone = "us-west-1b"
#   }
#
#   tag_specifications = [
#     {
#       resource_type = "instance"
#       tags          = { WhatAmI = "Instance" }
#     },
#     {
#       resource_type = "volume"
#       tags          = { WhatAmI = "Volume" }
#     },
#     {
#       resource_type = "spot-instances-request"
#       tags          = { WhatAmI = "SpotInstanceRequest" }
#     }
#   ]
#
#   tags = {
#     Environment = "dev"
#     Project     = "megasecret"
#   }
# }