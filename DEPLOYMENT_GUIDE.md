# Azure Multi-Service Deployment Guide

This guide walks you through deploying the complete Azure infrastructure and applications.

## Architecture Overview

This solution deploys a comprehensive Azure architecture with:

- **Static Web App**: Frontend application
- **Container App**: Public-facing API (from ACR)
- **Function App**: Private backend service (VNet integrated)
- **Azure SQL Database**: With managed identity authentication
- **Storage Account**: Private blob storage
- **Key Vault**: Secrets management with RBAC
- **Azure Container Registry (ACR)**: Private container registry
- **Virtual Network**: With subnets for each service
- **Private Endpoints**: For Storage, SQL, ACR, and Key Vault

## Prerequisites

- Azure CLI installed and logged in
- Terraform installed (v1.0+)
- Docker installed (for building container images)
- Node.js 18+ (for local testing)
- Azure subscription with appropriate permissions

## Step 1: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan -var="env_suffix=23d515"

# Deploy infrastructure
terraform apply -var="env_suffix=23d515" -auto-approve
```

Wait for the infrastructure to be created (~10-15 minutes).

## Step 2: Get Infrastructure Outputs

```bash
# Get all outputs
terraform output

# Get specific values
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
ACR_NAME=$(terraform output -raw acr_name)
CONTAINER_APP_NAME=$(terraform output -raw container_app_name)
FUNCTION_APP_NAME=$(terraform output -raw function_app_name)
KEY_VAULT_NAME=$(terraform output -raw key_vault_name)
STATIC_WEB_APP_NAME=$(terraform output -raw static_web_app_name)
STORAGE_ACCOUNT_NAME=$(terraform output -raw storage_account_name)
SQL_SERVER_FQDN=$(terraform output -raw sql_server_fqdn)
```

## Step 3: Build and Push Container Image

```bash
# Navigate to container app directory
cd app/container-app

# Login to ACR using managed identity
az acr login --name $ACR_NAME

# Build the Docker image
docker build -t ${ACR_LOGIN_SERVER}/container-app-api:latest .

# Push to ACR
docker push ${ACR_LOGIN_SERVER}/container-app-api:latest

# Return to root directory
cd ../..
```

## Step 4: Update Container App with Image

```bash
# Get resource group
BACKEND_RG=$(az containerapp show --name $CONTAINER_APP_NAME --resource-group $(terraform output -raw resource_group_backend_name) --query "resourceGroup" -o tsv)

# Update Container App with the image from ACR
az containerapp update \
  --name $CONTAINER_APP_NAME \
  --resource-group $BACKEND_RG \
  --image ${ACR_LOGIN_SERVER}/container-app-api:latest \
  --set-env-vars \
    KEY_VAULT_URL=https://${KEY_VAULT_NAME}.vault.azure.net \
    STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME} \
    SQL_SERVER=${SQL_SERVER_FQDN} \
    SQL_DATABASE=$(terraform output -raw sql_db_name) \
    FUNCTION_APP_URL=https://${FUNCTION_APP_NAME}.azurewebsites.net
```

## Step 5: Grant Terraform User Access to Key Vault

The Terraform service principal needs temporary access to create secrets:

```bash
# Get current user/service principal object ID
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || az account show --query user.name -o tsv)

# Grant Key Vault Secrets Officer role (for secret creation)
az role assignment create \
  --assignee $CURRENT_USER_ID \
  --role "Key Vault Secrets Officer" \
  --scope $(terraform output -raw key_vault_id)

# Wait a few seconds for RBAC to propagate
sleep 10
```

## Step 6: Deploy Function App

```bash
# Navigate to function app directory
cd app/function-app

# Install dependencies
npm install

# Create a zip package
zip -r function-app.zip . -x "*.git*" -x "node_modules/*"

# Deploy to Function App
az functionapp deployment source config-zip \
  --name $FUNCTION_APP_NAME \
  --resource-group $BACKEND_RG \
  --src function-app.zip

# Configure Function App environment variables
az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $BACKEND_RG \
  --settings \
    KEY_VAULT_URL=https://${KEY_VAULT_NAME}.vault.azure.net \
    STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME}

# Return to root
cd ../..
```

## Step 7: Deploy Static Web App

```bash
# Get deployment token
DEPLOYMENT_TOKEN=$(terraform output -raw static_web_app_api_key)

# Get Container App FQDN
CONTAINER_APP_FQDN=$(az containerapp show \
  --name $CONTAINER_APP_NAME \
  --resource-group $BACKEND_RG \
  --query "properties.configuration.ingress.fqdn" -o tsv)

