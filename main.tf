terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "TFC_AWS_PROVIDER_AUTH" {
  description = "Flag to use dynamic credentials"
  type        = bool
}

variable "TFC_AWS_RUN_ROLE_ARN" {
  description = "AWS role ARN to be assumed"
  type        = string
}

variable "NAT_ALLOCATION_ID" {
  type = string
}

variable "WEB_ALLOCATION_ID" {
  type = string
}

variable "VPC_CIDR_BLOCK" {
  type = string
}

variable "WEB_CIDR_BLOCK" {
  type = string
}

variable "DB_CIDR_BLOCK" {
  type = string
}

variable "RDS_MASTER_PASSWORD" {
  type = string
}

variable "EC2_AMI_ID" {
  type = string
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_vpc" "poly_asia" {
  cidr_block = var.VPC_CIDR_BLOCK
}

resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.poly_asia.id
  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "web" {
  vpc_id            = aws_vpc.poly_asia.id
  cidr_block        = var.WEB_CIDR_BLOCK
  availability_zone = "ap-southeast-1a"
  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "db" {
  vpc_id            = aws_vpc.poly_asia.id
  cidr_block        = var.DB_CIDR_BLOCK
  availability_zone = "ap-southeast-1a"
  tags = {
    Name = "private"
  }
}

resource "aws_nat_gateway" "public" {
  allocation_id = var.NAT_ALLOCATION_ID
  subnet_id     = aws_subnet.web.id
  depends_on    = [aws_internet_gateway.default]
}

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.poly_asia.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.default.id
  }
}

resource "aws_route_table" "db" {
  vpc_id = aws_vpc.poly_asia.id

  route {
    gateway_id     = aws_internet_gateway.default.id
    nat_gateway_id = aws_nat_gateway.public.id
  }
}

resource "aws_route_table_association" "default" {
  subnet_id      = aws_subnet.web.id
  route_table_id = aws_default_route_table.default.id
}

resource "aws_route_table_association" "db" {
  subnet_id      = aws_subnet.db.id
  route_table_id = aws_route_table.db.id
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.poly_asia.default_network_acl_id

  ingress {
    rule_no    = 100
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    from_port  = 0
    to_port    = 65535
    action     = "allow"
  }

  egress {
    rule_no    = 100
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    from_port  = 0
    to_port    = 65535
    action     = "allow"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.poly_asia.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 0
    to_port     = 65535
  }
}

resource "aws_security_group" "db" {
  name        = "db_sg"
  description = "Security group for DB instances"
  vpc_id      = aws_vpc.poly_asia.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_server" {
  security_group_id            = aws_security_group.db.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_default_security_group.default.id
}

resource "aws_vpc_security_group_egress_rule" "allow_server" {
  security_group_id            = aws_security_group.db.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = aws_default_security_group.default.id
}

resource "aws_network_interface" "server" {
  subnet_id       = aws_subnet.web.id
  private_ip      = "172.16.0.4"
  security_groups = [aws_default_security_group.default.id]
}

resource "aws_eip_association" "server" {
  allocation_id        = var.WEB_ALLOCATION_ID
  network_interface_id = aws_network_interface.server.id
}

resource "aws_instance" "web" {
  ami                                  = var.EC2_AMI_ID
  instance_type                        = "t2.micro"
  instance_initiated_shutdown_behavior = "terminate"
  network_interface {
    network_interface_id = aws_network_interface.server.id
    device_index         = 0
  }
  tags = {
    Name = "Web server"
  }
}
