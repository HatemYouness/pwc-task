# Monitoring Module Outputs

output "prometheus_workspace_id" {
  description = "ID of the AWS Managed Prometheus workspace"
  value       = module.monitoring.prometheus_workspace_id
}

output "prometheus_workspace_endpoint" {
  description = "Endpoint URL for the AWS Managed Prometheus workspace"
  value       = module.monitoring.prometheus_workspace_endpoint
}

output "prometheus_remote_write_url" {
  description = "Remote write URL for Prometheus"
  value       = module.monitoring.prometheus_remote_write_url
}

output "grafana_workspace_id" {
  description = "ID of the AWS Managed Grafana workspace"
  value       = module.monitoring.grafana_workspace_id
}

output "grafana_workspace_endpoint" {
  description = "Endpoint URL for accessing Grafana"
  value       = module.monitoring.grafana_workspace_endpoint
}

output "amp_ingest_role_arn" {
  description = "ARN of IAM role for Prometheus ingestion"
  value       = module.monitoring.amp_ingest_role_arn
}

output "amp_query_role_arn" {
  description = "ARN of IAM role for Prometheus queries"
  value       = module.monitoring.amp_query_role_arn
}

output "prometheus_namespace" {
  description = "Namespace where Prometheus resources are deployed"
  value       = module.prometheus_k8s.prometheus_namespace
}

output "prometheus_service_account_ingest" {
  description = "Service account for Prometheus metrics ingestion"
  value       = module.prometheus_k8s.prometheus_service_account_ingest
}

output "prometheus_service_account_query" {
  description = "Service account for Prometheus queries"
  value       = module.prometheus_k8s.prometheus_service_account_query
}
