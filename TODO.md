# TODO

## Infra: Add metrics-server as an EKS managed add-on

**Status:** Open — installed imperatively via `kubectl apply -f`.

**Why:** The current install (from the components.yaml manifest) is ephemeral. It will be lost on `terraform destroy` / `terraform apply` and isn't version-controlled in the repo. The EKS managed add-on survives cluster lifecycle operations and is managed by Terraform.

**What to do:**
1. Add `aws_eks_addon` resource in Terraform for metrics-server
2. Ensure the EKS cluster has the `AmazonEKSMetricsServerPolicy` IAM policy attached
3. Remove the imperative `kubectl apply -f` from any scripts or docs referencing metrics-server

**Example:**
```hcl
resource "aws_eks_addon" "metrics_server" {
  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "metrics-server"
  resolve_conflicts = "OVERWRITE"
}
```

## Infra: Migrate from `v1 Endpoints` to `discovery.k8s.io/v1 EndpointSlice`

**Status:** Open — `kubectl get endpoints` shows a deprecation warning.

**Why:** `v1 Endpoints` is deprecated in Kubernetes 1.33+ and will be removed in a future release. The replacement is `discovery.k8s.io/v1 EndpointSlice`, which scales better for large clusters.

**What to do:**
1. Update any scripts/docs that query `kubectl get endpoints` to use `kubectl get endpointslices` instead
2. Update any manifests or automation that creates Endpoints resources to use EndpointSlice resources
3. Verify all services still route traffic correctly after the migration

**Example:**
```powershell
# Old (deprecated)
kubectl get endpoints website-service

# New
kubectl get endpointslices -l kubernetes.io/service-name=website-service
```

**Note:** This is a read-only change for now — `kubectl get endpoints` still works but prints a warning. Plan to migrate before the resource is fully removed in a future EKS/K8s version.

## Security: Replace `create_node_security_group = false` with dedicated node SGs

**Status:** Open — using convenience flag for lab simplicity.

**Why:** `create_node_security_group = false` in `terraform/main.tf` means nodes only have the EKS cluster's primary security group, which is broad by design (allows all cluster-internal traffic). This sacrifices security for simplicity.

**What to do:**
1. Create a dedicated security group with minimal ingress/egress rules
2. Reference it explicitly in the node group via `security_groups = [...]`
3. Remove `create_node_security_group = false`

**Example:**
```hcl
resource "aws_security_group" "node_sg" {
  name        = "${var.project_name}-node-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP from ALB"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

eks_managed_node_groups = {
  default = {
    security_groups = [aws_security_group.node_sg.id]
    # ...
  }
}
```
