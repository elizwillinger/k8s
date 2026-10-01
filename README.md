# Lab Progress

## Step 2A: Dockerfile & Image

### What was done
- Created `Dockerfile` for the e-commerce web application
- Base image: `php:8.4-apache`
- Installed `mysqli` PHP extension via `docker-php-ext-install`
- Set default database connection env vars (`DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`) pointing to `mysql-service`
- Copied application source to `/var/www/html/`
- Exposed port 80


### Build & Push
```powershell
docker buildx build -t ezwill/labrepo:v1 .
docker push ezwill/labrepo:v1
```

### Notes
- `index.php` already reads DB credentials from environment variables — no code changes needed
- `mysql-service` is a Kubernetes service name; won't resolve in standalone Docker (expected for K8s deployment)

## Step 3: EKS Cluster (Terraform)

### What was done
- Provisioned an EKS cluster in `us-east-2` using the `terraform-aws-modules/eks/aws` v20 module
- Created a supporting VPC with public/private subnets and a NAT gateway
- Configured an EKS managed node group (AL2023 AMI, `t3.medium`, min 1 / max 4 / desired 2 nodes)
- Set `kubelet_extra_args = "--max-pods=10"` for the node group
- Enabled CloudWatch logging for all 5 cluster log types
- Enabled IRSA for workload identity
- Set a $20/month AWS cost budget with email alerts
- Cluster name: `k8slab-eks-cluster`

### Terraform workflow (run from `terraform/`)
```powershell
cd C:\Users\Eli\Documents\k8s\terraform

# Set AWS profile (system-level, persists across sessions)
[System.Environment]::SetEnvironmentVariable("AWS_PROFILE", "terraform-process", "User")

# Preview changes
terraform plan

# Apply
terraform apply

# Destroy (clean up all resources)
terraform destroy
```

### kubectl workflow
```powershell
# Refresh kubeconfig after every terraform apply/destroy
cmd /c "aws eks update-kubeconfig --name k8slab-eks-cluster --region us-east-2"

# Verify connection
kubectl cluster-info

# Quick sanity check
kubectl get nodes
kubectl get pods -A
```

### Notes
- `credential_process` in `~/.aws/config` uses SSO; the `terraform-process` profile must have `region = us-east-2` set
- The `enable_cluster_creator_admin_permissions = true` flag is required in the EKS module to grant the Terraform runner admin access to the cluster
- AL2023 nodes use **containerd** as the CRI (not Docker)
- Cluster version: 1.36

## Step 4: Deploy Website to Kubernetes

### What was done
- Created `manifests/website.yaml` — Deployment (`website`) running `ezwill/labrepo:v1` with DB connection env vars (`DB_HOST=mysql-service`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`)
- Created `manifests/mysql.yaml` — ConfigMap + MySQL Deployment
- Created `manifests/mysql-service.yaml` — MySQL ClusterIP Service
- Reorganized all manifests into intuitive filenames (removed old numbered files)

### Deploy
```powershell
# Deploy everything at once (DB + website)
kubectl apply -f manifests/

# Verify pods are running
kubectl get pods
kubectl get deployments
```

### Notes
- `ErrImagePull` was caused by Docker Hub private repo — fixed by making `ezwill/labrepo` public
- EKS managed node group update (adding `create_node_security_group = false`) took ~16 min
- See `TODO.md` for the security improvement (dedicated node SGs)

## Step 5: Expose Your Website

### What was done
- Created `manifests/website-service.yaml` — LoadBalancer Service exposing the website externally

### Deploy
```powershell
kubectl apply -f manifests/website-service.yaml

# Wait for the LoadBalancer to provision (2-5 min)
kubectl get svc website-service -w
```

### Outcome
- Website accessible at: `http://a00408d7df4b445b9a42bd3e359b89e5-2042941864.us-east-2.elb.amazonaws.com`
- HTTP 200 confirmed — full page renders with products from the database
