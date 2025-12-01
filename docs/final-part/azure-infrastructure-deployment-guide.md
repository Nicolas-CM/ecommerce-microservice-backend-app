[🏠 Volver al README](../../README.md#guía-de-despliegue-en-azure)

# Azure Infrastructure Deployment Guide - DEV Environment

## Prerequisites

### 1. Azure Resources
- Azure subscription (ID: `079ab1f2-9528-44da-ba22-d60a88fdb0b8`)
- Azure tenant (ID: `e994072b-523e-4bfe-86e2-442c5e10b244`)
- Service Principal with Contributor role

### 2. Tools Required
- Terraform >= 1.7.0
- Azure CLI >= 2.50.0
- kubectl >= 1.28

### 3. Create Service Principal
```bash
# Login to Azure
az login --tenant e994072b-523e-4bfe-86e2-442c5e10b244

# Create service principal
az ad sp create-for-rbac \
  --name "terraform-ecommerce-dev" \
  --role Contributor \
  --scopes /subscriptions/079ab1f2-9528-44da-ba22-d60a88fdb0b8 \
  --sdk-auth

# Save the output - you'll need it for GitHub secrets and local deployment
```

### 4. Create Terraform State Storage
```bash
# Variables
RESOURCE_GROUP="terraform-state-rg"
STORAGE_ACCOUNT="tfstateeco$(openssl rand -hex 4)"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT \
  --auth-mode login

# Update backend.hcl with the storage account name
echo "Storage Account: $STORAGE_ACCOUNT"
```

## Local Deployment

### Step 1: Configure Backend
Update `backend.hcl` with your storage account details:
```hcl
resource_group_name  = "terraform-state-rg"
storage_account_name = "tfstateeco<your-unique-id>"
container_name       = "tfstate"
key                  = "dev.tfstate"
```

### Step 2: Set Azure Credentials
```bash
# Windows (PowerShell)
$env:ARM_CLIENT_ID="<service-principal-client-id>"
$env:ARM_CLIENT_SECRET="<service-principal-client-secret>"
$env:ARM_SUBSCRIPTION_ID="079ab1f2-9528-44da-ba22-d60a88fdb0b8"
$env:ARM_TENANT_ID="e994072b-523e-4bfe-86e2-442c5e10b244"

# Linux/Mac (Bash)
export ARM_CLIENT_ID="<service-principal-client-id>"
export ARM_CLIENT_SECRET="<service-principal-client-secret>"
export ARM_SUBSCRIPTION_ID="079ab1f2-9528-44da-ba22-d60a88fdb0b8"
export ARM_TENANT_ID="e994072b-523e-4bfe-86e2-442c5e10b244"
```

### Step 3: Initialize and Deploy
```bash
cd infra/terraform/environments/dev

# Initialize Terraform
terraform init -backend-config=backend.hcl

# Validate configuration
terraform validate

# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

### Step 4: Connect to AKS
```bash
# Get AKS credentials
az aks get-credentials \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw aks_cluster_name) \
  --overwrite-existing

