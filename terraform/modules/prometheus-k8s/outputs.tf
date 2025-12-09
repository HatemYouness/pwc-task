output "prometheus_service_account_ingest" {
  description = "Name of the Prometheus ingest service account"
  value       = kubernetes_service_account.amp_ingest.metadata[0].name
}

output "prometheus_service_account_query" {
  description = "Name of the Prometheus query service account"
  value       = kubernetes_service_account.amp_query.metadata[0].name
}

output "prometheus_namespace" {
  description = "Namespace where Prometheus is deployed"
  value       = var.prometheus_namespace
}
