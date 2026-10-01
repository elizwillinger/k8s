# TODO

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
