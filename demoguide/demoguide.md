# Demo Guide — Logistics AI with Azure AI Foundry, Container Apps & SQL

**Duration**: ~30 minutes  
**Audience**: Developers, architects, cloud decision-makers  
**Scenario**: A European logistics company uses Azure AI Foundry to give operations teams natural-language insight into their shipment data stored in Azure SQL, running on Azure Container Apps.

---

## Pre-Demo Checklist

- [ ] `azd up` completed successfully
- [ ] App URL noted from deployment output
- [ ] Azure Portal open, resource group visible
- [ ] Browser tab with the app already loaded

---

## Part 1 — Architecture Walk-through (5 min)

### Step 1.1 — Open the Azure Portal

Navigate to the resource group `rg-fsc-{env}`. Show the deployed resources:

- Container Apps Environment + Container App
- Azure AI Foundry (AIServices) account
- SQL Server + Database
- Container Registry
- Application Insights

**Key talking point**: Everything is connected via Managed Identity — no passwords, no connection strings in code or environment variables.

### Step 1.2 — Show the Container App

1. Click the Container App → **Overview**
2. Click **Application URL** to open the dashboard
3. Point out: scale 0–5 replicas, port 8080, Consumption tier

### Step 1.3 — Show AI Foundry

1. Open the AI Foundry resource → **Model deployments**
2. Show GPT-4.1-mini deployment: Standard, 30K TPM
3. Open **AI Foundry portal** link → show Hub + Project structure

---

## Part 2 — Live Dashboard Demo (10 min)

### Step 2.1 — Open the Logistics Dashboard

![Dashboard screenshot — shipments table with status badges](screenshots/01-dashboard.png)

Point out:
- Summary cards: total shipments, delayed count, open exceptions
- Shipment table with colour-coded status badges (Delayed=red, In Transit=blue, On Time=green, Delivered=grey)
- Active exceptions panel (red left border)

**Talking point**: Data is live from Azure SQL, loaded on every page request via managed identity token auth (`DefaultAzureCredential`).

### Step 2.2 — Show a Delayed Shipment

Highlight the `Delayed` rows in the table. Point out the Barcelona→Berlin shipment with a customs exception.

---

## Part 3 — AI Query Demo (10 min)

### Step 3.1 — First Query: Risk Assessment

In the AI assistant box, type:

> **Which shipments are at risk of missing their delivery deadline?**

Click **Ask**.

![AI response showing risk assessment](screenshots/02-ai-response.png)

**Expected response**: GPT-4.1-mini identifies the delayed shipments and customs exception, gives a concise 2-3 sentence summary.

**Talking point**: The app builds a context string from live SQL data and sends it as a system prompt — the AI has real operational awareness, not canned responses.

### Step 3.2 — Second Query: Exception Summary

Type:

> **Summarise the current exceptions and their potential business impact.**

**Expected response**: Summary of the customs hold and weather delay, referencing the specific shipment IDs.

### Step 3.3 — Freestyle Query

Invite the audience to suggest a question. Good examples:
- *"Which carrier has the most issues this week?"*
- *"What's the estimated delivery for shipment 3?"*
- *"How many shipments are currently on time?"*

---

## Part 4 — Under the Hood (5 min)

### Step 4.1 — Managed Identity Auth

Navigate to the Container App → **Identity** → show System Assigned MI is enabled.

Navigate to the SQL Server → **Azure Active Directory** → show AAD-only authentication is enforced.

**Talking point**: The app gets a token for `https://database.windows.net/.default` at runtime using `DefaultAzureCredential`. No passwords anywhere.

### Step 4.2 — Application Insights

Open Application Insights → **Live Metrics** or **Failures**.

Show that every AI query and SQL call is traced automatically via the `AddApplicationInsightsTelemetry()` registration.

### Step 4.3 — SQL Auto-Pause

Navigate to the SQL Database → **Compute + storage**.

Show: GP_S_Gen5_1, min capacity 0.5 vCores, auto-pause after 60 minutes.

**Talking point**: Cost-optimised for demo workloads — the database pauses automatically when not in use, resuming transparently on first connection.

---

## Key Messages

1. **Azure AI Foundry** provides a managed, enterprise-grade AI hub — models, projects, and RBAC in one place
2. **Managed Identity** eliminates credential management across all three services (SQL, ACR, AI Foundry)
3. **Container Apps Consumption** tier scales to zero — pay only for actual usage
4. **SQL Serverless** auto-pause means near-zero cost when idle — ideal for demos and dev/test
5. **`azd up`** deploys the full stack in ~10 minutes — infra + build + push + deploy

---

## Tear Down

```bash
azd down --purge
```

This removes all resources including the AI Foundry model deployment and SQL server.
