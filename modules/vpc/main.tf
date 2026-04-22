module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.environment}-vault-vpc"
  cidr = var.vpc_cidr

  # Multi-AZ deployment for High Availability
  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = [cidrsubnet(var.vpc_cidr, 8, 1), cidrsubnet(var.vpc_cidr, 8, 2)]
  public_subnets  = [cidrsubnet(var.vpc_cidr, 8, 101), cidrsubnet(var.vpc_cidr, 8, 102)]

  # PRODUCTION STRATEGY: One NAT Gateway per Availability Zone.
  # This ensures that if us-east-1a goes down, the nodes in us-east-1b 
  # still have outbound internet access via their own NAT.
  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = var.environment
    Project     = "Vault-Fargate-KMS"
    ManagedBy   = "Terraform"
  }
}