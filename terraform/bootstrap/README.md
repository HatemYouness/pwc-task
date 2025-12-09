# Terraform Bootstrap Directory

This directory contains Terraform configuration to create the backend infrastructure (S3 bucket and DynamoDB table) required for remote state management.

## What This Creates

- **S3 Bucket**: `microservices-terraform-state` - Stores Terraform state files
  - Versioning enabled
  - Encryption enabled (AES256)
  - Public access blocked
  
- **DynamoDB Table**: `microservices-terraform-locks` - Handles state locking
  - Pay-per-request billing
  - Single hash key: `LockID`

## How to Use

### One-Time Setup (Before Main Terraform)

```bash
# Navigate to this directory
cd terraform/bootstrap

# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Create the resources
terraform apply

# Note the outputs
terraform output
```

### Important Notes

1. **Run this FIRST** before running the main Terraform configuration
2. These resources should **NOT be deleted** while using Terraform for your infrastructure
3. The state for this bootstrap is stored **locally** (not in S3)
4. Keep the local state file (`terraform.tfstate`) safe or commit it to version control

### After Bootstrap

Once these resources are created, the main Terraform configuration (in `../`) will use them automatically via the `backend.tf` file.

## Cleanup

Only destroy these resources when you're completely done with the project and have already destroyed all infrastructure managed by the main Terraform configuration:

```bash
cd terraform/bootstrap
terraform destroy
```

⚠️ **Warning**: Destroying these resources will make your main Terraform state inaccessible!
