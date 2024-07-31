
resource "aws_security_group" "yolo5-lt-sg" {
  name        = "yolo5-ec2-sg"
  description = "example"
  vpc_id      = var.vpc_id
  tags = {
    Name = "example"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh-yolo5-in" {
  security_group_id = aws_security_group.yolo5-lt-sg.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  to_port   = 22
  ip_protocol = "tcp"
}

#
# resource "aws_vpc_security_group_ingress_rule" "lb-in" {
#   security_group_id = aws_security_group.yolo5-lt-sg.id
#   referenced_security_group_id = aws_security_group.lb-sg.id
#   from_port   = 8443
#   to_port   = 8443
#   ip_protocol = "tcp"
# }

resource "aws_vpc_security_group_egress_rule" "internet_access" {
  security_group_id = aws_security_group.yolo5-lt-sg.id
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = -1
}

