# Root Terraform configuration that orchestrates all modules

# Module 1: VPC and Networking
# Creates VPC, subnets, internet gateway, NAT gateway, and route tables
module "vpc" {
  source = "./modules/vpc"

  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
}

# Module 2: IAM Roles and Policies
# Creates IAM roles for EKS cluster and worker nodes with required policies
module "iam" {
  source = "./modules/iam"

  cluster_name = var.cluster_name
}

# Module 3: EKS Cluster and Node Groups
# Creates EKS cluster, security group, and managed node group
module "eks" {
  source = "./modules/eks"

  cluster_name            = var.cluster_name
  cluster_version         = var.cluster_version
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  public_subnet_ids       = module.vpc.public_subnet_ids
  cluster_role_arn        = module.iam.eks_cluster_role_arn
  node_group_role_arn     = module.iam.eks_node_group_role_arn
  node_group_desired_size = var.node_group_desired_size
  node_group_min_size     = var.node_group_min_size
  node_group_max_size     = var.node_group_max_size
  node_instance_types     = var.node_instance_types

  depends_on = [
    module.vpc,
    module.iam
  ]
}

# Module 4: Monitoring with AWS Managed Prometheus and Grafana
# Creates AWS Managed Prometheus workspace and Grafana workspace
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name      = var.cluster_name
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(module.eks.oidc_provider_arn, "https://", "")}"
  oidc_provider     = replace(module.eks.oidc_provider_arn, "https://", "")

  depends_on = [
    module.eks
  ]
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

