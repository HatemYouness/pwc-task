# Terraform Backend Configuration
# This configures S3 for state storage and DynamoDB for state locking

terraform {
  backend "s3" {
    bucket         = "microservices-terraform-state"
    key            = "eks-cluster/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "microservices-terraform-locks"
    encrypt        = true
  }
}
