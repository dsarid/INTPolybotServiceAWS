resource "aws_security_group" "lb-sg" {
  name        = "tf-lb-security-group"
  description = "example"
  vpc_id      = var.vpc_id
  tags = {
    Name = "tf-lb-security-group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "telegram-in-1" {
  security_group_id = aws_security_group.lb-sg.id
  cidr_ipv4   = "91.108.4.0/22"
  from_port   = 8443
  to_port   = 8443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "telegram-in-2" {
  security_group_id = aws_security_group.lb-sg.id
  cidr_ipv4   = "149.154.160.0/20"
  from_port   = 8443
  to_port   = 8443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "lb-out" {
  security_group_id = aws_security_group.lb-sg.id
  cidr_ipv4 = "0.0.0.0/0"
  ip_protocol = -1
}

resource "aws_lb" "main-lb" {
#   depends_on = [module.app_vpc]
  name               = "${var.pb-owner}-tf-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb-sg.id]
  subnets = var.public_subnets
  enable_deletion_protection = false

#   provisioner "local-exec" {
#     command = "openssl req -newkey rsa:2048 -sha256 -nodes -keyout YOURPRIVATE.key -x509 -days 365 -out YOURPUBLIC.pem -subj \"/C=IL/ST=Jerusalem/L=Jerusalem/O=None/CN=${self.dns_name}\""
#     working_dir = "/home/pugo/Documents/aws-project/INTPolybotServiceAWS/tf"
#     when = create
#   }

  tags = {
    Environment = var.pb-env
  }
}


resource "aws_lb_target_group" "polybot-tf-tg" {
  depends_on = [aws_lb.main-lb]
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "front_end" {
  depends_on = [aws_acm_certificate.cert, aws_lb.main-lb]
  load_balancer_arn = aws_lb.main-lb.arn
  port              = "8443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.polybot-tf-tg.arn
  }
}

resource "tls_private_key" "main_cert_key" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "main_cert" {
#   key_algorithm   = "RSA"
  private_key_pem = tls_private_key.main_cert_key.private_key_pem

  subject {
    common_name  = aws_lb.main-lb.dns_name
    organization = "ACME Examples, Inc"
  }

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "cert" {
  private_key = tls_private_key.main_cert_key.private_key_pem
  certificate_body = tls_self_signed_cert.main_cert.cert_pem
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.polybot-tf-tg.id
#   target_id        = aws_instance.my_ec2.id
  for_each = {
    for k, v in aws_instance.my_ec2 :
    k => v
  }

  target_id        = each.value.id
  port             = 8443
}