# Atlassian Guard to Azure Sentinel Integration

This Azure Logic App enables automated ingestion of Atlassian Guard security alerts into Azure Sentinel, providing centralized security monitoring and incident response capabilities.

## Overview

This solution:
- Receives webhook notifications from Atlassian Guard Detect
- Validates incoming requests using a secure token
- Transforms alert data into a standardized format
- Ingests data into Azure Sentinel via Data Collection Endpoint (DCE)
- Provides error handling and retry mechanisms

## Architecture

```
Atlassian Guard → Webhook → Logic App → Azure Monitor DCE → Log Analytics Workspace → Azure Sentinel
```

## Prerequisites

Before you begin, ensure you have:

- **Azure Subscription** with appropriate permissions
- **Azure Sentinel** workspace deployed
- **Atlassian Guard** (requires Enterprise plan)
- **Permissions**:
  - Logic App Contributor (or higher) in Azure
  - Key Vault Administrator or Key Vault Secrets Officer
  - Monitoring Metrics Publisher role on the DCE
  - Atlassian Organization Admin access

## Architecture Components

### Required Azure Resources

1. **Resource Group** - Container for all resources
2. **Log Analytics Workspace** - Where Sentinel is enabled
3. **Data Collection Endpoint (DCE)** - Ingestion endpoint
4. **Data Collection Rule (DCR)** - Defines data transformation and routing
5. **Custom Table** - Log Analytics table for Atlassian Guard data
6. **Key Vault** - Secure storage for webhook token
7. **Logic App** - Webhook receiver and data processor
8. **Managed Identity** - For secure authentication

---

## Setup Instructions

### Step 1: Create Resource Group

```bash
az group create \
  --name rg-sentinel-log-ingest-eno \
  --location norwayeast
```

### Step 2: Set Up Log Analytics Workspace

If you don't already have a Log Analytics workspace with Sentinel enabled:

```bash
# Create Log Analytics Workspace
az monitor log-analytics workspace create \
  --resource-group rg-sentinel-log-ingest-eno \
  --workspace-name sentinel-workspace-prod \
  --location norwayeast

# Get workspace ID
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group rg-sentinel-log-ingest-eno \
  --workspace-name sentinel-workspace-prod \
  --query customerId -o tsv)
```

Enable Azure Sentinel on the workspace through the Azure Portal:
1. Navigate to **Azure Sentinel**
2. Click **+ Add**
3. Select your Log Analytics workspace

### Step 3: Create Custom Table in Log Analytics

Create a custom table to store Atlassian Guard alerts:

1. Navigate to your **Log Analytics Workspace** in Azure Portal
2. Go to **Tables** → **Create** → **New custom log (DCR-based)**
3. Create a table named: `atlassian_guard_detect_CL`
4. Define the schema with these columns:

| Column Name | Type | Description |
|-------------|------|-------------|
| TimeGenerated | datetime | Alert creation timestamp |
| AlertId | string | Unique alert identifier |
| AlertTitle | string | Alert title |
| AlertDetailURL | string | URL to alert details |
| DetectionTime | long | Detection timestamp (epoch) |
| ActivityAction | string | Action that triggered the alert |
| ActivitySubjectAri | string | Subject ARI |
| ActivitySubjectContainerAri | string | Container ARI |
| ActivitySubjectAti | string | Subject ATI |
| ActivityTimeStart | string | Activity start time |
| ActivityTimeEnd | string | Activity end time |
| ActorAccountId | string | Actor's account ID |
| ActorName | string | Actor's name |
| ActorUrl | string | URL to actor profile |
| ActorSessions | dynamic | Session information (JSON) |
| AlertProduct | string | Product name (e.g., Confluence) |
| AlertSite | string | Atlassian site |
| AlertUrl | string | URL to alert in Atlassian Guard |
| EventId | string | Event identifier |
| EventType | string | Event type |
| Timestamp | long | Event timestamp (epoch) |
| WorkspaceCloudId | string | Workspace cloud ID |
| WorkspaceId | string | Workspace ID |
| WorkspaceOrgId | string | Organization ID |

### Step 4: Create Data Collection Endpoint (DCE)

```bash
az monitor data-collection endpoint create \
  --name dce-sentinel-prod-eno \
  --resource-group rg-sentinel-log-ingest-eno \
  --location norwayeast \
  --public-network-access Enabled
```

Get the DCE endpoint URL:

```bash
DCE_URL=$(az monitor data-collection endpoint show \
  --name dce-sentinel-prod-eno \
  --resource-group rg-sentinel-log-ingest-eno \
  --query logsIngestion.endpoint -o tsv)

echo "DCE URL: $DCE_URL"
```

### Step 5: Create Data Collection Rule (DCR)

Create a file named `dcr-atlassian-guard.json`:

```json
{
  "location": "norwayeast",
  "properties": {
    "dataCollectionEndpointId": "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-sentinel-log-ingest-eno/providers/Microsoft.Insights/dataCollectionEndpoints/dce-sentinel-prod-eno",
    "streamDeclarations": {
      "Custom-atlassian_guard_detect_CL": {
        "columns": [
          {"name": "TimeGenerated", "type": "datetime"},
          {"name": "AlertId", "type": "string"},
          {"name": "AlertTitle", "type": "string"},
          {"name": "AlertDetailURL", "type": "string"},
          {"name": "DetectionTime", "type": "long"},
          {"name": "ActivityAction", "type": "string"},
          {"name": "ActivitySubjectAri", "type": "string"},
          {"name": "ActivitySubjectContainerAri", "type": "string"},
          {"name": "ActivitySubjectAti", "type": "string"},
          {"name": "ActivityTimeStart", "type": "string"},
          {"name": "ActivityTimeEnd", "type": "string"},
          {"name": "ActorAccountId", "type": "string"},
          {"name": "ActorName", "type": "string"},
          {"name": "ActorUrl", "type": "string"},
          {"name": "ActorSessions", "type": "dynamic"},
          {"name": "AlertProduct", "type": "string"},
          {"name": "AlertSite", "type": "string"},
          {"name": "AlertUrl", "type": "string"},
          {"name": "EventId", "type": "string"},
          {"name": "EventType", "type": "string"},
          {"name": "Timestamp", "type": "long"},
          {"name": "WorkspaceCloudId", "type": "string"},
          {"name": "WorkspaceId", "type": "string"},
          {"name": "WorkspaceOrgId", "type": "string"}
        ]
      }
    },
    "destinations": {
      "logAnalytics": [
        {
          "workspaceResourceId": "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-sentinel-log-ingest-eno/providers/Microsoft.OperationalInsights/workspaces/sentinel-workspace-prod",
          "name": "sentinel-workspace"
        }
      ]
    },
    "dataFlows": [
      {
        "streams": ["Custom-atlassian_guard_detect_CL"],
        "destinations": ["sentinel-workspace"],
        "transformKql": "source",
        "outputStream": "Custom-atlassian_guard_detect_CL"
      }
    ]
  }
}
```

Deploy the DCR:

```bash
az monitor data-collection rule create \
  --name dcr-atlassian-guard \
  --resource-group rg-sentinel-log-ingest-eno \
  --location norwayeast \
  --rule-file dcr-atlassian-guard.json
```

Get the DCR Immutable ID:

```bash
DCR_IMMUTABLE_ID=$(az monitor data-collection rule show \
  --name dcr-atlassian-guard \
  --resource-group rg-sentinel-log-ingest-eno \
  --query immutableId -o tsv)

echo "DCR Immutable ID: $DCR_IMMUTABLE_ID"
```

### Step 6: Create Azure Key Vault

```bash
# Create Key Vault
az keyvault create \
  --name kv-sentinel-guard-prod \
  --resource-group rg-sentinel-log-ingest-eno \
  --location norwayeast \
  --enable-rbac-authorization true

# Generate a secure webhook token
WEBHOOK_TOKEN=$(openssl rand -base64 32)

# Store the token in Key Vault
az keyvault secret set \
  --vault-name kv-sentinel-guard-prod \
  --name Atlassian-Guard-Detect-Webhook \
  --value "$WEBHOOK_TOKEN"

echo "Webhook Token (save this for Atlassian configuration): $WEBHOOK_TOKEN"
```

### Step 7: Deploy Logic App

1. **Create Logic App**:

```bash
az logic workflow create \
  --resource-group rg-sentinel-log-ingest-eno \
  --location norwayeast \
  --name la-atlassian-guard-ingest \
  --definition @logic-app-definition.json
```

2. **Enable Managed Identity**:

```bash
az logic workflow identity assign \
  --resource-group rg-sentinel-log-ingest-eno \
  --name la-atlassian-guard-ingest
```

3. **Get the Managed Identity Principal ID**:

```bash
PRINCIPAL_ID=$(az logic workflow identity show \
  --resource-group rg-sentinel-log-ingest-eno \
  --name la-atlassian-guard-ingest \
  --query principalId -o tsv)

echo "Principal ID: $PRINCIPAL_ID"
```

### Step 8: Assign Required Permissions

#### Grant Key Vault Permissions:

```bash
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-sentinel-log-ingest-eno/providers/Microsoft.KeyVault/vaults/kv-sentinel-guard-prod
```

#### Grant DCR Permissions:

```bash
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Monitoring Metrics Publisher" \
  --scope /subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/rg-sentinel-log-ingest-eno/providers/Microsoft.Insights/dataCollectionRules/dcr-atlassian-guard
```

### Step 9: Update Logic App Variables

Update the Logic App definition with your specific values:

1. Open the Logic App in Azure Portal
2. Go to **Logic app designer**
3. Edit the **Initialize variables** action
4. Update these variables:
   - `DCELogsIngestionURL`: Your DCE URL from Step 4
   - `DCRImmutableID`: Your DCR Immutable ID from Step 5
   - `TableName`: `atlassian_guard_detect_CL`

### Step 10: Get Logic App Webhook URL

```bash
az logic workflow show \
  --resource-group rg-sentinel-log-ingest-eno \
  --name la-atlassian-guard-ingest \
  --query "accessEndpoint" -o tsv
```

Or get it from the Azure Portal:
1. Open the Logic App
2. Go to **Logic app designer**
3. Expand the trigger **Atlassian_guard_webhook**
4. Copy the **HTTP POST URL**

---

## Atlassian Guard Configuration

### Step 11: Configure Webhook in Atlassian Guard

1. Log in to **Atlassian Admin** (admin.atlassian.com)
2. Navigate to **Security** → **Atlassian Guard**
3. Go to **Detect** → **Settings** → **Integrations**
4. Click **Add integration** → **Generic Webhook**
5. Configure the webhook:
   - **Name**: Azure Sentinel Integration
   - **Webhook URL**: Your Logic App webhook URL from Step 10
   - **Custom Headers**:
     - Header Name: `X-Automation-Webhook-Token`
     - Header Value: Your webhook token from Step 6
6. Select alert types to forward
7. Click **Save**

### Step 12: Test the Integration

#### Option 1: Test from Atlassian Guard

If your organization has real alerts, they'll automatically flow to Sentinel.

#### Option 2: Manual Test with Sample Payload

Send a test request to your Logic App:

```bash
curl -X POST "YOUR_LOGIC_APP_URL" \
  -H "Content-Type: application/json" \
  -H "X-Automation-Webhook-Token: YOUR_WEBHOOK_TOKEN" \
  -d '{
    "alertId": "test-alert-123",
    "alertTitle": "Test Alert",
    "alertDetailURL": "https://admin.atlassian.com/guard/alerts/test",
    "detectionTime": 1234567890,
    "activity": {
      "action": "test.action",
      "subject": {
        "ari": "ari:cloud:confluence::page/123",
        "containerAri": "ari:cloud:confluence::space/ABC",
        "ati": "confluence:page"
      },
      "time": {
        "start": "2024-01-01T00:00:00Z",
        "end": "2024-01-01T01:00:00Z"
      }
    },
    "actor": {
      "accountId": "test-account-id",
      "name": "Test User",
      "sessions": [
        {
          "ipAddress": "192.168.1.1",
          "userAgent": "Mozilla/5.0",
          "loginTime": "2024-01-01T00:00:00Z",
          "lastActiveTime": "2024-01-01T01:00:00Z"
        }
      ],
      "url": "https://admin.atlassian.com/users/test"
    },
    "alert": {
      "created": "2024-01-01T00:00:00Z",
      "id": "alert-123",
      "product": "confluence",
      "site": "yoursite",
      "title": "Test Alert",
      "url": "https://admin.atlassian.com/guard/alerts/123"
    },
    "id": "event-123",
    "timestamp": 1234567890,
    "type": "guard.detect.alert",
    "workspace": {
      "cloudId": "cloud-id-123",
      "id": "workspace-123",
      "orgId": "org-123"
    }
  }'
```

### Step 13: Verify Data Ingestion

Wait 5-10 minutes for data to appear, then query in Azure Sentinel:

```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(1h)
| order by TimeGenerated desc
| take 10
```

---

## Monitoring and Troubleshooting

### View Logic App Run History

```bash
az logic workflow run list \
  --resource-group rg-sentinel-log-ingest-eno \
  --name la-atlassian-guard-ingest
```