# Note: You'll need to manually configure the API endpoint in the Static Web App UI
echo "Static Web App URL: https://$(terraform output -raw static_web_app_default_host_name)"
echo "Container App API URL: https://${CONTAINER_APP_FQDN}"

# Deploy using Azure Static Web Apps CLI (if you have it installed)
# npm install -g @azure/static-web-apps-cli
# swa deploy ./app/static-web-app --deployment-token $DEPLOYMENT_TOKEN
```

Alternatively, you can deploy via GitHub Actions or Azure DevOps by setting up the deployment token as a secret.

## Step 8: Configure SQL Database

```bash
# Connect to SQL and create a sample table
# Note: This requires Azure AD authentication

# Get current user
CURRENT_USER=$(az account show --query user.name -o tsv)

# Add current user as SQL admin (if not already)
az sql server ad-admin create \
  --resource-group $(terraform output -raw resource_group_database_name) \
  --server-name $(terraform output -raw sql_server_name) \
  --display-name $CURRENT_USER \
  --object-id $(az ad signed-in-user show --query id -o tsv)

# Connect using Azure Data Studio or sqlcmd with Azure AD auth
# Create sample tables as needed
```

## Step 9: Test the Deployment

### Test Container App API

```bash
# Get Container App URL
CONTAINER_APP_URL="https://${CONTAINER_APP_FQDN}"

# Test health endpoint
curl ${CONTAINER_APP_URL}/health

# Test Key Vault integration
curl ${CONTAINER_APP_URL}/api/keyvault/test

# Test Storage integration
curl ${CONTAINER_APP_URL}/api/storage/test

# Test Database integration
curl ${CONTAINER_APP_URL}/api/database/test
```

### Test Static Web App

1. Open the Static Web App URL in a browser
2. Configure the Container App API endpoint
3. Click the test buttons to verify all integrations

## Step 10: Monitor and Verify

```bash
# Check Container App logs
az containerapp logs show \
  --name $CONTAINER_APP_NAME \
  --resource-group $BACKEND_RG \
  --follow

# Check Function App logs
az functionapp log tail \
  --name $FUNCTION_APP_NAME \
  --resource-group $BACKEND_RG
```

## Troubleshooting

### Container App Can't Access Key Vault

- Verify RBAC role assignment: `Key Vault Secrets User`
- Check that private endpoint is properly configured
- Verify managed identity is enabled on Container App

### Container App Can't Pull from ACR

- Verify RBAC role assignment: `AcrPull`
- Check that ACR allows AzureServices in network rules
- Verify Container App managed identity is enabled

### Function App Timeout

- Check VNet integration is properly configured
- Verify private DNS zones are linked to VNet
- Check NSG rules if any

### SQL Connection Failures

- Ensure Azure AD authentication is enabled on SQL Server
- Verify managed identity has access to database
- Check that private endpoint DNS resolution is working

## Clean Up

To destroy all resources:

```bash
# This will remove ALL resources
terraform destroy -var="env_suffix=23d515" -auto-approve
```

## Architecture Diagram

```
┌─────────────────────┐
│  Static Web App     │ (Public)
│  (Frontend)         │
└──────────┬──────────┘
           │
           │ HTTPS
           ▼
┌─────────────────────┐
│  Container App      │ (Public)
│  (API)              │
└──────────┬──────────┘
           │
           ├──────────────────┐
           │                  │
           ▼                  ▼
┌──────────────────┐  ┌──────────────────┐
│  Function App    │  │  Key Vault       │
│  (Private)       │  │  (Private)       │
└──────────────────┘  └──────────────────┘
           │
           ├──────────────────┬──────────────────┐
           ▼                  ▼                  ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  SQL Database    │  │  Storage Account │  │  ACR             │
│  (Private)       │  │  (Private)       │  │  (Private)       │
└──────────────────┘  └──────────────────┘  └──────────────────┘

All private resources connected via Private Endpoints
All services use Managed Identity for authentication
```

## Security Features

- ✅ No connection strings or keys in code
- ✅ All authentication via Managed Identity
- ✅ Private endpoints for all backend services
- ✅ Network isolation with VNet
- ✅ RBAC-based access control
- ✅ Secrets stored in Key Vault
- ✅ Container images in private ACR
- ✅ Function App not publicly accessible

## Next Steps

- Configure monitoring and alerts
- Set up Application Insights
- Implement CI/CD pipelines
- Add custom domains and SSL certificates
- Implement proper logging and diagnostics
- Set up backup and disaster recovery
