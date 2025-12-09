# Monitoring Setup Guide

This guide covers setting up AWS Managed Prometheus and Grafana to monitor your Kubernetes cluster and microservices application.

## Architecture

- **AWS Managed Prometheus (AMP)**: Stores and queries metrics
- **AWS Managed Grafana**: Visualizes metrics from Prometheus
- **Prometheus Agent**: Runs in EKS cluster, scrapes metrics and sends to AMP
- **Application Metrics**: Flask app exposes metrics endpoint

## Prerequisites

1. EKS cluster is deployed via Terraform
2. kubectl configured to access the cluster
3. AWS CLI installed and configured

## Step 1: Deploy Monitoring Infrastructure with Terraform

The monitoring module is already included in the main Terraform configuration.

```bash
cd terraform

# Apply Terraform (monitoring module will be created)
terraform apply

# Get the outputs
terraform output prometheus_remote_write_url
terraform output grafana_workspace_url
terraform output amp_ingest_role_arn
```

Save these values - you'll need them for the next steps.

## Step 2: Enable OIDC Provider for EKS

```bash
# Get cluster name
export CLUSTER_NAME=microservices-eks-cluster

# Associate OIDC provider (if not already done)
eksctl utils associate-iam-oidc-provider \
  --cluster $CLUSTER_NAME \
  --region us-east-1 \
  --approve
```

## Step 3: Update Kubernetes Monitoring Manifests

Replace placeholders in the monitoring YAML files:

```bash
# Get Terraform outputs
export AMP_INGEST_ROLE_ARN=$(terraform output -raw amp_ingest_role_arn)
export AMP_REMOTE_WRITE_URL=$(terraform output -raw prometheus_remote_write_url)
export GRAFANA_URL=$(terraform output -raw grafana_workspace_url)

# Update the files
cd ../k8s/monitoring

# Update service account
sed -i '' "s|<AMP_INGEST_ROLE_ARN>|${AMP_INGEST_ROLE_ARN}|g" serviceaccount.yaml
sed -i '' "s|<AMP_INGEST_ROLE_ARN>|${AMP_INGEST_ROLE_ARN}|g" complete-monitoring.yaml

# Update Prometheus config
sed -i '' "s|<PROMETHEUS_REMOTE_WRITE_URL>|${AMP_REMOTE_WRITE_URL}|g" prometheus-config.yaml
sed -i '' "s|<PROMETHEUS_REMOTE_WRITE_URL>|${AMP_REMOTE_WRITE_URL}|g" complete-monitoring.yaml
```

## Step 4: Deploy Prometheus to Kubernetes

### Option A: Using complete file

```bash
kubectl apply -f complete-monitoring.yaml
```

### Option B: Using individual files

```bash
kubectl apply -f namespace.yaml
kubectl apply -f serviceaccount.yaml
kubectl apply -f prometheus-config.yaml
kubectl apply -f prometheus-deployment.yaml
```

## Step 5: Verify Prometheus Deployment

```bash
# Check if Prometheus pod is running
kubectl get pods -n prometheus

# Check logs
kubectl logs -n prometheus -l app=prometheus

# Port-forward to access Prometheus UI (optional)
kubectl port-forward -n prometheus svc/prometheus 9090:9090

# Visit http://localhost:9090 to see Prometheus UI
```

## Step 6: Add Metrics Endpoint to Flask App

Add prometheus_flask_exporter to your Flask application:

```bash
# Update requirements.txt
echo "prometheus-flask-exporter==0.23.0" >> requirements.txt
```

Update `app/main.py`:

```python
from flask import Flask
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
metrics = PrometheusMetrics(app)

# Your routes...
```

Rebuild and redeploy the Docker image:

```bash
# Trigger GitHub Actions or build manually
docker build -t <ECR_URL>:latest .
docker push <ECR_URL>:latest

# Restart deployment to pick up new image
kubectl rollout restart deployment/microservices-app -n microservices
```

