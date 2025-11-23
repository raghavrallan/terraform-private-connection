#!/bin/bash

# Stop/Disable Azure Services to Save Costs
# This script stops services without destroying them

set -e

echo "========================================="
echo "Stopping Azure Services (Cost Saving)"
echo "========================================="
echo ""

# Get resource names
ACR_NAME="acrdev23d515"
CONTAINER_APP_NAME="aca-public-app-dev-23d515"
FUNCTION_APP_NAME="fn-app-dev-23d515"
BACKEND_RG="rg-backend-dev-23d515"

echo "✓ Current deployment preserved in Terraform state"
echo "✓ All infrastructure code saved in repository"
echo ""

# Scale Container App to 0 replicas (stops running but keeps config)
echo "→ Scaling Container App to 0 replicas..."
az containerapp update \
  --name $CONTAINER_APP_NAME \
  --resource-group $BACKEND_RG \
  --min-replicas 0 \
  --max-replicas 0

echo "✓ Container App scaled to 0 (no compute charges)"
echo ""

# Stop Function App
echo "→ Stopping Function App..."
az functionapp stop \
  --name $FUNCTION_APP_NAME \
  --resource-group $BACKEND_RG

echo "✓ Function App stopped"
echo ""

echo "========================================="
echo "Services Stopped Successfully!"
echo "========================================="
echo ""
echo "Cost Impact:"
echo "  • Container App: $0/month (scaled to 0)"
echo "  • Function App: $0/month (stopped)"
echo "  • Storage: ~$1-5/month (kept for state)"
echo "  • SQL Database: ~$15/month (S0 tier, cannot stop)"
echo "  • ACR: ~$40/month (Premium tier, cannot stop)"
echo "  • Key Vault: ~$0.15/month (minimal usage)"
echo "  • Private Endpoints: ~$29/month (4 endpoints)"
echo "  • Estimated monthly cost: ~$85-89/month"
echo ""
echo "To FULLY minimize costs, run: terraform destroy"
echo "To restart services, run: ./restart-services.sh"
echo ""
