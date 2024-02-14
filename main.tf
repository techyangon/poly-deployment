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
