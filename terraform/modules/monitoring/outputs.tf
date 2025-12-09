output "prometheus_workspace_id" {
  description = "ID of the Prometheus workspace"
  value       = aws_prometheus_workspace.main.id
}

output "prometheus_workspace_endpoint" {
  description = "Endpoint of the Prometheus workspace"
  value       = aws_prometheus_workspace.main.prometheus_endpoint
}

output "prometheus_remote_write_url" {
  description = "Remote write URL for Prometheus"
  value       = "${aws_prometheus_workspace.main.prometheus_endpoint}api/v1/remote_write"
}

output "prometheus_query_url" {
  description = "Query URL for Prometheus"
  value       = "${aws_prometheus_workspace.main.prometheus_endpoint}api/v1/query"
}

output "grafana_workspace_id" {
  description = "ID of the Grafana workspace"
  value       = aws_grafana_workspace.main.id
}

output "grafana_endpoint" {
  description = "Endpoint URL for Grafana"
  value       = aws_grafana_workspace.main.endpoint
}

output "amp_ingest_role_arn" {
  description = "ARN of the IAM role for Prometheus ingestion"
  value       = aws_iam_role.amp_ingest.arn
}

output "amp_query_role_arn" {
  description = "ARN of the IAM role for Prometheus queries"
  value       = aws_iam_role.amp_query.arn
}
