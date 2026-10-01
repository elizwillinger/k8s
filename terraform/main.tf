# =============================================================================
# VPC
# =============================================================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  enable_dns_hostnames = true
  enable_dns_support   = true

  cidr           = var.vpc_cidr
  azs            = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false

  # Tags for public subnets (needed for EKS auto-discovery)
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  # Tags for private subnets (needed for EKS auto-discovery)
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

# =============================================================================
# EKS Cluster
# =============================================================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Enable IRSA for workload identity
  enable_irsa = true

  # CloudWatch logging
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  create_cloudwatch_log_group = true

  # ---------- IAM ----------

  # Grant the Terraform runner admin access to the cluster
  enable_cluster_creator_admin_permissions = true

  # Node IAM role — the module creates one by default with the right policies
  create_node_iam_role = true

  # Prevent multiple security groups with ambiguous cluster tags
  create_node_security_group = false

  # ---------- Node Group ----------

  eks_managed_node_group_defaults = {
    ami_type       = "AL2023_x86_64_STANDARD"
    disk_size      = var.node_groups.disk_size
    subnets        = module.vpc.private_subnets
    attach_cluster_primary_security_group = true
  }

  eks_managed_node_groups = {
    default = {
      name = "${var.project_name}-node-group"

      instance_types = var.node_groups.instance_types
      min_size       = var.node_groups.min_size
      max_size       = var.node_groups.max_size
      desired_size   = var.node_groups.desired_size

      # SSH key pair (optional — leave empty if not needed)
      key_name = var.node_groups.key_name

      # Kubelet extra args: set max-pods appropriately
      kubelet_extra_args = "--max-pods=10"

      labels = {
        role = "workers"
      }

      tags = {
        Name = "${var.project_name}-eks-node"
      }
    }
  }
}
