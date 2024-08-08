data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical owner ID for Ubuntu AMIs

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_security_group" "polybot-ec2-sg" {
  name        = "polybot-ec2-sg"
  description = "example"
  vpc_id      = var.vpc_id
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

resource "aws_instance" "my_ec2" {
  for_each = tomap({"a" = var.public_subnets[0], "b" = var.public_subnets[1]})
#   depends_on = [aws_iam_instance_profile.ec2_instance_profile_poly, module.app_vpc, local_file.compose_user_data_poly]
  ami = data.aws_ami.ubuntu_ami.id
  instance_type = "t2.micro"


  key_name = var.ssh-key
  user_data = local_file.compose_user_data_poly.content
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile_poly.name
#   availability_zone = each.key
  subnet_id = each.value
  vpc_security_group_ids = [aws_security_group.polybot-ec2-sg.id]

  lifecycle {
    ignore_changes = [ami]
    replace_triggered_by = [local_file.generate-env-vars, local_file.compose_user_data_poly]
  }

  tags = {
    Name = "${var.pb-owner}-polybot"
  }
}
