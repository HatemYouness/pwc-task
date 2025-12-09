# AWS Managed Grafana
resource "aws_grafana_workspace" "main" {
  name                     = "${var.cluster_name}-grafana"
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["AWS_SSO"]
  permission_type          = "SERVICE_MANAGED"
  data_sources             = ["PROMETHEUS"]

  tags = {
    Name        = "${var.cluster_name}-grafana"
    Environment = "dev"
  }
}

# IAM Role for Grafana to access Prometheus
resource "aws_iam_role" "grafana" {
  name = "${var.cluster_name}-grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "grafana.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-grafana-role"
  }
}

resource "aws_iam_role_policy" "grafana_prometheus" {
  name = "${var.cluster_name}-grafana-prometheus-policy"
  role = aws_iam_role.grafana.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:ListWorkspaces",
          "aps:DescribeWorkspace",
          "aps:QueryMetrics",
          "aps:GetLabels",
          "aps:GetSeries",
          "aps:GetMetricMetadata"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the role to Grafana workspace
resource "aws_grafana_role_association" "prometheus" {
  role         = "ADMIN"
  workspace_id = aws_grafana_workspace.main.id
  user_ids     = []
  group_ids    = []
}
