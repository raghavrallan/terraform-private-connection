# Azure Private Infrastructure – Terraform Deployment

This project deploys a **fully private Azure application architecture** using **Terraform**, with strict resource separation, private link endpoints, private DNS zones, VNet-integrated compute, and managed identities.

The **only public-facing service** is the **Azure Container App**.  
Everything else (Storage, SQL DB, Function App) is **private-only**.

---

# 📁 Folder Structure

```
AZURE-TERRAFORM-TASK/
    modules/
        network/
            main.tf
            variables.tf
            outputs.tf
        storage/
            main.tf
            variables.tf
            outputs.tf
        sql/
            main.tf
            variables.tf
            outputs.tf
        container_app/
            main.tf
            variables.tf
            outputs.tf
        function_app/
            main.tf
            variables.tf
            outputs.tf
        private_endpoints/
            main.tf
            variables.tf
            outputs.tf
    README.md
    main.tf
    providers.tf
    variables.tf
    outputs.tf
    terraform.tfvars
```

---

# 🚀 Project Overview

This Terraform project builds a **private, production-grade Azure architecture** consisting of:

### ✔ Virtual Network (VNet)
- One VNet with 3 isolated subnets:
  - `snet-aca` → Container Apps
  - `snet-functions` → Function App VNet integration
  - `snet-privatelink` → Private Endpoints only

### ✔ Container App (Public)
- Runs inside VNet  
- Public ingress enabled  
- Uses System-assigned Managed Identity  

### ✔ Function App (Private Only)
- VNet integrated for outbound  
- Inbound access restricted to VNet only  
- System-assigned Managed Identity  

### ✔ Storage Account (Private with Azure Services Access)
- Public network access restricted with firewall rules
- Default action: Deny all traffic
- Azure Services bypass enabled (required for Function App)
- Access through Private Endpoint for private connectivity
- Private DNS: `privatelink.blob.core.windows.net`

### ✔ SQL Server + Database (Private)
- Public network disabled  
- Private Endpoint only  
- Private DNS: `privatelink.database.windows.net`

### ✔ Private Endpoints + Private DNS
- Blob private endpoint  
- SQL private endpoint  
- DNS Zones linked to VNet  
- Automatic private A records  

### ✔ RBAC with Managed Identity
- Container App → Storage RBAC  
- Function App → Storage RBAC  

---

# 🔐 Full Architecture Diagram

```
                     ┌──────────────────────┐
                     │  Internet / Clients   │
                     └──────────┬───────────┘
                                │
                 PUBLIC ACCESS  │
                                ▼
                    ┌─────────────────────┐
                    │   Container App      │
                    │  (Public Ingress)    │
                    └─────────┬───────────┘
                              │ VNet Traffic Only
            ┌─────────────────┼────────────────────┐
            │                 │                    │
            ▼                 ▼                    ▼
┌─────────────────┐  ┌─────────────────┐  ┌───────────────────────┐
│  Function App    │  │ Private EP:      │  │ Private EP:          │
│ (VNet-only HTTP) │  │ Storage Blob     │  │ SQL Server           │
└─────────────────┘  └─────────────────┘  └───────────────────────┘
            │                 │                    │
            └──────────┬──────┴──────────┬────────┘
                       ▼                 ▼
              ┌──────────────────────────────────────┐
              │        Private DNS Zones              │
              │  (Blob + SQL Private DNS resolution) │
              └──────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │ Virtual Network  │
                    │  (3 Subnets)     │
                    └──────────────────┘
```

---

# 🧱 Resource Group Layout

Each service is deployed in **its own resource group**:

| Resource Group | Purpose |
|----------------|---------|
| `rg-network`   | VNet, subnets, private endpoints, private DNS |
| `rg-storage`   | Storage Account |
| `rg-database`  | SQL Server + SQL DB |
| `rg-backend`   | Container App + Function App |

---

# ⚙ How Terraform Works (Simple)

1. You write `.tf` files describing infrastructure  
2. `terraform init` downloads providers  
3. `terraform plan` shows what will be created  
4. `terraform apply` deploys everything to Azure  

Terraform keeps track of resources using `terraform.tfstate`.

---

# 🧪 How to Deploy

### Step 1 — Login to Azure
```bash
az login
az account set --subscription "<your-subscription-id>"
```

### Step 2 — Initialize Terraform
```bash
terraform init
```

### Step 3 — Preview the deployment
```bash
terraform plan
```

### Step 4 — Deploy the infrastructure
```bash
terraform apply -auto-approve
```
