# Static Web App Frontend

This is a simple frontend application that demonstrates integration with the Azure Container App API.

## Features

- Health check for Container App
- Test Key Vault integration
- Test Storage Account connectivity
- Test SQL Database connectivity
- Call private Function App through Container App
- Upload blobs to Storage Account

## Deployment

This app is designed to be deployed to Azure Static Web Apps using the deployment token.

### Using Azure CLI

```bash
# Get the deployment token from Terraform output
DEPLOYMENT_TOKEN=$(terraform output -raw static_web_app_api_key)

# Deploy using Azure Static Web Apps CLI
npx @azure/static-web-apps-cli deploy ./app/static-web-app \
  --deployment-token $DEPLOYMENT_TOKEN \
  --app-location "/"
```

### Using GitHub Actions

Add the deployment token as a secret in your GitHub repository and use the Static Web Apps GitHub Action.

## Configuration

After deployment, configure the Container App API endpoint in the web interface.

## Local Development

Simply open `index.html` in a web browser. Make sure to configure the API endpoint to your Container App URL.
