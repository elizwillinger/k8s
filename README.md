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

> **Note:** This creates an external AWS ELB that is **not** tracked by Terraform.
> When ready to destroy the cluster, see [`terraform/README.md`](terraform/README.md)
> for the correct destroy workflow (must delete the LoadBalancer service first).

## Step 6: Implement Configuration Management

### What was done
- Created `manifests/feature-toggle-config.yaml` — ConfigMap `feature-toggle-config` with `FEATURE_DARK_MODE=true`
- Updated `manifests/website.yaml` — added `FEATURE_DARK_MODE` env var via `configMapKeyRef` referencing the ConfigMap, updated image tag to `v2`
- Updated `app/index.php` — checks `$_ENV['FEATURE_DARK_MODE']`; when `true`, injects a dark mode CSS `<style>` block and adds `dark-mode` class to `<html>`
- Updated `app/Dockerfile` — added `FEATURE_DARK_MODE=false` as the default env var

### Deploy
```powershell
# Rebuild and push the updated image
 docker build -t ezwill/labrepo:v2 app/
docker push ezwill/labrepo:v2

# Apply ConfigMap + Deployment
kubectl apply -f manifests/
```

### Outcome
- Website renders in dark mode — dark backgrounds, light text, accent-colored links
- Demonstrates how ConfigMaps manage application features without code redeployment (toggle the ConfigMap value and restart pods to change behavior)

## Step 8: Perform a Rolling Update

### What was done
- Modified `app/index.php` to add a promotional banner for the marketing campaign
- Built and pushed the updated image as `ezwill/labrepo:v5` to Docker Hub
- Updated `manifests/website.yaml` with the new image tag (`v5`)
- Applied the update with `kubectl apply -f manifests/website.yaml`
- Monitored the rolling update with `kubectl rollout status deployment/website`

### Deploy
```powershell
# Build and push the updated image
docker build -t ezwill/labrepo:v5 app/
docker push ezwill/labrepo:v5

# Apply the rolling update
kubectl apply -f manifests/website.yaml

# Monitor rollout
kubectl rollout status deployment/website --watch
```

### Outcome
- The website updated with zero downtime — existing pods served traffic while new pods came up
- Demonstrates Kubernetes' rolling update strategy: gradual replacement of old pods with new ones

## Step 10: Autoscale Your Application

### What was done
- Installed metrics-server for Kubernetes metrics (`kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`)
- Created `manifests/05-hpa.yaml` — HorizontalPodAutoscaler targeting 50% CPU utilization, min 3 / max 10 replicas
- Verified autoscaling under load with `ab -n 10000 -c 200` against the LoadBalancer endpoint
- Observed HPA scaling from 3 → 10 pods and back down after load stopped (~5 min stabilization window)

### Deploy HPA
```powershell
kubectl apply -f manifests/05-hpa.yaml

# Verify
kubectl get hpa website -w
```

### Load test
```bash
# From WSL2 or any machine with ab installed
ab -n 10000 -c 200 http://<EXTERNAL-IP>/
```

### Notes
- HPA measures CPU utilization against each pod's **request** (100m), not the limit
- Scale-down uses a 5-minute stabilization window by default to prevent flapping
- The HPA formula: `desiredReplicas = ceil(currentReplicas × currentUtilization / targetUtilization)`
- metrics-server is installed imperatively for now; TODO: migrate to `aws_eks_addon` in Terraform
