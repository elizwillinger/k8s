# EKS Cluster — Terraform

Provision an EKS cluster with a managed node group using the official
`terraform-aws-modules/eks/aws` module.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- `kubectl` installed

## Quick Start

```bash
cd terraform

# Review what will be created
terraform plan -var-file="variables.tf"

# Apply
terraform apply

# After apply, configure kubectl:
aws eks update-kubeconfig --name k8slab-eks-cluster --region <region>
```

## Architecture

```
VPC (10.0.0.0/16)
├── Public Subnets  (10.0.101-103.0/24) — NAT Gateway
├── Private Subnets (10.0.1-3.0/24)
│   └── EKS Managed Node Group
└── EKS Control Plane (public + private endpoint)
```

## Customization

Edit `variables.tf` defaults or pass overrides at runtime:

```bash
terraform apply \
  -var="aws_region=us-west-2" \
  -var="cluster_version=1.30" \
  -var="node_desired_size=3"
```

## AWS Budget

A $20/month cost budget is created automatically with alerts at **80%** ($16) and **100%** ($20).  Notifications go to the email address in `terraform.tfvars` (change via `budget_email` variable).

## Destroy

```bash
terraform destroy
```

> **Warning:** This will delete the EKS cluster, node group, VPC, budget, and
> all associated resources.

## Files

| File | Purpose |
|------|---------|
| `providers.tf` | Terraform & AWS provider config |
| `variables.tf` | Input variables with defaults |
| `main.tf` | VPC + EKS module + node group |
| `budget.tf` | $20/month AWS cost budget (alerts at 80% & 100%) |
| `outputs.tf` | Cluster endpoint, security groups, kubectl setup |
