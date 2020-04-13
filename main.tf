provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}


locals {
  subnets = cidrsubnets(var.vpc_cidr_block, 8, 8, 8, 8)
  server_subnet_index = 0
}


data "aws_acm_certificate" "default" {
  domain   = var.domain
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "default" {
  name         = var.zone
  private_zone = false
}

data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_vpc" "default" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = var.prefix
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

resource "aws_subnet" "public" {
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.default.id
  availability_zone_id    = data.aws_availability_zones.available.zone_ids[count.index]
  cidr_block              = locals.subnets[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.prefix}-Public-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count                = var.private_subnet_count
  vpc_id               = aws_vpc.default.id
  availability_zone_id = data.aws_availability_zones.available.zone_ids[count.index]
  cidr_block           = locals.subnets[count.index + var.public_subnet_count]
  tags = {
    Name = "${var.prefix}-Private-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.default.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }
  tags = {
    Name = "${var.prefix}-Public"
  }
}

resource "aws_lb" "default" {
  name               = "${var.prefix}-Default"
  load_balancer_type = "application"
  internal           = false
  subnets            = locals.subnets
  security_groups    = [aws_security_group.lb.id]
  tags = {
    Name = "${var.prefix}-Default"
  }
}

resource "aws_lb_target_group" "default" {
  name     = "${var.prefix}-Default"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.default.id
}

resource "aws_lb_listener" "http" {
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
    target_group_arn = aws_lb_target_group.default.arn
  }
}

resource "aws_route53_record" "cname_record" {
  zone_id = data.aws_route53_zone.default.zone_id
  name    = var.domain
  type    = "CNAME"
  ttl     = "60"
  records = [aws_lb.default.dns_name]
}

resource "aws_key_pair" "default" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "default" {
  name        = "${var.prefix}-Default"
  description = "Controls access from/to instance"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "${var.prefix}-Default"
  }
}

resource "aws_security_group" "lb" {
  name        = "${var.prefix}-ALB"
  description = "Controls access from/to load balancer"
  vpc_id      = aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "${var.prefix}-ALB"
  }
}

resource "aws_instance" "server" {
  instance_type = var.instance_type
  ami           = "ami-0e698fee1e6224f1a"
  subnet_id     = aws_subnet.public[local.server_subnet_index].id
  vpc_security_group_ids = [
    aws_security_group.default.id
  ]
  key_name = aws_key_pair.default.id
  tags = {
    Name     = var.prefix
  }

  connection {
    type    = "ssh"
    host    = self.public_ip
    user    = "ubuntu"
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "cat ./bitnami_credentials"
    ]
  }
}

resource "aws_ebs_volume" "storage" {
  type              = "gp2"
  availability_zone = data.aws_availability_zones.available[locals.server_subnet_index]
  size              = 10
  iops              = 100
  tags = {
    Name = var.prefix
  }
}

resource "aws_volume_attachment" "server-storage" {
  device_name = "/dev/sda1"
  volume_id   = aws_ebs_volume.storage.id
  instance_id = aws_instance.server.id
}

resource "aws_lb_target_group_attachment" "server-default" {
  target_group_arn = aws_lb_target_group.default.arn
  target_id        = aws_instance.server.id
}
