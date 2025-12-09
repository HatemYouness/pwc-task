output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.eks_node_group.arn
}

output "cluster_policy_attachment" {
  description = "EKS cluster policy attachment"
  value       = aws_iam_role_policy_attachment.eks_cluster_policy.id
}

output "vpc_resource_controller_attachment" {
  description = "VPC resource controller policy attachment"
  value       = aws_iam_role_policy_attachment.eks_vpc_resource_controller.id
}

output "worker_node_policy_attachment" {
  description = "Worker node policy attachment"
  value       = aws_iam_role_policy_attachment.eks_worker_node_policy.id
}

output "cni_policy_attachment" {
  description = "CNI policy attachment"
  value       = aws_iam_role_policy_attachment.eks_cni_policy.id
}

output "container_registry_policy_attachment" {
  description = "Container registry policy attachment"
  value       = aws_iam_role_policy_attachment.eks_container_registry_policy.id
}
