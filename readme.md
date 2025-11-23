# Azure Terraform Infrastructure with Private Networking

> **Production-grade Azure architecture** with complete private networking, managed identities, and containerized applications

## 🎯 Project Overview

This project deploys a **fully automated, secure Azure infrastructure** using Terraform with:

- ✅ **Modular Terraform Design** - 9 reusable modules for infrastructure as code
- ✅ **Private Networking** - VNet, Private Endpoints, and Private DNS Zones
- ✅ **Zero Secrets in Code** - All authentication via managed identities
- ✅ **Containerized Applications** - Docker images in private Azure Container Registry
- ✅ **Production Security** - RBAC-based access, network isolation, and Key Vault integration
- ✅ **Complete Application Stack** - Container App API, Function App backend, and Static Web App frontend

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet                                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                    PUBLIC ACCESS
                             │
                             ▼
              ┌──────────────────────────┐
              │   Container App (Public)  │
              │   Node.js API + Docker    │
              └──────────┬───────────────┘
                         │
                         │ VNet Integration
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
┌─────────────────┐ ┌──────────┐ ┌────────────────┐
│  Function App   │ │ Key Vault│ │ Static Web App │
│   (Private)     │ │(Private) │ │    (Public)    │
└────────┬────────┘ └────┬─────┘ └────────────────┘
         │               │
         │  Private Endpoints
         │               │
    ┌────┴───────────────┴─────────────────┐
    │                                       │
    ▼                                       ▼
┌────────────────┐                  ┌──────────────┐
│ Storage Account│                  │ SQL Database │
│   (Private)    │                  │  (Private)   │
└────────────────┘                  └──────────────┘
         │                                  │
         └──────────────┬───────────────────┘
                        │
                        ▼
              ┌─────────────────────┐
              │   Private DNS Zones  │
              │  - blob.core.windows │
              │  - database.windows  │
              │  - azurecr.io        │
              │  - vaultcore.azure   │
              └─────────────────────┘
                        │
                        ▼
              ┌─────────────────────┐
              │  Virtual Network     │
              │  3 Subnets           │
              │  - Container Apps    │
              │  - Functions         │
              │  - Private Endpoints │
              └─────────────────────┘
```

---

## 📦 What's Deployed

### Infrastructure (35+ Resources)

| Service | Tier | Purpose | Access |
|---------|------|---------|--------|
| **Azure Container Registry** | Premium | Docker image storage | Private Endpoint |
| **Key Vault** | Standard | Secrets management (RBAC) | Private Endpoint |
| **Container App** | Consumption | Public-facing Node.js API | Public + VNet |
| **Function App** | Consumption | Private backend service | Private (VNet only) |
| **Static Web App** | Free | Frontend web application | Public |
| **SQL Database** | Standard S0 | Data storage | Private Endpoint |
| **Storage Account** | Standard LRS | Blob storage | Private Endpoint |
| **Virtual Network** | Standard | Network isolation | 3 subnets |
| **Private Endpoints** | 4x | Private connectivity | ACR, KV, Storage, SQL |
| **Private DNS Zones** | 4x | Internal DNS resolution | Linked to VNet |

### Application Code

**Container App** (`app/container-app/`)
- Node.js 18 + Express API
- Dockerized with Alpine Linux
- Managed identity integration
- Endpoints: `/health`, `/api/storage/test`, `/api/keyvault/test`, `/api/database/test`

**Function App** (`app/function-app/`)
- Azure Functions v4 + Node.js 18
- HTTP trigger endpoint
- Private backend processing
- Managed identity for Key Vault and Storage

**Static Web App** (`app/static-web-app/`)
- HTML5 + Vanilla JavaScript
- Responsive CSS design
- Frontend for the application

---

## 🗂️ Project Structure

```
terraform-private-connection/
├── main.tf                    # Main infrastructure configuration
├── variables.tf               # Input variables
├── output.tf                  # Output values
├── providers.tf               # Azure provider configuration
├── terraform.tfvars           # Variable values
│
├── modules/                   # Terraform modules
│   ├── network/              # VNet, subnets
│   ├── storage/              # Storage Account
│   ├── sql/                  # SQL Server + Database
│   ├── acr/                  # Azure Container Registry
│   ├── keyvault/             # Key Vault
│   ├── container_app/        # Container App + Environment
│   ├── function_app/         # Function App + App Service Plan
│   ├── static_web_app/       # Static Web App
│   └── private_endpoints/    # Private Endpoints + DNS Zones
│
├── app/                      # Application code
│   ├── container-app/        # Node.js API + Dockerfile
│   ├── function-app/         # Azure Functions code
│   └── static-web-app/       # Frontend HTML/CSS/JS
│
├── DEPLOYMENT_GUIDE.md       # Detailed deployment instructions
├── DEPLOYMENT_COMPLETE.md    # Deployment summary
├── NEXT_STEPS.md             # Post-deployment tasks
├── PROJECT_SUMMARY.md        # Complete project overview
├── COST_OPTIMIZATION.md      # Cost-saving strategies
│
├── deploy.sh                 # Automated deployment script
├── stop-services.sh          # Stop services to save costs
└── restart-services.sh       # Restart stopped services
```

---

## 🚀 Quick Start

### Prerequisites

- Azure CLI installed and authenticated
- Terraform 1.0+ installed
- Docker installed (for building Container App image)
- Git for version control

### Step 1: Login to Azure

```bash
az login
az account set --subscription "<your-subscription-id>"
```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Deploy Infrastructure

```bash
terraform apply -var="env_suffix=<random-6-digit>" -auto-approve
```

Replace `<random-6-digit>` with a unique suffix (e.g., `123456`) to ensure globally unique resource names.

### Step 4: Deploy Container App

```bash
# Login to ACR
az acr login --name acr<env><suffix>

