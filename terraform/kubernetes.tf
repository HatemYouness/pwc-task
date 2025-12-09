# Kubernetes provider configuration
data "aws_eks_cluster" "main" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "main" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

# Microservices namespace
resource "kubernetes_namespace" "microservices" {
  metadata {
    name = "microservices"
    labels = {
      name        = "microservices"
      environment = "dev"
    }
  }
}

# Prometheus namespace
resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
    labels = {
      name        = "prometheus"
      environment = "dev"
    }
  }
}
