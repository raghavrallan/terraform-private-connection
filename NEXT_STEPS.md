# Next Steps - Application Deployment

Once Terraform infrastructure deployment completes, follow these steps to deploy the applications.

## Prerequisites Check

```bash
# Verify you're logged in
az account show

# Verify Docker is running
docker --version
docker ps
```

## Step 1: Get Infrastructure Outputs

```bash
# Get all outputs
terraform output

# Store important values
export ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
export ACR_NAME=$(terraform output -raw acr_name)
export CONTAINER_APP_NAME=$(terraform output -raw container_app_name)
export FUNCTION_APP_NAME=$(terraform output -raw function_app_name)
export KEY_VAULT_NAME=$(terraform output -raw key_vault_name)
export STORAGE_ACCOUNT_NAME=$(terraform output -raw storage_account_name)
export SQL_SERVER_FQDN=$(terraform output -raw sql_server_fqdn)
export SQL_DB_NAME=$(terraform output -raw sql_db_name)
export BACKEND_RG=$(terraform output -raw resource_group_backend_name)
export STATIC_WEB_APP_NAME=$(terraform output -raw static_web_app_name)

# Display values
echo "ACR Login Server: $ACR_LOGIN_SERVER"
echo "Container App: $CONTAINER_APP_NAME"
echo "Function App: $FUNCTION_APP_NAME"
echo "Key Vault: $KEY_VAULT_NAME"
```

## Step 2: Build and Push Container Image to ACR

```bash
# Navigate to container app directory
cd app/container-app

# Login to ACR
az acr login --name $ACR_NAME

# Build the Docker image
docker build -t ${ACR_LOGIN_SERVER}/container-app-api:v1 .

# Verify image was built
docker images | grep container-app-api

# Push to ACR
docker push ${ACR_LOGIN_SERVER}/container-app-api:v1

# Verify image in ACR
az acr repository show --name $ACR_NAME --repository container-app-api

# Return to root
cd ../..
```

## Step 3: Update Container App with Custom Image

```bash
# Update Container App with the new image from ACR
az containerapp update \
  --name $CONTAINER_APP_NAME \
  --resource-group $BACKEND_RG \
  --image ${ACR_LOGIN_SERVER}/container-app-api:v1 \
  --set-env-vars \
    KEY_VAULT_URL=https://${KEY_VAULT_NAME}.vault.azure.net \
    STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME} \
    SQL_SERVER=${SQL_SERVER_FQDN} \
    SQL_DATABASE=${SQL_DB_NAME} \
    FUNCTION_APP_URL=https://${FUNCTION_APP_NAME}.azurewebsites.net

# Get the Container App URL
export CONTAINER_APP_URL=$(az containerapp show \
  --name $CONTAINER_APP_NAME \
  --resource-group $BACKEND_RG \
  --query "properties.configuration.ingress.fqdn" -o tsv)

echo "Container App URL: https://${CONTAINER_APP_URL}"
```

## Step 4: Grant Key Vault Access

The deployment user needs temporary access to manage Key Vault:

```bash
# Get current user object ID
export USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

# Grant Key Vault Secrets Officer role (for secret management)
export KEY_VAULT_ID=$(terraform output -raw key_vault_id)

az role assignment create \
  --assignee $USER_OBJECT_ID \
  --role "Key Vault Secrets Officer" \
  --scope $KEY_VAULT_ID

# Wait for RBAC propagation
echo "Waiting 15 seconds for RBAC to propagate..."
sleep 15

echo "Key Vault access granted!"
```

## Step 5: Deploy Function App Code

```bash
# Navigate to function app directory
cd app/function-app

# Install production dependencies
npm install --production

# Create deployment package
zip -r function-app.zip . -x "*.git*" -x ".funcignore" -x "node_modules/.bin/*"

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

# Clean up
rm function-app.zip

# Return to root
cd ../..

echo "Function App deployed!"
```

## Step 6: Test Container App Endpoints

```bash
# Test health endpoint
curl https://${CONTAINER_APP_URL}/health

# Test Key Vault integration
curl https://${CONTAINER_APP_URL}/api/keyvault/test

# Test Storage integration
curl https://${CONTAINER_APP_URL}/api/storage/test

# Test Database integration
curl https://${CONTAINER_APP_URL}/api/database/test

# Test Function App call
curl https://${CONTAINER_APP_URL}/api/function/call
```

## Step 7: Deploy Static Web App (Optional)

The Static Web App can be deployed via:

### Option A: Manual Upload

```bash
cd app/static-web-app

# Get deployment token
export DEPLOYMENT_TOKEN=$(terraform output -raw static_web_app_api_key)

# Deploy using SWA CLI (if installed)
npx @azure/static-web-apps-cli deploy \
  --deployment-token $DEPLOYMENT_TOKEN \
  --app-location "."
```

### Option B: GitHub Actions

1. Fork/push the code to GitHub
2. Add `AZURE_STATIC_WEB_APPS_API_TOKEN` as a repository secret
3. Use GitHub Actions workflow to deploy

### Option C: Azure CLI

```bash
# Get Static Web App details
az staticwebapp show \
  --name $STATIC_WEB_APP_NAME \
  --resource-group $BACKEND_RG
```

## Step 8: Configure Static Web App

Once deployed:

