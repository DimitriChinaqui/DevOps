# Azure Terraform Deployment

## Overview

This project uses Terraform to deploy a scalable web application infrastructure on Azure. The infrastructure includes:
- A Virtual Network (VNet) with subnets for web, application, and database tiers.
- Two Virtual Machines (VMs) in the web tier with a Load Balancer.
- A VM in the application tier.
- An Azure SQL Database in the database tier.
- A Network Security Group (NSG) with appropriate rules for each tier.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed on your local machine.
- An Azure account with sufficient permissions to create resources.
- Azure CLI installed and authenticated.

## Deployment

1. Clone the repository:
    
    git clone https://github.com/your-repo/azure-terraform-deployment.git
    cd DevOps

2. Set the admin passwords on variables.tf file


2. Initialize Terraform:
    terraform init
   
3. Apply the Terraform scripts to deploy the infrastructure:
    
    terraform apply
    

4. Confirm the deployment when prompted.

## Outputs

The deployment will output:
- The public IP address of the web tier Load Balancer.
- The fully qualified domain name (FQDN) of the Azure SQL Server.

## Cost Estimation

The estimated cost for the deployed infrastructure is approximately $273/month.

## Cleanup

To remove the deployed infrastructure, run:

terraform destroy
