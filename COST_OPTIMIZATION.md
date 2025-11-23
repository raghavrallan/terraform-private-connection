# Cost Optimization Guide

## Current Deployment Costs

### Active Services (Current Monthly Cost: ~$97-136)

| Service | Tier | Monthly Cost | Can Stop? |
|---------|------|--------------|-----------|
| Static Web App | Free | $0 | N/A (Free) |
| Container App | Consumption | $10-30 | ✅ Yes (scale to 0) |
| Function App | Consumption | $0-15 | ✅ Yes (stop) |
| SQL Database | S0 | $15 | ❌ No* |
| Storage Account | Standard LRS | $1-5 | ❌ No (needed for state) |
| ACR | Premium | $40 | ❌ No* |
| Key Vault | Standard | $0.15 | ❌ No (minimal cost) |
| Private Endpoints (4x) | Per endpoint | $29 | ❌ No* |
| Private DNS Zones (4x) | Per zone | $2 | ❌ No (minimal cost) |

*Can only be removed via `terraform destroy`

## Cost Saving Options

### Option 1: Stop Compute Services (Recommended)
**Savings: ~$10-45/month**
**Remaining Cost: ~$85-89/month**

Stop Container App and Function App but keep all infrastructure:

```bash
./stop-services.sh
```

This stops:
- Container App (scale to 0 replicas)
- Function App (stopped)

**When to use**: Development breaks, weekends, testing phases

**To restart**:
```bash
./restart-services.sh
```

### Option 2: Destroy Everything
**Savings: 100% (~$97-136/month)**
**Remaining Cost: $0/month**

```bash
terraform destroy -var="env_suffix=23d515" -auto-approve
```

**When to use**: Long-term pause, project completion

**To rebuild**: Run `terraform apply` again

### Option 3: Downgrade Services
**Savings: ~$35-64/month**
**Remaining Cost: ~$33-72/month**

Manual changes in Azure Portal:
1. Downgrade ACR from Premium to Basic (-$35/month)
2. Remove private endpoints (-$29/month)
3. Keep SQL Database S0 ($15/month)

**Trade-offs**:
- No private endpoints (less secure)
- No ACR private endpoint support
- Requires manual reconfiguration

## What's Saved and Where

### Infrastructure State
- **Location**: `terraform.tfstate` (local) or Azure Storage (if configured)
- **Contents**: Complete infrastructure definition
- **Recovery**: Run `terraform apply` to recreate

### Application Code
- **Location**: `app/` directory
  - `app/container-app/` - Container App API code
  - `app/function-app/` - Function App code
  - `app/static-web-app/` - Static Web App code
- **Docker Image**: Stored in ACR (acrdev23d515.azurecr.io/container-app-api:v1)

### Terraform Configuration
- **Location**: Root directory + `modules/`
- **Files**: `*.tf` files defining all infrastructure
- **Recovery**: Infrastructure as Code - fully reproducible

### Documentation
- **DEPLOYMENT_GUIDE.md** - Full deployment instructions
- **NEXT_STEPS.md** - Post-deployment steps
- **PROJECT_SUMMARY.md** - Project overview
- **This file** - Cost optimization guide

## Current Services Status

### Stopped (By stop-services.sh)
```bash
# Check Container App status
az containerapp show --name aca-public-app-dev-23d515 --resource-group rg-backend-dev-23d515 --query "properties.runningStatus"

# Check Function App status
az functionapp show --name fn-app-dev-23d515 --resource-group rg-backend-dev-23d515 --query "state"
```

### Still Running (Cannot Stop Without Destroy)
- SQL Database: sql-server-dev-priv-23d515.database.windows.net
- Storage Account: stdevprivinfra23d515
- ACR: acrdev23d515.azurecr.io
- Key Vault: kv-dev-23d515.vault.azure.net
- Static Web App: purple-pond-0f8879f1e.3.azurestaticapps.net
- All networking (VNet, Private Endpoints, DNS)

## Recovery Procedures

### From Stopped State
```bash
# Quick restart
./restart-services.sh

# Or manually
az containerapp update --name aca-public-app-dev-23d515 --resource-group rg-backend-dev-23d515 --min-replicas 1
az functionapp start --name fn-app-dev-23d515 --resource-group rg-backend-dev-23d515
```

### From Destroyed State
```bash
# Reinitialize Terraform
terraform init

# Deploy everything
terraform apply -var="env_suffix=23d515" -auto-approve

# Rebuild and redeploy Container App (see NEXT_STEPS.md)
cd app/container-app
az acr build --registry acrdev23d515 --image container-app-api:v1 .
az containerapp update --name aca-public-app-dev-23d515 --resource-group rg-backend-dev-23d515 --image acrdev23d515.azurecr.io/container-app-api:v1
```

## Cost Monitoring

### View Current Costs
```bash
# View costs for all resource groups
az consumption usage list --start-date 2025-11-01 --end-date 2025-11-30

# View Container App costs
az monitor metrics list --resource /subscriptions/.../aca-public-app-dev-23d515
```

### Set Budget Alerts
```bash
# Create a budget in Azure Portal
# Cost Management > Budgets > Add budget
# Recommended: $150/month with alerts at 80% and 100%
```

## Recommendations

### For Development
1. **Stop services when not actively developing**: Use `stop-services.sh`
2. **Use Container App auto-scaling**: Already configured (0-2 replicas)
3. **Keep infrastructure up**: Faster to restart than rebuild

### For Production
1. **Downgrade ACR to Standard**: If you don't need private endpoints ($20/month saved)
2. **Remove private endpoints**: If security requirements allow ($29/month saved)
3. **Optimize SQL Database tier**: Consider serverless if usage is sporadic

### For Long-Term Storage
1. **Destroy everything**: Run `terraform destroy`
2. **Keep code repository**: All configuration preserved in Git
3. **Rebuild when needed**: ~15 minutes with automation

## Important Notes

⚠️ **Do NOT delete these files**:
- `terraform.tfstate` - Contains current infrastructure state
- `terraform.tfstate.backup` - Backup of previous state
- `.terraform/` directory - Terraform providers and modules
- `app/` directory - Application source code

✅ **Safe to delete** (can regenerate):
- `function-app.zip` - Can rebuild from source
- Container App node_modules/ - Can reinstall
- Build artifacts and logs

## Summary

**Currently Stopped**: Container App, Function App (via stop-services.sh)
**Still Running**: SQL, Storage, ACR, Key Vault, Networking (~$85-89/month)
**Fully Saved**: All Terraform state, application code, documentation
**Recovery Time**: 5 minutes (restart) or 15 minutes (full rebuild)

To resume work, simply run:
```bash
./restart-services.sh
```
