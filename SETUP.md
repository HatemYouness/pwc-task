# Setup Guide

This guide covers the complete setup for the microservices infrastructure and deployment pipeline.

## Prerequisites

1. AWS Account with appropriate permissions
2. GitHub repository
3. AWS CLI installed locally
4. Terraform installed locally (>= 1.0)
5. kubectl installed locally

## Step 1: Bootstrap Terraform Backend (One-time Setup)

Before deploying the infrastructure, you need to create the S3 bucket and DynamoDB table for Terraform state management.

```bash
# Navigate to bootstrap directory
cd terraform/bootstrap

# Initialize and apply
terraform init
terraform apply

# Note the outputs - you'll need these values
terraform output
```

This creates:
- S3 bucket: `microservices-terraform-state`
- DynamoDB table: `microservices-terraform-locks`

## Step 2: Configure GitHub Secrets

Add the following secrets to your GitHub repository (Settings → Secrets and variables → Actions):

### Required Secrets:
- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key
- `AWS_ACCOUNT_ID` - Your AWS account ID (12-digit number)

### How to get AWS credentials:
```bash
# Create IAM user with appropriate permissions or use existing credentials
aws configure list
```

## Step 3: Update Configuration Files

### Update Kubernetes Deployment Files

Replace `<AWS_ACCOUNT_ID>` in the following files with your actual AWS account ID:
- `k8s/deployment.yaml`
- `k8s/complete-deployment.yaml`

```bash
# You can use sed to replace it automatically
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
sed -i '' "s/<AWS_ACCOUNT_ID>/${AWS_ACCOUNT_ID}/g" k8s/deployment.yaml
sed -i '' "s/<AWS_ACCOUNT_ID>/${AWS_ACCOUNT_ID}/g" k8s/complete-deployment.yaml
```

## Step 4: Deploy Infrastructure with Terraform

### Option A: Using GitHub Actions (Recommended)

1. Push changes to the `main` branch:
```bash
git add .
git commit -m "Add Terraform and GitHub Actions configuration"
git push origin main
```

2. Go to GitHub Actions tab and monitor the `Terraform Deploy to AWS` workflow
3. The workflow will automatically plan and apply Terraform changes

### Option B: Manual Deployment

```bash
cd terraform

# Initialize Terraform with backend
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Save important outputs
terraform output > outputs.txt
```

## Step 5: Configure kubectl

After the EKS cluster is created, configure kubectl:

```bash
aws eks update-kubeconfig --region us-east-1 --name microservices-eks-cluster

# Verify connection
kubectl get nodes
```

## Step 6: Build and Push Docker Image

### Option A: Using GitHub Actions (Recommended)

Push code changes to trigger the Docker build:

```bash
git add .
git commit -m "Trigger Docker build"
git push origin main
```

The `Build and Push Docker Image to ECR` workflow will automatically:
- Build the Docker image
- Scan for vulnerabilities
- Push to ECR

### Option B: Manual Build and Push

```bash
# Get ECR login command
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Build image
docker build -t microservices-eks-cluster-app:latest .

# Tag image
docker tag microservices-eks-cluster-app:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/microservices-eks-cluster-app:latest

# Push to ECR
docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/microservices-eks-cluster-app:latest
```

## Step 7: Deploy to Kubernetes

```bash
# Apply all Kubernetes manifests
kubectl apply -f k8s/complete-deployment.yaml

# Check deployment status
kubectl get pods -n microservices
kubectl get services -n microservices

# Get LoadBalancer URL (may take a few minutes)
kubectl get service microservices-app-service -n microservices -o wide
```

## Step 8: Verify Deployment

```bash
# Check pod logs
kubectl logs -n microservices -l app=microservices-app

# Get service endpoint
export LB_URL=$(kubectl get service microservices-app-service -n microservices -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://${LB_URL}"

# Test the application
curl http://${LB_URL}
```

## GitHub Actions Workflows

### 1. Docker Build and Push (`docker-build-push.yml`)

**Triggers:**
- Push to `main` or `task` branch (when app code changes)
- Pull requests
- Manual trigger

**What it does:**
- Builds Docker image
- Scans for vulnerabilities
- Pushes to ECR with multiple tags (sha, latest)

### 2. Terraform Deploy (`terraform-deploy.yml`)

**Triggers:**
- Push to `main` branch (when Terraform code changes)
- Pull requests (plan only)
- Manual trigger

**What it does:**
- Runs `terraform fmt`, `validate`, and `plan`
- Posts plan results as PR comment
- Applies changes on merge to main (requires approval)

## Monitoring and Maintenance

### View Terraform State

```bash
cd terraform
terraform state list
terraform show
```

### Update Application

1. Make code changes
2. Push to GitHub
3. GitHub Actions will automatically build and push new image
4. Update Kubernetes deployment:
```bash
kubectl rollout restart deployment/microservices-app -n microservices
kubectl rollout status deployment/microservices-app -n microservices
```

### Scale Application

```bash
kubectl scale deployment microservices-app --replicas=3 -n microservices
```

## Cleanup

### Delete Kubernetes Resources

```bash
kubectl delete -f k8s/complete-deployment.yaml
```

### Destroy Terraform Infrastructure

```bash
cd terraform
terraform destroy
```

### Delete Bootstrap Resources (Optional)

```bash
cd terraform/bootstrap
terraform destroy
```

## Troubleshooting

### Terraform State Lock Issues

```bash
# List locks
aws dynamodb scan --table-name microservices-terraform-locks

# Force unlock (use carefully)
terraform force-unlock <LOCK_ID>
```

### ECR Authentication Issues

```bash
# Re-authenticate to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

### Pod Not Starting

```bash
kubectl describe pod -n microservices <pod-name>
kubectl logs -n microservices <pod-name>
```

## Cost Optimization

To minimize AWS costs during development:
1. Stop/start nodes when not in use
2. Use smaller instance types (already configured as t3.small)
3. Delete resources when not needed
4. Enable ECR lifecycle policies (already configured)

## Security Best Practices

1. ✅ ECR image scanning enabled
2. ✅ S3 bucket encryption enabled
3. ✅ Terraform state encryption enabled
4. ✅ Private subnets for worker nodes
5. ✅ Security groups properly configured
6. ⚠️ Consider using IAM roles for service accounts (IRSA) for pods
7. ⚠️ Rotate AWS credentials regularly
8. ⚠️ Enable AWS CloudTrail for audit logging
