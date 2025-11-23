#!/bin/bash

# Azure Multi-Service Deployment Script
# This script automates the deployment of all services

set -e  # Exit on error

echo "=========================================="
echo "Azure Multi-Service Deployment Script"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

command -v az >/dev/null 2>&1 || { print_error "Azure CLI is required but not installed. Aborting."; exit 1; }
command -v terraform >/dev/null 2>&1 || { print_error "Terraform is required but not installed. Aborting."; exit 1; }
command -v docker >/dev/null 2>&1 || { print_error "Docker is required but not installed. Aborting."; exit 1; }

print_status "All prerequisites met!"
echo ""

# Step 1: Deploy Infrastructure
print_status "Step 1: Deploying infrastructure with Terraform..."
terraform init
terraform apply -var="env_suffix=23d515" -auto-approve

if [ $? -eq 0 ]; then
    print_status "Infrastructure deployed successfully!"
else
    print_error "Infrastructure deployment failed!"
    exit 1
fi
echo ""

# Step 2: Get outputs
print_status "Step 2: Retrieving infrastructure outputs..."
ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
ACR_NAME=$(terraform output -raw acr_name)
CONTAINER_APP_NAME=$(terraform output -raw container_app_name)
FUNCTION_APP_NAME=$(terraform output -raw function_app_name)
KEY_VAULT_NAME=$(terraform output -raw key_vault_name)
STORAGE_ACCOUNT_NAME=$(terraform output -raw storage_account_name)
SQL_SERVER_FQDN=$(terraform output -raw sql_server_fqdn)
SQL_DB_NAME=$(terraform output -raw sql_db_name)
BACKEND_RG=$(terraform output -raw resource_group_backend_name)

print_status "Outputs retrieved successfully!"
echo ""

# Step 3: Build and push container image
print_status "Step 3: Building and pushing container image..."
cd app/container-app

print_status "Logging into ACR..."
az acr login --name $ACR_NAME

print_status "Building Docker image..."
docker build -t ${ACR_LOGIN_SERVER}/container-app-api:latest .

print_status "Pushing image to ACR..."
docker push ${ACR_LOGIN_SERVER}/container-app-api:latest

cd ../..
print_status "Container image deployed to ACR!"
echo ""

# Step 4: Grant Key Vault access to current user
print_status "Step 4: Configuring Key Vault access..."
CURRENT_USER_ID=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")

if [ -n "$CURRENT_USER_ID" ]; then
    KEY_VAULT_ID=$(terraform output -raw key_vault_id)
    az role assignment create \
      --assignee $CURRENT_USER_ID \
      --role "Key Vault Secrets Officer" \
      --scope $KEY_VAULT_ID \
      2>/dev/null || print_warning "Key Vault role assignment may already exist"

    print_status "Waiting for RBAC propagation..."
    sleep 15
fi
echo ""

# Step 5: Update Container App
print_status "Step 5: Updating Container App with image and environment..."
az containerapp update \
  --name $CONTAINER_APP_NAME \
  --resource-group $BACKEND_RG \
  --image ${ACR_LOGIN_SERVER}/container-app-api:latest \
  --set-env-vars \
    KEY_VAULT_URL=https://${KEY_VAULT_NAME}.vault.azure.net \
    STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME} \
    SQL_SERVER=${SQL_SERVER_FQDN} \
    SQL_DATABASE=${SQL_DB_NAME} \
    FUNCTION_APP_URL=https://${FUNCTION_APP_NAME}.azurewebsites.net

print_status "Container App updated successfully!"
echo ""

# Step 6: Deploy Function App
print_status "Step 6: Deploying Function App..."
cd app/function-app

print_status "Installing dependencies..."
npm install --production

print_status "Creating deployment package..."
zip -r function-app.zip . -x "*.git*" -x ".funcignore"

print_status "Deploying to Azure..."
az functionapp deployment source config-zip \
  --name $FUNCTION_APP_NAME \
  --resource-group $BACKEND_RG \
  --src function-app.zip

print_status "Configuring Function App environment..."
az functionapp config appsettings set \
  --name $FUNCTION_APP_NAME \
  --resource-group $BACKEND_RG \
  --settings \
    KEY_VAULT_URL=https://${KEY_VAULT_NAME}.vault.azure.net \
    STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME}

# Clean up
rm function-app.zip

cd ../..
print_status "Function App deployed successfully!"
echo ""

# Step 7: Get URLs
print_status "Step 7: Retrieving service URLs..."
CONTAINER_APP_FQDN=$(az containerapp show \
  --name $CONTAINER_APP_NAME \
  --resource-group $BACKEND_RG \
  --query "properties.configuration.ingress.fqdn" -o tsv)

STATIC_WEB_APP_URL=$(terraform output -raw static_web_app_default_host_name)

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo -e "${GREEN}Static Web App URL:${NC} https://${STATIC_WEB_APP_URL}"
echo -e "${GREEN}Container App API URL:${NC} https://${CONTAINER_APP_FQDN}"
echo -e "${GREEN}Function App URL:${NC} https://${FUNCTION_APP_NAME}.azurewebsites.net"
echo ""
echo "Next steps:"
echo "1. Open the Static Web App URL in your browser"
echo "2. Configure the Container App API endpoint: https://${CONTAINER_APP_FQDN}"
echo "3. Test the application using the UI"
echo ""
echo "To view Container App logs:"
echo "  az containerapp logs show --name $CONTAINER_APP_NAME --resource-group $BACKEND_RG --follow"
echo ""
echo "To view Function App logs:"
echo "  az functionapp log tail --name $FUNCTION_APP_NAME --resource-group $BACKEND_RG"
echo ""
print_status "Deployment script finished successfully!"
