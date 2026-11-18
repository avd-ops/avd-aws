terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60"
    }
  }
}

resource "aws_vpc" "avd" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "vpc-avd-hybrid-${var.environment}"
    Environment = var.environment
    avd-ops     = "hybrid-aws"
  }
}

resource "aws_subnet" "hosts" {
  vpc_id                  = aws_vpc.avd.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name        = "snet-avd-hosts-${var.environment}"
    Environment = var.environment
    avd-ops     = "hybrid-aws"
  }
}

resource "aws_subnet" "nat" {
  count                   = var.egress_mode == "nat-gateway" ? 1 : 0
  vpc_id                  = aws_vpc.avd.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name        = "snet-avd-nat-${var.environment}"
    Environment = var.environment
    avd-ops     = "hybrid-aws"
  }
}

resource "aws_internet_gateway" "avd" {
  count  = var.egress_mode == "nat-gateway" ? 1 : 0
  vpc_id = aws_vpc.avd.id

  tags = {
    Name        = "igw-avd-hybrid-${var.environment}"
    Environment = var.environment
    avd-ops     = "hybrid-aws"
  }
}

resource "aws_eip" "nat" {
  count  = var.egress_mode == "nat-gateway" ? 1 : 0
  domain = "vpc"

  tags = {
    Name        = "eip-avd-nat-${var.environment}"
    Environment = var.environment
    avd-ops     = "hybrid-aws"
  }

  depends_on = [aws_internet_gateway.avd]
}

resource "aws_nat_gateway" "avd" {
  count         = var.egress_mode == "nat-gateway" ? 1 : 0
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.nat[0].id

  tags = {
    Name        = "nat-avd-hybrid-${var.environment}"
    Environment = var.environment
    avd-ops     = "hybrid-aws"
  }

  depends_on = [aws_internet_gateway.avd]
}

resource "aws_route_table" "public" {
  count  = var.egress_mode == "nat-gateway" ? 1 : 0
  vpc_id = aws_vpc.avd.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.avd[0].id
  }

  tags = {
    Name        = "rt-avd-public-${var.environment}"
    Environment = var.environment
    avd-ops     = "hybrid-aws"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.egress_mode == "nat-gateway" ? 1 : 0
  subnet_id      = aws_subnet.nat[0].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table" "private" {
  count  = var.egress_mode == "nat-gateway" ? 1 : 0
  vpc_id = aws_vpc.avd.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.avd[0].id
  }

  tags = {
    Name        = "rt-avd-private-${var.environment}"
    Environment = var.environment
    avd-ops     = "hybrid-aws"
  }
}

resource "aws_route_table_association" "private" {
  count          = var.egress_mode == "nat-gateway" ? 1 : 0
  subnet_id      = aws_subnet.hosts.id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_security_group" "session_host" {
  name                   = "avd-hosts-sg-${var.environment}"
  description            = "AVD Hybrid session hosts: outbound HTTPS (443) and optional RDP Shortpath (UDP 3478); no inbound internet RDP."
  vpc_id                 = aws_vpc.avd.id
  revoke_rules_on_delete = true
  ingress                = []

  egress {
    description = "Azure Arc, Entra ID, and AVD control-plane outbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "egress" {
    for_each = var.enable_rdp_shortpath_udp_3478 ? [1] : []
    content {
      description = "AVD RDP Shortpath STUN/TURN outbound UDP"
      from_port   = 3478
      to_port     = 3478
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Name        = "sg-avd-hosts-${var.environment}"
    Environment = var.environment
    avd-ops     = "hybrid-aws"
  }
}
