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
  type        = string
}

variable "TFC_AWS_RUN_ROLE_ARN" {
  description = "AWS role ARN to be assumed"
  type        = string
}

provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_vpc" "poly_asia" {
  cidr_block = "172.16.0.0/16"
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.poly_asia.default_network_acl_id

  ingress {
    rule_no    = 100
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    from_port  = 0
    to_port    = 0
    action     = "allow"
  }

  egress {
    rule_no    = 100
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    from_port  = 0
    to_port    = 0
    action     = "allow"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.poly_asia.id

  ingress {
    self      = true
    protocol  = -1
    from_port = 0
    to_port   = 0
  }

  ingress {
    cidr_blocks = "0.0.0.0/0"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
  }

  egress {
    cidr_blocks = "0.0.0.0/0"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
  }
}

resource "aws_security_group" "db" {
  name        = "db_sg"
  description = "Security group for DB instances"
  vpc_id      = aws_vpc.poly_asia.id
}

resource "allow_vpc_security_group_ingress_rule" "allow_server" {
  security_group_id = aws_security_group.db.id
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
  security_group    = aws_security_group.default.id
}

resource "allow_vpc_security_group_egress_rule" "allow_server" {
  security_group_id = aws_security_group.db.id
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
  security_group    = aws_security_group.default.id
}