1. Open Static Web App URL: https://$(terraform output -raw static_web_app_default_host_name)
2. In the UI, configure the Container App API endpoint: `https://${CONTAINER_APP_URL}`
3. Save the configuration (stored in browser localStorage)
4. Test all endpoints using the UI buttons

## Step 9: Verify All Services

```bash
# Check Container App status
az containerapp show --name $CONTAINER_APP_NAME --resource-group $BACKEND_RG --query "properties.runningStatus"

# Check Function App status
az functionapp show --name $FUNCTION_APP_NAME --resource-group $BACKEND_RG --query "state"

# View Container App logs
az containerapp logs show --name $CONTAINER_APP_NAME --resource-group $BACKEND_RG --follow

# View Function App logs
az functionapp log tail --name $FUNCTION_APP_NAME --resource-group $BACKEND_RG
```

## Step 10: Final URLs

```bash
echo "==================================="
echo "Deployment Complete!"
echo "==================================="
echo ""
echo "Public Services:"
echo "  Container App API: https://${CONTAINER_APP_URL}"
echo "  Static Web App: https://$(terraform output -raw static_web_app_default_host_name)"
echo ""
echo "Private Services (VNet/Private Endpoint only):"
echo "  Function App: https://${FUNCTION_APP_NAME}.azurewebsites.net"
echo "  SQL Server: ${SQL_SERVER_FQDN}"
echo "  Storage: ${STORAGE_ACCOUNT_NAME}.blob.core.windows.net"
echo "  ACR: ${ACR_LOGIN_SERVER}"
echo "  Key Vault: https://${KEY_VAULT_NAME}.vault.azure.net"
echo ""
echo "Test the Container App:"
echo "  curl https://${CONTAINER_APP_URL}/health"
echo ""
```

## Troubleshooting

### Container App shows 403 errors

Check RBAC permissions:
```bash
# List role assignments for Container App
az role assignment list --scope $(terraform output -raw storage_account_id)
```

### Function App not accessible

The Function App is private by design. It should only be called by the Container App using managed identity.

### Key Vault access denied

Grant yourself permissions:
```bash
az role assignment create \
  --assignee $USER_OBJECT_ID \
  --role "Key Vault Secrets Officer" \
  --scope $(terraform output -raw key_vault_id)
```

### ACR pull failures

Verify Container App has AcrPull role:
```bash
az role assignment list --scope $(terraform output -raw acr_id)
```

## Quick Deploy Script

Save this as `quick-deploy.sh`:

```bash
#!/bin/bash
set -e

echo "Starting application deployment..."

# Get outputs
export ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
export ACR_NAME=$(terraform output -raw acr_name)
export CONTAINER_APP_NAME=$(terraform output -raw container_app_name)
export BACKEND_RG=$(terraform output -raw resource_group_backend_name)
export KEY_VAULT_NAME=$(terraform output -raw key_vault_name)
export STORAGE_ACCOUNT_NAME=$(terraform output -raw storage_account_name)
export SQL_SERVER_FQDN=$(terraform output -raw sql_server_fqdn)
export SQL_DB_NAME=$(terraform output -raw sql_db_name)
export FUNCTION_APP_NAME=$(terraform output -raw function_app_name)

# Build and push container
echo "Building container image..."
cd app/container-app
az acr login --name $ACR_NAME
docker build -t ${ACR_LOGIN_SERVER}/container-app-api:v1 .
docker push ${ACR_LOGIN_SERVER}/container-app-api:v1
cd ../..

# Update Container App
echo "Updating Container App..."
az containerapp update \
  --name $CONTAINER_APP_NAME \
  --resource-group $BACKEND_RG \
  --image ${ACR_LOGIN_SERVER}/container-app-api:v1 \
  --set-env-vars \
    KEY_VAULT_URL=https://${KEY_VAULT_NAME}.vault.azure.net \
    STORAGE_ACCOUNT_NAME=${STORAGE_ACCOUNT_NAME} \
    SQL_SERVER=${SQL_SERVER_FQDN} \
    SQL_DATABASE=${SQL_DB_NAME} \
    FUNCTION_APP_URL=https://${FUNCTION_APP_NAME}.azurewebsites.net

# Deploy Function App
echo "Deploying Function App..."
cd app/function-app
npm install --production
zip -r function-app.zip . -x "*.git*"
az functionapp deployment source config-zip \
  --name $FUNCTION_APP_NAME \
  --resource-group $BACKEND_RG \
  --src function-app.zip
rm function-app.zip
cd ../..

echo "Deployment complete!"
export CONTAINER_APP_URL=$(az containerapp show --name $CONTAINER_APP_NAME --resource-group $BACKEND_RG --query "properties.configuration.ingress.fqdn" -o tsv)
echo "Container App URL: https://${CONTAINER_APP_URL}"
```

Make it executable:
```bash
chmod +x quick-deploy.sh
./quick-deploy.sh
```

## Summary

After following these steps, you will have:

✅ Container App running custom Node.js API from ACR
✅ Function App deployed with private backend code
✅ All services using managed identity
✅ Key Vault storing secrets
✅ Private endpoints for all data services
✅ Static Web App for frontend testing
✅ Complete end-to-end integration

**Total deployment time**: ~5-10 minutes for applications (after infrastructure is ready)
