#!/bin/bash

# Restart Azure Services
# This script restarts previously stopped services

set -e

echo "========================================="
echo "Restarting Azure Services"
echo "========================================="
echo ""

# Get resource names
CONTAINER_APP_NAME="aca-public-app-dev-23d515"
FUNCTION_APP_NAME="fn-app-dev-23d515"
BACKEND_RG="rg-backend-dev-23d515"

# Scale Container App back up
echo "→ Scaling Container App back to 1-2 replicas..."
az containerapp update \
  --name $CONTAINER_APP_NAME \
  --resource-group $BACKEND_RG \
  --min-replicas 1 \
  --max-replicas 2

echo "✓ Container App restarted"
echo ""

# Start Function App
echo "→ Starting Function App..."
az functionapp start \
  --name $FUNCTION_APP_NAME \
  --resource-group $BACKEND_RG

echo "✓ Function App started"
echo ""

echo "========================================="
echo "Services Restarted Successfully!"
echo "========================================="
echo ""
echo "Container App URL: https://aca-public-app-dev-23d515.mangobeach-bb77f975.westus2.azurecontainerapps.io"
echo ""
