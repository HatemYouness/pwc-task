# Kubernetes ServiceAccounts for Prometheus with IAM roles (IRSA)
resource "kubernetes_service_account" "amp_ingest" {
  metadata {
    name      = "amp-iamproxy-ingest-service-account"
    namespace = var.prometheus_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = var.amp_ingest_role_arn
    }
    labels = {
      app       = "prometheus"
      component = "monitoring"
    }
  }
}

resource "kubernetes_service_account" "amp_query" {
  metadata {
    name      = "amp-iamproxy-query-service-account"
    namespace = var.prometheus_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = var.amp_query_role_arn
    }
    labels = {
      app       = "prometheus"
      component = "monitoring"
    }
  }
}
