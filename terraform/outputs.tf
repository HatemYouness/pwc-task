# Output the cluster endpoint
output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

# Output the cluster name
output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

# Output region
output "region" {
  description = "AWS region"
  value       = var.aws_region
}

# Output ECR repository URL
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.microservices_app.repository_url
}

# Output ECR repository name
output "ecr_repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.microservices_app.name
}

# Output configure kubectl command
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# Monitoring outputs
output "prometheus_workspace_endpoint" {
  description = "AWS Managed Prometheus workspace endpoint"
  value       = module.monitoring.prometheus_workspace_endpoint
}

output "prometheus_remote_write_url" {
  description = "Prometheus remote write URL"
  value       = module.monitoring.prometheus_remote_write_url
}

output "grafana_workspace_url" {
  description = "AWS Managed Grafana workspace URL"
  value       = "https://${module.monitoring.grafana_endpoint}"
}

output "amp_ingest_role_arn" {
  description = "IAM role ARN for Prometheus ingestion"
  value       = module.monitoring.amp_ingest_role_arn
}

# Namespace outputs
output "microservices_namespace" {
  description = "Microservices namespace name"
  value       = kubernetes_namespace.microservices.metadata[0].name
}

output "prometheus_namespace" {
  description = "Prometheus namespace name"
  value       = kubernetes_namespace.prometheus.metadata[0].name
}