Or in Azure Portal:
1. Navigate to your Logic App
2. Click **Overview** → **Runs history**
3. Click on a run to see detailed execution

### Common Issues

#### 1. Authentication Failures
**Error**: `401 Unauthorized`

**Solution**: 
- Verify the webhook token matches between Key Vault and Atlassian
- Check Key Vault permissions for the Managed Identity

#### 2. DCE Ingestion Failures
**Error**: `403 Forbidden` or `500 Internal Server Error`

**Solution**:
- Verify Managed Identity has "Monitoring Metrics Publisher" role on DCR
- Check DCR Immutable ID is correct
- Verify DCE URL is correct

#### 3. Missing Data in Sentinel
**Solution**:
- Check Logic App run history for errors
- Verify DCR transformation KQL is correct
- Ensure custom table exists and schema matches

#### 4. Schema Mismatch
**Error**: Data not appearing in Log Analytics

**Solution**:
- Verify all column names and types match between DCR and custom table
- Check for case sensitivity in field names

### View Logs

Query Logic App execution logs:

```kql
AzureDiagnostics
| where ResourceType == "WORKFLOWS"
| where resource_workflowName_s == "la-atlassian-guard-ingest"
| order by TimeGenerated desc
```

---

## Security Best Practices

1. **Restrict Network Access**: Configure DCE network rules to only accept traffic from your Logic App
2. **Rotate Secrets**: Regularly rotate the webhook token in Key Vault
3. **Monitor Access**: Enable diagnostic logging on Key Vault and DCE
4. **Use Private Endpoints**: For production, consider using Private Endpoints for Key Vault and DCE
5. **Least Privilege**: Ensure Managed Identity only has required permissions

---

## Sample Sentinel Queries

### Recent Alerts

```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(24h)
| project TimeGenerated, AlertTitle, ActorName, AlertProduct, AlertSite
| order by TimeGenerated desc
```

### Alerts by Actor

```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(7d)
| summarize AlertCount = count() by ActorName, ActorAccountId
| order by AlertCount desc
```

### Alerts by Type

```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(30d)
| summarize Count = count() by AlertTitle, AlertProduct
| order by Count desc
```

### Session Analysis

```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(7d)
| extend Sessions = parse_json(ActorSessions)
| mv-expand Sessions
| extend IPAddress = tostring(Sessions.ipAddress)
| summarize count() by IPAddress, ActorName
| order by count_ desc
```

---

## Costs

Estimated monthly costs (may vary by region):

- **Logic App**: ~$0.01 per workflow run + $0.000016 per action
- **Key Vault**: ~$0.03 per 10,000 operations
- **Log Analytics Ingestion**: ~$2.30 per GB
- **Data Collection Rules**: No additional cost
- **Data Retention**: Variable based on retention settings

**Example**: 1,000 alerts/month ≈ $5-15/month

---

## Maintenance

### Regular Tasks

- **Monthly**: Review run history for errors
- **Quarterly**: Rotate webhook token
- **Yearly**: Review and optimize data retention policies

### Updating the Logic App

To update the Logic App definition:

```bash
az logic workflow update \
  --resource-group rg-sentinel-log-ingest-eno \
  --name la-atlassian-guard-ingest \
  --definition @updated-definition.json
```

---

## Cleanup

To remove all resources:

```bash
az group delete \
  --name rg-sentinel-log-ingest-eno \
  --yes --no-wait
```

---

## Support and Contributing

### Issues
Please report issues via the GitHub Issues tab.

### Contributing
Pull requests are welcome! Please ensure:
- Clear description of changes
- Updated documentation
- Tested in a dev environment

---

## License

MIT License - See LICENSE file for details

---

## Additional Resources

- [Azure Logic Apps Documentation](https://docs.microsoft.com/azure/logic-apps/)
- [Azure Sentinel Documentation](https://docs.microsoft.com/azure/sentinel/)
- [Atlassian Guard Documentation](https://support.atlassian.com/security-and-access-policies/docs/get-started-with-atlassian-guard/)
- [Azure Monitor Data Collection](https://docs.microsoft.com/azure/azure-monitor/essentials/data-collection-endpoint-overview)

---

## Changelog

### Version 1.0.0 (Current)
- Initial release
- Support for Atlassian Guard Detect alerts
- Azure Sentinel integration via DCE
- Secure authentication with Key Vault
- Comprehensive error handling

---

**Last Updated**: October 2025