# Verify connection
kubectl cluster-info
kubectl get nodes
```

## GitHub Actions Deployment

### Step 1: Configure GitHub Secrets (Global)
Go to Settings > Secrets and variables > Actions > **New repository secret**.
These secrets apply to ALL environments:

- `AZURE_CLIENT_ID`: Service principal client ID
- `AZURE_CLIENT_SECRET`: Service principal client secret
- `AZURE_SUBSCRIPTION_ID`: `079ab1f2-9528-44da-ba22-d60a88fdb0b8`
- `AZURE_TENANT_ID`: `e994072b-523e-4bfe-86e2-442c5e10b244`

### Step 2: Configure GitHub Environments
1. Go to Settings > Environments
2. Create a new environment named `dev`

### Step 3: Configure Environment Secrets (DEV)
Inside the `dev` environment settings, add **Environment secrets**:

- `TF_BACKEND_RG`: `terraform-state-rg`
- `TF_BACKEND_SA`: Your DEV storage account (e.g., `tfstateecodev1234`)
- `TF_BACKEND_CONTAINER`: `tfstate`

### Step 4: Trigger Deployment
The workflow `.github/workflows/infra-dev-terraform.yml` will trigger on:
- Push to `dev` branch
- Pull requests to `dev` branch

```bash
# Commit and push changes
git add .
git commit -m "feat: configure Azure AKS infrastructure for DEV environment"
git push origin main
```

## Infrastructure Overview

### Created Resources
The Terraform configuration creates the following Azure resources:

1. **Resource Group**: `eco-dev-rg`
   - Location: East US
   - Contains all dev environment resources

2. **Virtual Network**: `eco-dev-vnet`
   - Address space: `10.20.0.0/16`
   - Subnets:
     - Container Apps: `10.20.1.0/24`
     - AKS: `10.20.2.0/24`

3. **Azure Kubernetes Service (AKS)**: `eco-dev-aks`
   - Kubernetes version: 1.28.5
   - Node pool:
     - VM size: Standard_DS2_v2
     - Initial nodes: 2
     - Auto-scaling: 1-5 nodes
   - Network plugin: Azure CNI
   - Monitoring: Enabled with Log Analytics

4. **Azure Container Registry (ACR)**: `ecodevaacr`
   - SKU: Standard
   - Integrated with AKS (AcrPull role assigned)

5. **Log Analytics Workspace**: `eco-dev-law`
   - Retention: 30 days
   - Used for AKS monitoring

6. **Container Apps Environment**: `eco-dev-aca-env`
   - For microservices deployment via Container Apps

### Network Architecture
```
Virtual Network (10.20.0.0/16)
├── Container Apps Subnet (10.20.1.0/24)
│   └── Container Apps Environment
└── AKS Subnet (10.20.2.0/24)
    └── AKS Cluster Nodes
    
AKS Kubernetes Services: 10.0.0.0/16
└── DNS Service: 10.0.0.10
```

## Outputs

After successful deployment, you can retrieve outputs:

```bash
# View all outputs
terraform output

# Specific outputs
terraform output resource_group_name
terraform output acr_login_server
terraform output aks_cluster_name

# Sensitive outputs (kubeconfig)
terraform output -raw aks_kube_config > ~/.kube/config-dev
```

## Updating Infrastructure

### Modify Configuration
1. Update variables in `terraform.tfvars`
2. Run `terraform plan` to review changes
3. Run `terraform apply` to apply changes

### Common Updates
**Scale AKS nodes:**
```hcl
# In terraform.tfvars
aks_min_count = 2
aks_max_count = 10
```

**Change Kubernetes version:**
```hcl
kubernetes_version = "1.29.0"
```

## Cleanup

```bash
# Destroy all infrastructure
terraform destroy

# Confirm by typing 'yes' when prompted
```

**Warning:** This will delete all resources including data. Make sure to backup any important data before destroying.

## Troubleshooting

### Issue: Backend initialization fails
**Solution:** Verify storage account exists and you have access:
```bash
az storage account show --name <storage-account> --resource-group terraform-state-rg
```

### Issue: AKS creation fails
**Solution:** Check quota limits:
```bash
az vm list-usage --location eastus --output table
```

### Issue: Cannot connect to AKS
**Solution:** Get fresh credentials:
```bash
az aks get-credentials --resource-group eco-dev-rg --name eco-dev-aks --overwrite-existing --admin
```

## Next Steps

1. **Deploy Microservices to AKS:**
   - Build and push Docker images to ACR
   - Deploy Helm charts to AKS cluster
   - Configure ingress controller

2. **Configure CI/CD for Applications:**
   - Create GitHub Actions workflows for microservices
   - Automate image builds and deployments

3. **Set up Monitoring:**
   - Configure Application Insights
   - Set up alerts and dashboards

4. **Implement Security:**
   - Configure Azure Key Vault for secrets
   - Set up Azure AD integration
   - Configure network policies

## References

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure Container Registry Documentation](https://docs.microsoft.com/en-us/azure/container-registry/)

[🏠 Volver al README](../../README.md#guía-de-despliegue-en-azure)
