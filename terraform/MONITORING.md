# Monitoring Infrastructure

This directory contains all monitoring-related resources organized into two modules:

## 1. AWS Managed Services (`modules/monitoring/`)

**Purpose**: Provisions AWS-managed monitoring infrastructure

**Resources**:
- AWS Managed Prometheus (AMP) workspace
- AWS Managed Grafana workspace
- IAM roles with IRSA (IAM Roles for Service Accounts) for:
  - Prometheus metrics ingestion to AMP
  - Prometheus queries from AMP
  - Grafana access to AMP

**Outputs**:
- Prometheus workspace ID and endpoints
- Grafana workspace ID and endpoint
- IAM role ARNs for service accounts

## 2. Prometheus Kubernetes Deployment (`modules/prometheus-k8s/`)

**Purpose**: Deploys Prometheus agent to EKS cluster

**Resources**:
- Kubernetes ServiceAccounts with IAM role annotations
- Prometheus ConfigMap with remote_write configuration
- Prometheus Deployment (1 replica)
- Prometheus Service (ClusterIP)

**Configuration**:
- Scrapes metrics from pods with `prometheus.io/scrape: "true"` annotation
- Remote writes metrics to AWS Managed Prometheus
- Uses IRSA for authentication to AWS services

## Architecture Flow

```
┌─────────────────────┐
│   EKS Cluster       │
│                     │
│  ┌──────────────┐   │      ┌──────────────────────┐
│  │ Prometheus   │───┼─────>│ AWS Managed          │
│  │ Agent        │   │      │ Prometheus (AMP)     │
│  └──────────────┘   │      └──────────────────────┘
│         │           │                 │
│         v           │                 v
│  ┌──────────────┐   │      ┌──────────────────────┐
│  │ App Pods     │   │      │ AWS Managed          │
│  │ (/metrics)   │   │      │ Grafana              │
│  └──────────────┘   │      └──────────────────────┘
└─────────────────────┘
```

## Deployment Order

1. **AWS Resources** (`modules/monitoring/`)
   - Created first via Terraform
   - Provides IAM roles and workspace endpoints

2. **Kubernetes Resources** (`modules/prometheus-k8s/`)
   - Deployed after EKS cluster is ready
   - Uses IAM role ARNs from monitoring module
   - Requires prometheus namespace to exist

## Cost Considerations

- **AMP**: ~$10-15/month for metrics ingestion and storage
- **Grafana**: ~$10/month for workspace
- **Prometheus Pod**: Minimal (runs on existing EKS nodes)

**Total**: ~$20-30/month for monitoring stack

## Access

- **Prometheus**: Internal only (ClusterIP service on port 9090)
- **Grafana**: External via AWS Console
  - Requires AWS SSO configuration
  - URL available in Terraform outputs

## Monitored Applications

Applications expose metrics by adding these annotations to pod specs:

```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "5000"
  prometheus.io/path: "/metrics"
```

See `k8s/complete-deployment.yaml` for example configuration.
