# Quick Start Guide

Get Atlassian Guard alerts flowing into Azure Sentinel in under 30 minutes!

## Prerequisites

- Azure subscription with Contributor access
- Atlassian organization with Guard (Enterprise plan)
- Azure CLI installed ([Install](https://docs.microsoft.com/cli/azure/install-azure-cli))

## Automated Deployment (Recommended)

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/atlassian-guard-sentinel.git
cd atlassian-guard-sentinel
```

### 2. Login to Azure

```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_NAME_OR_ID"
```

### 3. Run the Deployment Script

```bash
chmod +x deploy.sh
./deploy.sh
```

The script will:
- Create all required Azure resources
- Configure permissions
- Generate and store webhook token
- Deploy the Logic App

**Important**: Save the webhook URL and token displayed at the end!

### 4. Configure Atlassian Guard

1. Go to [Atlassian Admin](https://admin.atlassian.com)
2. Navigate to **Security** → **Atlassian Guard** → **Detect**
3. Go to **Settings** → **Integrations**
4. Click **Add integration** → **Generic Webhook**
5. Enter:
   - **Name**: Azure Sentinel
   - **Webhook URL**: [URL from deployment script]
   - **Custom Header**: `X-Automation-Webhook-Token` = [Token from deployment]
6. Select alert types and **Save**

### 5. Verify Integration

Test with the sample payload:

```bash
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -H "X-Automation-Webhook-Token: YOUR_TOKEN" \
  -d @test-payload.json
```

Check Azure Sentinel after 5-10 minutes:

```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(1h)
| take 10
```

## Manual Deployment

If you prefer step-by-step control, follow the detailed [Setup Guide](README.md#setup-instructions).

## Architecture Overview

```
┌─────────────────┐
│ Atlassian Guard │
│    (Detect)     │
└────────┬────────┘
         │ Webhook
         ▼
┌─────────────────┐     ┌──────────────┐
│   Logic App     │────▶│  Key Vault   │
│   (Webhook)     │     │   (Token)    │
└────────┬────────┘     └──────────────┘
         │
         │ Managed Identity Auth
         ▼
┌─────────────────┐     ┌──────────────┐
│      DCE        │────▶│ Log Analytics│
│  (Ingestion)    │     │  Workspace   │
└─────────────────┘     └──────┬───────┘
                               │
                               ▼
                        ┌──────────────┐
                        │    Sentinel  │
                        │  (Alerting)  │
                        └──────────────┘
```

## Common Commands

### View Logic App Runs

```bash
az logic workflow run list \
  --resource-group rg-sentinel-log-ingest-eno \
  --name la-atlassian-guard-ingest \
  --top 10
```

### Query Recent Alerts

```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(24h)
| summarize count() by AlertTitle, AlertProduct
```

### Check DCE Health

```bash
az monitor data-collection endpoint show \
  --name dce-sentinel-prod-eno \
  --resource-group rg-sentinel-log-ingest-eno
```

## Troubleshooting

### No Data Appearing?

1. Check Logic App run history for errors
2. Verify Managed Identity has correct permissions
3. Ensure DCR Immutable ID is correct in Logic App
4. Confirm custom table exists with matching schema

### Authentication Failures?

1. Verify webhook token matches between Key Vault and Atlassian
2. Check Managed Identity has "Key Vault Secrets User" role
3. Ensure header name is exactly: `X-Automation-Webhook-Token`

### DCE Ingestion Errors?

1. Verify Managed Identity has "Monitoring Metrics Publisher" role
2. Check DCE URL is correct (no trailing slashes)
3. Ensure DCR is linked to correct Log Analytics workspace

For detailed troubleshooting, see [README.md](README.md#monitoring-and-troubleshooting).

## Next Steps

1. **Create Detection Rules**: Set up Sentinel analytics rules for Atlassian alerts
2. **Configure Playbooks**: Automate response actions
3. **Set Up Dashboards**: Visualize Guard alerts in Sentinel
4. **Enable Notifications**: Configure email/Teams alerts for critical events

## Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/atlassian-guard-sentinel/issues)
- **Documentation**: [Full README](README.md)
- **Contributing**: [Contributing Guide](CONTRIBUTING.md)

## Cost Estimate

Typical monthly cost for 1,000 alerts: **$5-15 USD**

Breakdown:
- Logic App runs: ~$1
- Log Analytics ingestion: ~$2-10 (depends on data volume)
- Data retention: ~$1-3
- Key Vault: ~$0.50
- Other resources: Minimal

---

**Deployed successfully?** ⭐ Star the repo and share with your team!
