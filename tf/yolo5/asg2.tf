data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical owner ID for Ubuntu AMIs

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}


resource "aws_launch_template" "yolo5_launch_template" {
#   depends_on = [aws_ecr_repository.yolo5-ecr]
  instance_type                        = "t2.medium"
  name                                 = "yolo5-tf-asg-template"
  image_id                             = data.aws_ami.ubuntu_ami.id
  disable_api_stop                     = false
  disable_api_termination              = false
  key_name                             = var.ssh-key
  user_data                            = base64encode(local_file.compose_user_data_poly.content)
  vpc_security_group_ids = [aws_security_group.yolo5-lt-sg.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.ec2_instance_profile_yolo.arn
  }

  block_device_mappings {
    device_name  = "/dev/sda1"

    ebs {
      delete_on_termination = "true"
      encrypted             = "false"
      iops                  = 3000
      throughput            = 125
      volume_size           = 20
      volume_type           = "gp3"
    }
  }
  lifecycle {
    replace_triggered_by = [local_file.generate-env-vars, local_file.compose_user_data_poly]
  }
}

resource "aws_autoscaling_group" "yolo5-asg" {
  launch_template {
    id      = aws_launch_template.yolo5_launch_template.id
    version = "$Latest"
  }

  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  vpc_zone_identifier  = var.public_subnets

  tag {
    key                 = "Name"
    value               = "yolo5-asg"
    propagate_at_launch = true
  }

  health_check_type          = "EC2"
  health_check_grace_period  = 300
#   force_delete                = true
  wait_for_capacity_timeout     = "0"
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.yolo5-asg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.yolo5-asg.name
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name                = "high-cpu-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 60
  alarm_description         = "This metric monitors EC2 CPU utilization and triggers scale up policy if it exceeds 60%."
  insufficient_data_actions = []

  alarm_actions = [
    aws_autoscaling_policy.scale_up.arn
  ]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.yolo5-asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name                = "low-cpu-alarm"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = 300
  statistic                 = "Average"
  threshold                 = 20
  alarm_description         = "This metric monitors EC2 CPU utilization and triggers scale down policy if it falls below 20%."
  insufficient_data_actions = []

  alarm_actions = [
    aws_autoscaling_policy.scale_down.arn
  ]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.yolo5-asg.name
  }
}