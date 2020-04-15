data "aws_acm_certificate" "default" {
  domain   = var.cert_domain
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "default" {
  name         = var.zone
  private_zone = false
}


resource "aws_security_group" "lb" {
  name        = "${var.prefix}-ALB"
  description = "Controls access from/to load balancer"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = [
      { port = 80 },
      { port = 443 }
    ]
    iterator = it
    content {
      from_port   = it.value.port
      to_port     = it.value.port
      protocol    = lookup(it.value, "protocol", "tcp")
      cidr_blocks = lookup(it.value, "cidr_blocks", ["0.0.0.0/0"])
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-ALB"
  }
}

resource "aws_lb" "default" {
  name               = var.prefix
  load_balancer_type = "application"
  internal           = false
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.lb.id]
  tags = {
    Name = var.prefix
  }
}

resource "aws_lb_target_group" "http" {
  name     = "${var.prefix}-Http"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "HTTP" {
  load_balancer_arn = aws_lb.default.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.default.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-2019-08"
  certificate_arn   = data.aws_acm_certificate.default.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

resource "aws_lb_target_group_attachment" "server-http" {
  target_group_arn = aws_lb_target_group.http.arn
  target_id        = var.instance_id
}

resource "aws_route53_record" "cname_record" {
  zone_id = data.aws_route53_zone.default.zone_id
  name    = var.service_domain
  type    = "CNAME"
  ttl     = "60"
  records = [aws_lb.default.dns_name]
}
