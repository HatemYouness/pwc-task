variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "prometheus_namespace" {
  description = "Kubernetes namespace for Prometheus"
  type        = string
}

variable "amp_ingest_role_arn" {
  description = "ARN of the IAM role for AMP ingestion"
  type        = string
}

variable "amp_query_role_arn" {
  description = "ARN of the IAM role for AMP queries"
  type        = string
}

variable "prometheus_remote_write_url" {
  description = "Remote write URL for AWS Managed Prometheus"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}
