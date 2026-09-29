# -----------------------------------------------------------------------------
# Variables
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Name of the project (used as prefix for resource naming)"
  type        = string
  default     = "k8slab"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "k8slab-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.36"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "node_groups" {
  description = "EKS managed node group configuration"
  type = object({
    desired_size = number
    max_size     = number
    min_size     = number
    instance_types = list(string)
    disk_size    = number
    key_name     = string
  })
  default = {
    desired_size = 2
    max_size     = 4
    min_size     = 1
    instance_types = ["t3.medium"]
    disk_size    = 20
    key_name     = ""
  }
}


variable "budget_email" {
  description = "Email address for AWS Budget alerts (80% and 100% thresholds)"
  type        = string
}
