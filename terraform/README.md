# Terraform Multi-Environment Setup

This directory contains Infrastructure as Code for the WM AKS Platform across multiple environments using Terraform.

## Directory Structure

```
terraform/
├── shared/                      # Shared reusable modules
│   └── modules/
│       ├── network/            # Networking resources (VNet, Subnets)
│       ├── aks/                # Kubernetes cluster
│       ├── acr/                # Container registry
│       └── storage/            # Storage accounts
│
└── environments/               # Environment-specific configurations
    ├── dev/                    # Development environment
    ├── stg/                    # Staging environment
    ├── prd/                    # Production environment
    └── dr/                     # Disaster Recovery environment
```

## Environments Overview

### Development (dev)
- **Location**: Malaysia West
- **AKS Nodes**: 2 (Standard_B2s)
- **ACR**: Standard
- **Storage**: LRS (Local Redundancy)
- **Use Case**: Development and testing

### Staging (stg)
- **Location**: Malaysia West
- **AKS Nodes**: 3 (Standard_D2s_v3)
- **ACR**: Standard
- **Storage**: GRS (Geo Redundancy)
- **Use Case**: Pre-production validation

### Production (prd)
- **Location**: Malaysia West
- **AKS Nodes**: 5 (Standard_D4s_v3)
- **ACR**: Premium
- **Storage**: Premium with GRS
- **Use Case**: Production workloads

### Disaster Recovery (dr)
- **Location**: East Asia (different region)
- **AKS Nodes**: 5 (Standard_D4s_v3)
- **ACR**: Premium
- **Storage**: Premium with GZRS (Geo-Zone Redundancy)
- **Use Case**: Failover capability

## Prerequisites

- Terraform >= 1.0
- Azure CLI configured with appropriate credentials
- Azure subscription with necessary permissions

## Usage

### Initialize an Environment

```bash
cd environments/dev
terraform init
```

### Plan Changes

```bash
cd environments/dev
terraform plan
```

### Apply Configuration

```bash
cd environments/dev
terraform apply
```

### Destroy Environment

```bash
cd environments/dev
terraform destroy
```

## Environment Variables

Each environment has its own `terraform.tfvars` file with specific values. Key differences:

| Variable | Dev | Stg | Prd | DR |
|----------|-----|-----|-----|-----|
| environment | dev | stg | prd | dr |
| vnet_cidr | 10.10.0.0/16 | 10.20.0.0/16 | 10.30.0.0/16 | 10.40.0.0/16 |
| aks_node_count | 2 | 3 | 5 | 5 |
| aks_vm_size | B2s | D2s_v3 | D4s_v3 | D4s_v3 |
| location | malaysiawest | malaysiawest | malaysiawest | eastasia |

## Shared Modules

### Network Module
Creates:
- Resource Group
- Virtual Network
- Subnets (web, aks-system, aks-app, db)

### AKS Module
Creates:
- AKS Resource Group
- Kubernetes Cluster with system node pool

### ACR Module
Creates:
- Container Registry for storing Docker images

### Storage Module
Creates:
- Storage Account for application data

## State Management

Currently using local state (`terraform.tfstate`). For production:

1. **Migrate to Azure Storage Backend** (recommended for prd/dr):
   ```hcl
   terraform {
     backend "azurerm" {
       resource_group_name  = "rg-terraform-backend"
       storage_account_name = "tfstate"
       container_name       = "tfstate"
       key                  = "prod.tfstate"
     }
   }
   ```

2. **Use Azure Storage with separate containers per environment**

3. **Enable state locking with Azure Blob Storage**

## Best Practices

1. **Always plan before apply**
   ```bash
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

2. **Use workspaces for additional isolation** (optional)
   ```bash
   terraform workspace new staging
   terraform workspace select staging
   ```

3. **Review outputs after apply**
   ```bash
   terraform output
   ```

4. **Backup state files regularly**

5. **Use git for version control** (add `.gitignore`)
   ```
   *.tfstate*
   .terraform/
   *.log
   ```

## Outputs

Each environment produces outputs for integration:

- `resource_group_network`: Network resource group name
- `vnet_id`: Virtual network ID
- `aks_cluster_name`: Kubernetes cluster name
- `acr_login_server`: Container registry login endpoint
- `storage_account_name`: Storage account name

## Common Tasks

### Get Kubeconfig
```bash
cd environments/prod
az aks get-credentials --resource-group <rg-name> --name <cluster-name>
```

### Deploy to ACR
```bash
az acr login --name <acr-name>
docker tag myapp:latest <acr-name>.azurecr.io/myapp:latest
docker push <acr-name>.azurecr.io/myapp:latest
```

### Monitor Deployment
```bash
terraform apply -auto-approve
terraform output
az resource group list
```

## Troubleshooting

### Plan Empty
- Check if variables are properly set in `terraform.tfvars`
- Verify Azure credentials: `az account show`
- Check resource group doesn't already exist

### Permission Denied
- Ensure Azure credentials have appropriate permissions
- Use `az login` to authenticate

### State Lock
- If stuck: `terraform force-unlock <lock-id>`
- Check for incomplete operations

## Migration from Old Structure

If migrating from a single terraform directory:
1. Copy existing module code to `shared/modules/`
2. Update module references from `./modules/` to `../../shared/modules/`
3. Test with dev environment first
4. Validate outputs match expectations
5. Update CI/CD pipelines to target new structure

## Support

For issues or questions:
- Review Terraform documentation: https://www.terraform.io/docs
- Check Azure Terraform provider: https://registry.terraform.io/providers/hashicorp/azurerm
- Review module outputs and states: `terraform show`