# Build and push Docker image
cd app/container-app
npm install
docker build -t acr<env><suffix>.azurecr.io/container-app-api:v1 .
docker push acr<env><suffix>.azurecr.io/container-app-api:v1

# Update Container App
az containerapp update \
  --name aca-public-app-<env>-<suffix> \
  --resource-group rg-backend-<env>-<suffix> \
  --image acr<env><suffix>.azurecr.io/container-app-api:v1
```

---

## 🔑 Key Features

### 1. Zero Secrets Architecture

All services authenticate using **Azure Managed Identity** (no passwords, connection strings, or keys in code):

- Container App → ACR (AcrPull)
- Container App → Key Vault (Key Vault Secrets User)
- Container App → Storage (Storage Blob Data Contributor)
- Function App → Key Vault (Key Vault Secrets User)
- Function App → Storage (Storage Blob Data Contributor + Storage Account Contributor)

### 2. Private Networking

All data services are **completely private** with no public access:

- ACR: Private endpoint only, admin disabled
- Key Vault: Private endpoint, RBAC-enabled
- Storage Account: Private endpoint, default deny
- SQL Database: Private endpoint, public access disabled

### 3. Modular Terraform Design

Nine reusable modules for maximum flexibility:

1. **network** - VNet with 3 subnets
2. **storage** - Storage Account with firewall
3. **sql** - SQL Server + Database
4. **acr** - Container Registry (Premium)
5. **keyvault** - Key Vault (RBAC)
6. **container_app** - Container App + Environment
7. **function_app** - Function App + Service Plan
8. **static_web_app** - Static Web App
9. **private_endpoints** - Private Endpoints + DNS Zones

### 4. Security Best Practices

- ✅ Network isolation with VNet and private endpoints
- ✅ RBAC-based access control throughout
- ✅ Managed identity authentication (no secrets)
- ✅ Private DNS zones for internal resolution
- ✅ Container App with minimal Alpine Linux base
- ✅ Firewall rules on all data services
- ✅ Key Vault for centralized secrets management

---

## 💰 Cost Management

### Monthly Cost Estimate

**Services Running**: ~$87-91/month
- SQL Database (S0): $15/month
- Azure Container Registry (Premium): $40/month
- Storage Account: $1-5/month
- Private Endpoints (4x): $29/month
- Key Vault: $0.15/month
- Container App: $0-10/month (consumption-based)
- Function App: $0-15/month (consumption-based)

### Stop Services to Save Costs

```bash
# Stop Container App and Function App
./stop-services.sh

