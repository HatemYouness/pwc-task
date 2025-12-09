# Terraform EKS Cluster Deployment

This directory contains Terraform configuration to provision an AWS EKS (Elastic Kubernetes Service) cluster.

## Prerequisites

1. **AWS CLI** installed and configured with credentials
2. **Terraform** >= 1.0 installed
3. **kubectl** installed for cluster management

## Configuration Files

- `provider.tf` - AWS provider configuration
- `variables.tf` - Input variables for cluster configuration
- `vpc.tf` - VPC, subnets, NAT gateways, and routing
- `iam.tf` - IAM roles and policies for EKS cluster and nodes
- `main.tf` - EKS cluster and node group resources
- `outputs.tf` - Output values after deployment

## Architecture

This is a **simplified configuration for task/demo purposes**:
- **VPC** with CIDR 10.0.0.0/16
- **1 Public Subnet** in single availability zone
- **1 Private Subnet** in single availability zone
- **Internet Gateway** for public subnet traffic
- **1 NAT Gateway** for private subnet outbound traffic
- **EKS Cluster** with version 1.28
- **Node Group** with 1 t3.small instance (scalable 1-2)

## Deployment Steps

### 1. Initialize Terraform
```bash
cd terraform
terraform init
```

### 2. Review the configuration (optional)
```bash
terraform plan
```

### 3. Apply the configuration
```bash
terraform apply
```
Type `yes` when prompted to confirm.

### 4. Configure kubectl
After successful deployment, configure kubectl to interact with your cluster:
```bash
aws eks update-kubeconfig --region us-east-1 --name microservices-eks-cluster
```

### 5. Verify cluster access
```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

## Customization

You can customize the deployment by modifying `variables.tf` or creating a `terraform.tfvars` file:

```hcl
aws_region              = "us-west-2"
cluster_name            = "my-cluster"
cluster_version         = "1.28"
node_group_desired_size = 1
node_instance_types     = ["t3.small"]
```

## Outputs

After deployment, Terraform will output:
- Cluster endpoint
- Cluster name and ARN
- VPC and subnet IDs
- kubectl configuration command

View outputs anytime:
```bash
terraform output
```

## Clean Up

To destroy all resources:
```bash
terraform destroy
```
Type `yes` when prompted to confirm.

## Estimated Costs

This is a **cost-optimized configuration for tasks/demos**:
- **EKS Cluster**: ~$73/month
- **EC2 Instance** (1x t3.small): ~$15/month
- **NAT Gateway** (1): ~$32/month
- **Total**: ~$120/month

**Note**: This is a minimal setup. For production, use multiple AZs and larger instances.
