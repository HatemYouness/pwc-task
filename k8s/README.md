# Kubernetes Deployment Guide

This directory contains Kubernetes manifests to deploy the microservices application and Prometheus monitoring.

## Files

### Application Deployment

**`complete-deployment.yaml`**
- Complete deployment configuration for the microservices application
- Includes:
  - Deployment with 2 replicas
  - LoadBalancer Service (Network Load Balancer)
  - Health probes (liveness and readiness)
  - Resource limits and requests
  - Prometheus scrape annotations
- **Note**: Namespace `microservices` is managed by Terraform

### Monitoring Stack

**`prometheus-deployment.yaml`**
- Complete Prometheus deployment for AWS Managed Prometheus integration
- Includes:
  - ConfigMap with comprehensive scrape configurations
  - Deployment with proper security context
  - Service (ClusterIP)
  - Health probes and resource limits
  - IRSA (IAM Roles for Service Accounts) integration
- **Note**: Namespace `prometheus` and ServiceAccounts are managed by Terraform

## Prerequisites

1. **Terraform infrastructure deployed** (VPC, EKS cluster, monitoring stack)
2. **kubectl configured** to connect to your cluster:
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name microservices-eks-cluster
   ```
3. **Docker image built and pushed** to ECR (via GitHub Actions or manually)

## Building and Pushing Docker Image

### Option 1: Using AWS ECR (Recommended for EKS)

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Create ECR repository
aws ecr create-repository --repository-name microservices-app --region us-east-1

## Deployment Order

### 1. Deploy Infrastructure (Terraform)
```bash
# Create S3 backend and DynamoDB table
cd terraform/bootstrap
terraform init && terraform apply

# Deploy all infrastructure
cd ..
terraform init && terraform apply
```

This creates:
- VPC and networking (single AZ, NAT gateway)
- EKS cluster (1.28) with 1 t3.small node
- ECR repository for Docker images
- AWS Managed Prometheus workspace
- AWS Managed Grafana workspace
- Kubernetes namespaces: `microservices`, `prometheus`
- ServiceAccounts with IAM roles for Prometheus (IRSA)

### 2. Configure kubectl
```bash
aws eks update-kubeconfig --name microservices-eks-cluster --region us-east-1
```

### 3. Build and Push Docker Image

**Using GitHub Actions (Recommended):**
- Push code to GitHub
- Workflow automatically builds and pushes to ECR on main branch

**Manual Build:**
```bash
# Login to ECR
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build and tag
cd ..
docker build -t microservices-eks-cluster-app:latest .
docker tag microservices-eks-cluster-app:latest $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/microservices-eks-cluster-app:latest

# Push to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/microservices-eks-cluster-app:latest
```

### 4. Update Image Reference

Update the image in `complete-deployment.yaml`:
```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
sed -i.bak "s/<AWS_ACCOUNT_ID>/$AWS_ACCOUNT_ID/g" k8s/complete-deployment.yaml
```

### 5. Deploy Prometheus

```bash
# Deploy Prometheus resources
kubectl apply -f k8s/prometheus-deployment.yaml

# Get remote write URL from Terraform
cd terraform
REMOTE_WRITE_URL=$(terraform output -raw prometheus_remote_write_url)
cd ..

# Update ConfigMap with actual remote write URL
kubectl patch deployment prometheus -n prometheus \
  -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"prometheus\",\"env\":[{\"name\":\"PROMETHEUS_REMOTE_WRITE_URL\",\"value\":\"$REMOTE_WRITE_URL\"}]}]}}}}"

# Or manually edit the ConfigMap and replace ${PROMETHEUS_REMOTE_WRITE_URL}
kubectl edit configmap prometheus-config -n prometheus
# Then restart: kubectl rollout restart deployment/prometheus -n prometheus
```

### 6. Deploy Application
```bash
kubectl apply -f k8s/complete-deployment.yaml
```

## Verify Deployment

### Check Application
```bash
# Check pods status
kubectl get pods -n microservices
kubectl get deployment -n microservices
kubectl get svc -n microservices

# View logs
kubectl logs -n microservices -l app=microservices-app -f