# Cost savings: ~$10-25/month
# New monthly cost: ~$72-76/month
```

### Restart Services

```bash
# Restart all services
./restart-services.sh

# Recovery time: 2-3 minutes
```

### Destroy Everything

```bash
# Remove all infrastructure
terraform destroy -var="env_suffix=<your-suffix>" -auto-approve

# Cost: $0/month
# Recovery time: 15-20 minutes with terraform apply
```

See **COST_OPTIMIZATION.md** for detailed cost-saving strategies.

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **DEPLOYMENT_GUIDE.md** | Step-by-step deployment instructions |
| **DEPLOYMENT_COMPLETE.md** | Post-deployment summary with URLs |
| **PROJECT_SUMMARY.md** | Complete technical overview |
| **NEXT_STEPS.md** | Manual post-deployment tasks |
| **COST_OPTIMIZATION.md** | Cost management strategies |

---

## 🧪 Testing the Deployment

### Test Container App API

```bash
# Health check
curl https://aca-public-app-<env>-<suffix>.<region>.azurecontainerapps.io/health

# Test storage integration
curl https://aca-public-app-<env>-<suffix>.<region>.azurecontainerapps.io/api/storage/test

# Test Key Vault integration
curl https://aca-public-app-<env>-<suffix>.<region>.azurecontainerapps.io/api/keyvault/test

# Test database connectivity
curl https://aca-public-app-<env>-<suffix>.<region>.azurecontainerapps.io/api/database/test
```

### View Terraform Outputs

```bash
terraform output
```

---

## 🔄 CI/CD Integration

This project is ready for CI/CD pipelines:

### GitHub Actions Example

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Terraform Init
        run: terraform init

      - name: Terraform Apply
        run: terraform apply -var="env_suffix=${{ secrets.ENV_SUFFIX }}" -auto-approve
```

---

## 🛠️ Troubleshooting

### Issue: Container App shows welcome page instead of API

**Solution**: Check target port configuration
```bash
az containerapp ingress update \
  --name aca-public-app-<env>-<suffix> \
  --resource-group rg-backend-<env>-<suffix> \
  --target-port 8080
```

### Issue: ACR authentication failed

**Solution**: Configure registry with managed identity
```bash
az containerapp registry set \
  --name aca-public-app-<env>-<suffix> \
  --resource-group rg-backend-<env>-<suffix> \
  --server acr<env><suffix>.azurecr.io \
  --identity system
```

### Issue: Key Vault access denied

**Solution**: Wait for RBAC permissions to propagate (5-10 minutes) or manually create secrets:
```bash
az keyvault secret set \
  --vault-name kv-<env>-<suffix> \
  --name storage-account-name \
  --value "st<env>privinfra<suffix>"
```

---

## 📝 Resource Naming Convention

All resources follow a consistent naming pattern:

| Resource Type | Pattern | Example |
|---------------|---------|---------|
| Resource Group | `rg-<purpose>-<env>-<suffix>` | `rg-backend-dev-23d515` |
| Container App | `aca-public-app-<env>-<suffix>` | `aca-public-app-dev-23d515` |
| Function App | `fn-app-<env>-<suffix>` | `fn-app-dev-23d515` |
| ACR | `acr<env><suffix>` | `acrdev23d515` |
| Key Vault | `kv-<env>-<suffix>` | `kv-dev-23d515` |
| Storage | `st<env>privinfra<suffix>` | `stdevprivinfra23d515` |
| SQL Server | `sql-server-<env>-priv-<suffix>` | `sql-server-dev-priv-23d515` |

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License.

---

## 🙏 Acknowledgments

- Built with [Terraform](https://www.terraform.io/)
- Deployed on [Microsoft Azure](https://azure.microsoft.com/)
- Containerized with [Docker](https://www.docker.com/)
- Generated with [Claude Code](https://claude.com/claude-code)

---

## 📞 Support

For issues, questions, or contributions:
- Open an issue on GitHub
- Check the documentation files
- Review the troubleshooting section above

---

**Project Status**: ✅ Production Ready

**Last Updated**: November 2025

**Infrastructure as Code**: 100% Terraform

**Security**: Zero secrets in code, managed identity throughout

**Cost**: Optimized with stop/start scripts
