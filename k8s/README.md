# Kubernetes Deployment Guide

This directory contains Kubernetes manifests to deploy the microservices application.

## Files

- `namespace.yaml` - Creates the microservices namespace
- `deployment.yaml` - Deployment configuration for the app
- `service.yaml` - LoadBalancer service to expose the app
- `complete-deployment.yaml` - All-in-one deployment file

## Prerequisites

1. **EKS cluster is running** (provisioned via Terraform)
2. **kubectl configured** to connect to your cluster:
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name microservices-eks-cluster
   ```
3. **Docker image built and pushed** to a container registry (ECR, Docker Hub, etc.)

## Building and Pushing Docker Image

### Option 1: Using AWS ECR (Recommended for EKS)

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Create ECR repository
aws ecr create-repository --repository-name microservices-app --region us-east-1

# Build Docker image
cd ..
docker build -t microservices-app:latest .

# Tag the image
docker tag microservices-app:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/microservices-app:latest

# Push to ECR
docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/microservices-app:latest
```

### Option 2: Using Docker Hub

```bash
# Build Docker image
cd ..
docker build -t <your-dockerhub-username>/microservices-app:latest .

# Login to Docker Hub
docker login

# Push to Docker Hub
docker push <your-dockerhub-username>/microservices-app:latest
```

## Deployment Steps

### Step 1: Update the image in deployment files

Replace `<YOUR_DOCKER_IMAGE>:<TAG>` in the YAML files with your actual image:
- For ECR: `<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/microservices-app:latest`
- For Docker Hub: `<your-dockerhub-username>/microservices-app:latest`

### Step 2: Deploy using individual files

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Deploy the application
kubectl apply -f deployment.yaml

# Create the service
kubectl apply -f service.yaml
```

### Step 3: OR Deploy using the all-in-one file

```bash
kubectl apply -f complete-deployment.yaml
```

## Verify Deployment

```bash
# Check if namespace is created
kubectl get namespaces

# Check pods status
kubectl get pods -n microservices

# Check deployment
kubectl get deployments -n microservices

# Check service
kubectl get services -n microservices

# Get detailed pod information
kubectl describe pods -n microservices

# View logs
kubectl logs -n microservices -l app=microservices-app
```

## Access the Application

```bash
# Get the LoadBalancer external IP/DNS
kubectl get service microservices-app-service -n microservices

# Wait for EXTERNAL-IP to be assigned (may take a few minutes)
# Access your app at: http://<EXTERNAL-IP>
```

## Scaling

```bash
# Scale to 3 replicas
kubectl scale deployment microservices-app --replicas=3 -n microservices

# Verify scaling
kubectl get pods -n microservices
```

## Update Deployment

```bash
# After pushing a new image version
kubectl set image deployment/microservices-app microservices-app=<NEW_IMAGE>:<NEW_TAG> -n microservices

# Check rollout status
kubectl rollout status deployment/microservices-app -n microservices
```

## Troubleshooting

```bash
# Check pod logs
kubectl logs -n microservices <pod-name>

# Get pod details
kubectl describe pod -n microservices <pod-name>

# Check events
kubectl get events -n microservices --sort-by='.lastTimestamp'

# Access pod shell for debugging
kubectl exec -it -n microservices <pod-name> -- /bin/sh
```

## Clean Up

```bash
# Delete all resources
kubectl delete -f complete-deployment.yaml

# Or delete individually
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
kubectl delete -f namespace.yaml
```

## Resource Configuration

The deployment includes:
- **Replicas**: 2 pods for high availability
- **Resources**: 
  - Requests: 128Mi memory, 100m CPU
  - Limits: 256Mi memory, 200m CPU
- **Health Checks**:
  - Liveness probe: Checks if app is running
  - Readiness probe: Checks if app is ready to serve traffic
- **Service Type**: LoadBalancer (creates AWS ELB automatically)
