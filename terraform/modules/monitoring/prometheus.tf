# AWS Managed Prometheus (AMP)
resource "aws_prometheus_workspace" "main" {
  alias = "${var.cluster_name}-prometheus"

  tags = {
    Name        = "${var.cluster_name}-prometheus"
    Environment = "dev"
  }
}

# IAM Role for Prometheus to scrape metrics from EKS
resource "aws_iam_role" "amp_ingest" {
  name = "${var.cluster_name}-amp-ingest-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:sub" = "system:serviceaccount:prometheus:amp-iamproxy-ingest-service-account"
            "${var.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-amp-ingest-role"
  }
}

resource "aws_iam_role_policy" "amp_ingest" {
  name = "${var.cluster_name}-amp-ingest-policy"
  role = aws_iam_role.amp_ingest.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:RemoteWrite",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ]
        Resource = aws_prometheus_workspace.main.arn
      }
    ]
  })
}

# IAM Role for Prometheus to query metrics
resource "aws_iam_role" "amp_query" {
  name = "${var.cluster_name}-amp-query-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:sub" = "system:serviceaccount:prometheus:amp-iamproxy-query-service-account"
            "${var.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.cluster_name}-amp-query-role"
  }
}

resource "aws_iam_role_policy" "amp_query" {
  name = "${var.cluster_name}-amp-query-policy"
  role = aws_iam_role.amp_query.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aps:QueryMetrics",
          "aps:GetSeries",
          "aps:GetLabels",
          "aps:GetMetricMetadata"
        ]
        Resource = aws_prometheus_workspace.main.arn
      }
    ]
  })
}
