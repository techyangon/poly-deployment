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