# Get detailed pod information
kubectl describe pods -n microservices
```

### Check Prometheus
```bash
# Check Prometheus resources
kubectl get pods -n prometheus
kubectl get svc -n prometheus
kubectl get configmap -n prometheus

# View Prometheus logs
kubectl logs -n prometheus deployment/prometheus -f

# Verify ServiceAccount annotations
kubectl get sa -n prometheus amp-iamproxy-ingest-service-account -o yaml
```


## Access the Services

### Application
```bash
# Get the Network Load Balancer DNS
APP_URL=$(kubectl get svc microservices-app-service -n microservices -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application: http://$APP_URL"

# Test endpoints
curl http://$APP_URL/
curl http://$APP_URL/users
curl http://$APP_URL/products
curl http://$APP_URL/metrics  # Prometheus metrics
```

### Prometheus (Internal Only)
```bash
# Port forward to access Prometheus UI locally
kubectl port-forward -n prometheus svc/prometheus 9090:9090

# Access at http://localhost:9090
# Check targets at http://localhost:9090/targets
# Check config at http://localhost:9090/config
```

### Grafana
```bash
# Get Grafana workspace URL from Terraform
cd terraform
terraform output grafana_workspace_endpoint

# Access via AWS Console with SSO
# Configure Prometheus data source in Grafana using AMP endpoint
```

## Monitoring Configuration

### Application Metrics

The application is configured to expose metrics at `/metrics` endpoint. Prometheus automatically discovers and scrapes pods with these annotations:

```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "5000"
  prometheus.io/path: "/metrics"
```

### Adding Flask Metrics

To expose detailed metrics from your Flask application:

1. Install the Prometheus client:
```bash
pip install prometheus-flask-exporter
```

2. Add to your Flask app:
```python
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
metrics = PrometheusMetrics(app)
```

3. Rebuild and redeploy your Docker image

## Scaling

```bash
# Scale application to 3 replicas
kubectl scale deployment microservices-app --replicas=3 -n microservices

# Verify scaling
kubectl get pods -n microservices -w
```

## Update Deployment

### Via GitHub Actions (Recommended)
Push changes to main branch and the workflow will automatically:
1. Build new Docker image
2. Push to ECR
3. Update deployment (if configured)

### Manual Update
```bash
# After pushing a new image version
kubectl rollout restart deployment/microservices-app -n microservices

# Check rollout status
kubectl rollout status deployment/microservices-app -n microservices

# View rollout history
kubectl rollout history deployment/microservices-app -n microservices
```

## Troubleshooting

### Application Issues
```bash
# Check pod logs
kubectl logs -n microservices deployment/microservices-app --tail=100 -f

# Get pod details
kubectl describe pod -n microservices -l app=microservices-app

# Check events
kubectl get events -n microservices --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n microservices

# Access pod shell for debugging
kubectl exec -it -n microservices deployment/microservices-app -- /bin/sh
```

### Prometheus Issues
```bash
# Check if Prometheus is scraping targets
kubectl port-forward -n prometheus svc/prometheus 9090:9090
# Visit http://localhost:9090/targets

# Check Prometheus logs
kubectl logs -n prometheus deployment/prometheus --tail=100

# Verify ConfigMap
kubectl get configmap prometheus-config -n prometheus -o yaml

# Check if remote write is working (look for errors in logs)
kubectl logs -n prometheus deployment/prometheus | grep remote_write

# Verify IAM role is attached to ServiceAccount
kubectl describe sa amp-iamproxy-ingest-service-account -n prometheus
```

### Network Load Balancer Issues
```bash
# Check service
kubectl describe svc microservices-app-service -n microservices

# Verify NLB was created
aws elbv2 describe-load-balancers --region us-east-1 | grep microservices

# Check target group health (get ARN from AWS console)
aws elbv2 describe-target-health --target-group-arn <ARN>
```

## Clean Up

```bash
# Delete application
kubectl delete -f k8s/complete-deployment.yaml

# Delete Prometheus
kubectl delete -f k8s/prometheus-deployment.yaml

# Delete infrastructure (Terraform)
cd terraform
terraform destroy -auto-approve
```
