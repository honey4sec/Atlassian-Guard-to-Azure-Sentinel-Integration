#!/bin/bash

##############################################################################
# Atlassian Guard to Azure Sentinel Integration - Automated Deployment
# 
# This script automates the deployment of all required Azure resources
# for integrating Atlassian Guard alerts into Azure Sentinel.
#
# Prerequisites:
# - Azure CLI installed and logged in (az login)
# - Appropriate Azure permissions (Contributor or higher)
# - jq installed for JSON processing
##############################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_message "$BLUE" "=============================================="
print_message "$BLUE" "Atlassian Guard to Azure Sentinel Deployment"
print_message "$BLUE" "=============================================="
echo ""

# Check prerequisites
print_message "$YELLOW" "Checking prerequisites..."

if ! command -v az &> /dev/null; then
    print_message "$RED" "Error: Azure CLI is not installed. Please install it first."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    print_message "$RED" "Error: jq is not installed. Please install it first."
    exit 1
fi

if ! az account show &> /dev/null; then
    print_message "$RED" "Error: Not logged into Azure CLI. Please run 'az login' first."
    exit 1
fi

print_message "$GREEN" "✓ Prerequisites checked"
echo ""

# Configuration
print_message "$YELLOW" "Please provide the following configuration details:"
echo ""

read -p "Resource Group Name [rg-sentinel-log-ingest-eno]: " RESOURCE_GROUP
RESOURCE_GROUP=${RESOURCE_GROUP:-rg-sentinel-log-ingest-eno}

read -p "Azure Region [norwayeast]: " LOCATION
LOCATION=${LOCATION:-norwayeast}

read -p "Log Analytics Workspace Name [sentinel-workspace-prod]: " WORKSPACE_NAME
WORKSPACE_NAME=${WORKSPACE_NAME:-sentinel-workspace-prod}

read -p "Key Vault Name [kv-sentinel-guard-prod]: " KEYVAULT_NAME
KEYVAULT_NAME=${KEYVAULT_NAME:-kv-sentinel-guard-prod}

read -p "Logic App Name [la-atlassian-guard-ingest]: " LOGIC_APP_NAME
LOGIC_APP_NAME=${LOGIC_APP_NAME:-la-atlassian-guard-ingest}

read -p "DCE Name [dce-sentinel-prod-eno]: " DCE_NAME
DCE_NAME=${DCE_NAME:-dce-sentinel-prod-eno}

read -p "DCR Name [dcr-atlassian-guard]: " DCR_NAME
DCR_NAME=${DCR_NAME:-dcr-atlassian-guard}

echo ""
print_message "$YELLOW" "Configuration Summary:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  Workspace: $WORKSPACE_NAME"
echo "  Key Vault: $KEYVAULT_NAME"
echo "  Logic App: $LOGIC_APP_NAME"
echo "  DCE: $DCE_NAME"
echo "  DCR: $DCR_NAME"
echo ""

read -p "Proceed with deployment? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    print_message "$RED" "Deployment cancelled."
    exit 0
fi

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
print_message "$GREEN" "Using subscription: $SUBSCRIPTION_ID"
echo ""

##############################################################################
# STEP 1: Create Resource Group
##############################################################################
print_message "$BLUE" "Step 1: Creating Resource Group..."
if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    print_message "$YELLOW" "Resource group already exists. Skipping..."
else
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --output none
    print_message "$GREEN" "✓ Resource group created"
fi
echo ""

##############################################################################
# STEP 2: Create Log Analytics Workspace
##############################################################################
print_message "$BLUE" "Step 2: Creating Log Analytics Workspace..."
if az monitor log-analytics workspace show \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$WORKSPACE_NAME" &> /dev/null; then
    print_message "$YELLOW" "Workspace already exists. Skipping..."
else
    az monitor log-analytics workspace create \
        --resource-group "$RESOURCE_GROUP" \
        --workspace-name "$WORKSPACE_NAME" \
        --location "$LOCATION" \
        --output none
    print_message "$GREEN" "✓ Log Analytics workspace created"
fi

