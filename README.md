# Foundry SQL Container App — Logistics AI Demo

A production-ready Azure demo scenario that combines:

- **Azure AI Foundry** Hub + Project with GPT-4.1-mini deployment
- **Azure Container Apps** hosting a .NET 10 Razor Pages logistics dashboard
- **Azure SQL** (General Purpose Serverless, auto-pause) with managed identity auth
- **Azure Container Registry** for private image storage
- **Application Insights** + Log Analytics for observability

All authentication uses **Managed Identity** — no connection strings, no secrets.

---

## Architecture

```
User → Container App (HTTPS)
         ├── SQL Server (token auth via MI)    — shipments, routes, exceptions
         └── AI Foundry Project (MI)           — natural language query
```

---

## What Gets Deployed

| Resource | SKU |
|---|---|
| Log Analytics Workspace | PerGB2018 |
| Application Insights | Web |
| Storage Account | Standard_LRS |
| Azure Container Registry | Standard |
| AI Foundry (AIServices) | S0 — swedencentral |
| GPT-4.1-mini deployment | Standard 30K TPM |
| Azure SQL Server | (AAD-only) |
| Azure SQL Database | GP_S_Gen5_1 Serverless |
| Container Apps Environment | Consumption |
| Container App | 0.5 vCPU / 1Gi, scale 0-5 |

---

## Prerequisites

- [Azure Developer CLI (azd)](https://aka.ms/azd) ≥ 1.9
- Docker Desktop (for local image build)
- .NET 10 SDK
- Azure subscription with Contributor + User Access Administrator

---

## Deploy

```bash
azd auth login
azd env new logistics-demo
azd env set AZURE_LOCATION eastus2
azd up
```

The `AI_FOUNDRY_ENDPOINT` and `SQL_SERVER` environment variables are automatically injected into the Container App.

---

## Demo Flow

1. Open the deployed URL (printed by `azd up`)
2. The dashboard shows 5 seed shipments with statuses: In Transit, Delayed, Delivered
3. Two active exceptions are shown in the exceptions table
4. Type a question in the AI assistant box, e.g.:
   - *"Which shipments are at risk of missing delivery?"*
   - *"Summarise the current exceptions and their impact"*
5. GPT-4.1-mini responds with logistics context built from the live SQL data

---

## Project Structure

```
infra/                         Bicep IaC (AVM modules)
  main.bicep                   Orchestration — 5-phase deployment
  main.bicepparam              azd-wired parameters
  modules/
    monitoring.bicep           Log Analytics + App Insights
    storage.bicep              Storage for AI Foundry
    sql.bicep                  SQL Server + GP Serverless DB
    container-registry.bicep   ACR Standard
    ai-foundry.bicep           AI Foundry Hub + Project + GPT-4.1-mini
    container-apps.bicep       CAE + Container App
    role-assignments.bicep     All RBAC bindings

src/LogisticsApp/              .NET 10 Razor Pages webapp
  Models/LogisticsModels.cs    Shipment, Route, ShipmentException
  Services/LogisticsDbService.cs  SQL access (MI auth + seeding)
  Services/AiFoundryService.cs    AI Foundry chat inference
  Pages/Index.cshtml(.cs)      Dashboard + inline AI query
  Dockerfile                   Multi-stage build, port 8080
```

---

## Local Development

```bash
cd src/LogisticsApp
dotnet run
```

Without `AI_FOUNDRY_ENDPOINT` or `SQL_SERVER` set, the app falls back to in-memory demo data and disables AI features gracefully.

---

## Tear Down

```bash
azd down --purge
```