## Step 7: Configure Grafana

### Access Grafana

```bash
# Get Grafana URL
echo $GRAFANA_URL
# or
terraform output grafana_workspace_url
```

Visit the URL in your browser. You'll need to sign in via AWS SSO.

### Add Prometheus Data Source

1. Go to Grafana workspace
2. Click **Configuration** → **Data sources**
3. Click **Add data source**
4. Select **Prometheus**
5. In **HTTP URL**, enter the AMP workspace query endpoint:
   ```
   https://aps-workspaces.<region>.amazonaws.com/workspaces/<workspace-id>
   ```
6. Under **Auth**, enable **SigV4 auth**
   - Default Region: `us-east-1`
   - Service: `aps`
7. Click **Save & Test**

### Import Dashboards

Import pre-built dashboards:

1. Click **+** → **Import**
2. Enter dashboard IDs:
   - **3119** - Kubernetes cluster monitoring
   - **6417** - Kubernetes Pods
   - **7249** - Kubernetes Cluster
   - **315** - Kubernetes cluster monitoring (Prometheus)

3. Or create custom dashboard:
   - Add panel
   - Use PromQL queries like:
     ```promql
     # Request rate
     rate(flask_http_request_total[5m])
     
     # Request duration
     flask_http_request_duration_seconds_sum / flask_http_request_duration_seconds_count
     
     # Pod CPU usage
     container_cpu_usage_seconds_total{namespace="microservices"}
     
     # Pod memory usage
     container_memory_usage_bytes{namespace="microservices"}
     ```

## Step 8: Verify Metrics Collection

Check if metrics are being scraped:

```bash
# Check Prometheus targets (port-forward first)
kubectl port-forward -n prometheus svc/prometheus 9090:9090

# Visit http://localhost:9090/targets
# You should see your microservices-app pods listed
```

Query metrics in Prometheus:

```promql
# Check if app metrics are available
up{job="microservices-app"}

# Request count
flask_http_request_total

# CPU usage by pod
container_cpu_usage_seconds_total{namespace="microservices"}
```

## Useful PromQL Queries

### Application Metrics

```promql
# Request rate per endpoint
rate(flask_http_request_total[5m])

# Average request duration
rate(flask_http_request_duration_seconds_sum[5m]) / rate(flask_http_request_duration_seconds_count[5m])

# Request error rate
rate(flask_http_request_total{status=~"5.."}[5m])
```

### Kubernetes Metrics

```promql
# Pod CPU usage
sum(rate(container_cpu_usage_seconds_total{namespace="microservices"}[5m])) by (pod)

# Pod memory usage
sum(container_memory_usage_bytes{namespace="microservices"}) by (pod)

# Pod restart count
kube_pod_container_status_restarts_total{namespace="microservices"}
```

## Cleanup

```bash
# Delete monitoring stack
kubectl delete -f k8s/monitoring/complete-monitoring.yaml

# Destroy Terraform monitoring resources
cd terraform
terraform destroy -target=module.monitoring
```

## Troubleshooting

### Prometheus not scraping metrics

```bash
# Check Prometheus logs
kubectl logs -n prometheus -l app=prometheus

# Check if service account has correct annotations
kubectl describe sa amp-iamproxy-ingest-service-account -n prometheus
```

### Metrics not appearing in Grafana

1. Verify Prometheus remote write is working (check Prometheus logs)
2. Ensure Grafana data source is configured with correct endpoint
3. Check IAM permissions for Grafana to query AMP

### High costs

AWS Managed Prometheus and Grafana can be expensive. For development:
- Delete monitoring stack when not in use
- Use smaller retention periods
- Consider self-hosted Prometheus/Grafana for development

## Cost Estimates

- **AWS Managed Prometheus**: ~$10-20/month (depends on ingestion rate)
- **AWS Managed Grafana**: ~$9/month per active user
- **Total**: ~$20-30/month for monitoring

