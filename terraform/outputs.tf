# =============================================================================
# Outputs
# =============================================================================

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data (for kubectl config)"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs used by the EKS cluster"
  value       = module.vpc.private_subnets
}

output "node_security_group_id" {
  description = "Security group ID of the EKS managed node group"
  value       = module.eks.node_security_group_id
}

output "kubeconfig_command" {
  description = "AWS CLI command to configure kubectl for this cluster"
  value       = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.aws_region}"
  sensitive   = false
}
