locals {
  region = var.region

}

data "aws_availability_zones" "available" {}




module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                 = "${var.environment}-vpc"
  cidr                 = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = var.private_subnets
  public_subnets       = var.public_subnets
  enable_nat_gateway   = true

}