WORKSPACE_ID=$(az monitor log-analytics workspace show \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$WORKSPACE_NAME" \
    --query id -o tsv)

print_message "$GREEN" "Workspace ID: $WORKSPACE_ID"
echo ""

##############################################################################
# STEP 3: Create Custom Table
##############################################################################
print_message "$BLUE" "Step 3: Creating Custom Table..."
print_message "$YELLOW" "Note: Custom table creation requires manual setup in Azure Portal"
print_message "$YELLOW" "Please create table 'atlassian_guard_detect_CL' with the schema provided in README.md"
echo ""
read -p "Press Enter after creating the custom table..."
echo ""

##############################################################################
# STEP 4: Create Data Collection Endpoint
##############################################################################
print_message "$BLUE" "Step 4: Creating Data Collection Endpoint..."
if az monitor data-collection endpoint show \
    --name "$DCE_NAME" \
    --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    print_message "$YELLOW" "DCE already exists. Skipping..."
else
    az monitor data-collection endpoint create \
        --name "$DCE_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --public-network-access Enabled \
        --output none
    print_message "$GREEN" "✓ Data Collection Endpoint created"
fi

DCE_URL=$(az monitor data-collection endpoint show \
    --name "$DCE_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query logsIngestion.endpoint -o tsv)

print_message "$GREEN" "DCE URL: $DCE_URL"
echo ""

##############################################################################
# STEP 5: Create Data Collection Rule
##############################################################################
print_message "$BLUE" "Step 5: Creating Data Collection Rule..."

# Update DCR template with actual values
DCR_TEMPLATE=$(cat dcr-atlassian-guard.json)
DCR_TEMPLATE=$(echo "$DCR_TEMPLATE" | sed "s|YOUR_SUBSCRIPTION_ID|$SUBSCRIPTION_ID|g")
DCR_TEMPLATE=$(echo "$DCR_TEMPLATE" | sed "s|rg-sentinel-log-ingest-eno|$RESOURCE_GROUP|g")
DCR_TEMPLATE=$(echo "$DCR_TEMPLATE" | sed "s|dce-sentinel-prod-eno|$DCE_NAME|g")
DCR_TEMPLATE=$(echo "$DCR_TEMPLATE" | sed "s|sentinel-workspace-prod|$WORKSPACE_NAME|g")
DCR_TEMPLATE=$(echo "$DCR_TEMPLATE" | sed "s|norwayeast|$LOCATION|g")

echo "$DCR_TEMPLATE" > /tmp/dcr-configured.json

if az monitor data-collection rule show \
    --name "$DCR_NAME" \
    --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    print_message "$YELLOW" "DCR already exists. Skipping..."
else
    az monitor data-collection rule create \
        --name "$DCR_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --rule-file /tmp/dcr-configured.json \
        --output none
    print_message "$GREEN" "✓ Data Collection Rule created"
fi

DCR_IMMUTABLE_ID=$(az monitor data-collection rule show \
    --name "$DCR_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query immutableId -o tsv)

print_message "$GREEN" "DCR Immutable ID: $DCR_IMMUTABLE_ID"
echo ""

##############################################################################
# STEP 6: Create Key Vault and Store Webhook Token
##############################################################################
print_message "$BLUE" "Step 6: Creating Key Vault..."
if az keyvault show --name "$KEYVAULT_NAME" &> /dev/null; then
    print_message "$YELLOW" "Key Vault already exists. Skipping..."
else
    az keyvault create \
        --name "$KEYVAULT_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --enable-rbac-authorization true \
        --output none
    print_message "$GREEN" "✓ Key Vault created"
fi

# Generate webhook token
print_message "$YELLOW" "Generating webhook token..."
WEBHOOK_TOKEN=$(openssl rand -base64 32)

# Store token in Key Vault
az keyvault secret set \
    --vault-name "$KEYVAULT_NAME" \
    --name "Atlassian-Guard-Detect-Webhook" \
    --value "$WEBHOOK_TOKEN" \
    --output none

print_message "$GREEN" "✓ Webhook token stored in Key Vault"
print_message "$YELLOW" "IMPORTANT: Save this token for Atlassian configuration:"
print_message "$GREEN" "$WEBHOOK_TOKEN"
echo ""

##############################################################################
# STEP 7: Deploy Logic App
##############################################################################
print_message "$BLUE" "Step 7: Deploying Logic App..."

# Update Logic App definition with actual values
LOGIC_APP_DEF=$(cat logic-app-definition.json)
LOGIC_APP_DEF=$(echo "$LOGIC_APP_DEF" | sed "s|YOUR-DCE-ENDPOINT|${DCE_URL#https://}|g")
LOGIC_APP_DEF=$(echo "$LOGIC_APP_DEF" | sed "s|dcr-YOUR-DCR-IMMUTABLE-ID|$DCR_IMMUTABLE_ID|g")
LOGIC_APP_DEF=$(echo "$LOGIC_APP_DEF" | sed "s|YOUR_SUBSCRIPTION_ID|$SUBSCRIPTION_ID|g")
LOGIC_APP_DEF=$(echo "$LOGIC_APP_DEF" | sed "s|YOUR_RESOURCE_GROUP|$RESOURCE_GROUP|g")
LOGIC_APP_DEF=$(echo "$LOGIC_APP_DEF" | sed "s|YOUR_REGION|$LOCATION|g")

echo "$LOGIC_APP_DEF" > /tmp/logic-app-configured.json

if az logic workflow show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$LOGIC_APP_NAME" &> /dev/null; then
    print_message "$YELLOW" "Logic App already exists. Updating..."
    az logic workflow update \
        --resource-group "$RESOURCE_GROUP" \
        --name "$LOGIC_APP_NAME" \
        --definition /tmp/logic-app-configured.json \
        --output none
else
    az logic workflow create \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --name "$LOGIC_APP_NAME" \
        --definition /tmp/logic-app-configured.json \
        --output none
fi

print_message "$GREEN" "✓ Logic App deployed"
echo ""

##############################################################################
# STEP 8: Enable Managed Identity and Assign Permissions
##############################################################################
print_message "$BLUE" "Step 8: Configuring Managed Identity..."

# Enable managed identity
az logic workflow identity assign \
    --resource-group "$RESOURCE_GROUP" \
    --name "$LOGIC_APP_NAME" \
    --output none

PRINCIPAL_ID=$(az logic workflow identity show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$LOGIC_APP_NAME" \
    --query principalId -o tsv)

print_message "$GREEN" "Managed Identity Principal ID: $PRINCIPAL_ID"

# Wait for identity propagation
print_message "$YELLOW" "Waiting for identity propagation..."
sleep 30

# Assign Key Vault permissions
print_message "$YELLOW" "Assigning Key Vault Secrets User role..."
az role assignment create \
    --assignee "$PRINCIPAL_ID" \
    --role "Key Vault Secrets User" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEYVAULT_NAME" \
    --output none

# Assign DCR permissions
print_message "$YELLOW" "Assigning Monitoring Metrics Publisher role..."
az role assignment create \
    --assignee "$PRINCIPAL_ID" \
    --role "Monitoring Metrics Publisher" \
    --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Insights/dataCollectionRules/$DCR_NAME" \
    --output none

print_message "$GREEN" "✓ Permissions assigned"
echo ""

##############################################################################
# STEP 9: Get Webhook URL
##############################################################################
print_message "$BLUE" "Step 9: Retrieving Webhook URL..."

WEBHOOK_URL=$(az rest \
    --method post \
    --uri "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Logic/workflows/$LOGIC_APP_NAME/triggers/Atlassian_guard_webhook/listCallbackUrl?api-version=2016-06-01" \
    --query value -o tsv)

print_message "$GREEN" "✓ Webhook URL retrieved"
echo ""

##############################################################################
# DEPLOYMENT COMPLETE
##############################################################################
print_message "$GREEN" "=============================================="
print_message "$GREEN" "Deployment Complete!"
print_message "$GREEN" "=============================================="
echo ""

print_message "$BLUE" "Configuration Details:"
echo ""
print_message "$YELLOW" "Webhook URL (use in Atlassian Guard):"
print_message "$GREEN" "$WEBHOOK_URL"
echo ""
print_message "$YELLOW" "Webhook Token (use in Atlassian Guard header):"
print_message "$GREEN" "$WEBHOOK_TOKEN"
echo ""

print_message "$BLUE" "Next Steps:"
echo "1. Configure webhook in Atlassian Guard:"
echo "   - URL: $WEBHOOK_URL"
echo "   - Header: X-Automation-Webhook-Token: $WEBHOOK_TOKEN"
echo ""
echo "2. Test the integration using the test payload in README.md"
echo ""
echo "3. Verify data ingestion in Azure Sentinel:"
echo "   atlassian_guard_detect_CL | take 10"
echo ""

print_message "$YELLOW" "Save these credentials securely!"
echo ""

# Cleanup temporary files
rm -f /tmp/dcr-configured.json /tmp/logic-app-configured.json

print_message "$GREEN" "Deployment script completed successfully!"
