# Atlassian Guard to Azure Sentinel Integration - File Index

This repository contains all necessary files for deploying the Atlassian Guard to Azure Sentinel integration.

## 📁 Repository Structure

### Documentation Files

#### **README.md** (17 KB)
The main documentation file containing:
- Complete overview of the solution
- Detailed step-by-step setup instructions (13 steps)
- Architecture explanation
- Troubleshooting guide
- Security best practices
- Sample KQL queries
- Cost estimates
- Maintenance guidelines

**Use this for**: Complete reference and manual deployment

---

#### **QUICKSTART.md** (5 KB)
Simplified quick start guide containing:
- 30-minute deployment overview
- Prerequisites checklist
- Automated deployment instructions
- Basic configuration steps
- Common commands
- Quick troubleshooting tips

**Use this for**: Fast deployment and getting started quickly

---

#### **DEPLOYMENT-CHECKLIST.md** (6 KB)
Comprehensive deployment checklist with:
- Pre-deployment requirements
- Step-by-step verification items
- Testing procedures
- Security validation
- Post-deployment tasks
- Sign-off section

**Use this for**: Ensuring nothing is missed during deployment

---

#### **SENTINEL-QUERIES.md** (10 KB)
Collection of ready-to-use KQL queries including:
- Basic alert queries
- User activity analysis
- Network and IP analysis
- Session analysis
- Time-based analysis
- Anomaly detection queries
- Threat hunting queries
- Performance optimization tips

**Use this for**: Querying and analyzing data in Azure Sentinel

---

#### **CONTRIBUTING.md** (4 KB)
Contribution guidelines covering:
- How to report issues
- Submitting changes
- Development guidelines
- Testing checklist
- Pull request process
- Areas for contribution
- Code of conduct

**Use this for**: Contributing to the project

---

#### **LICENSE** (1 KB)
MIT License file

**Use this for**: Understanding usage rights

---

### Configuration Files

#### **logic-app-definition.json** (23 KB)
Complete Logic App workflow definition including:
- HTTP webhook trigger
- Key Vault integration for token validation
- JSON parsing and validation
- Data transformation logic
- DCE ingestion with retry logic
- Comprehensive error handling
- Managed Service Identity authentication

**Use this for**: Deploying the Logic App

**Required customization:**
- Replace `YOUR-DCE-ENDPOINT` with your DCE URL
- Replace `dcr-YOUR-DCR-IMMUTABLE-ID` with your DCR Immutable ID
- Replace `YOUR_SUBSCRIPTION_ID` with your subscription ID
- Replace `YOUR_RESOURCE_GROUP` with your resource group name
- Replace `YOUR_REGION` with your Azure region

---

#### **dcr-atlassian-guard.json** (3 KB)
Data Collection Rule definition including:
- Stream declaration with 24 columns
- Column types and names
- Destination configuration
- Data flow transformation rules

**Use this for**: Creating the Data Collection Rule

**Required customization:**
- Replace `YOUR_SUBSCRIPTION_ID` with your subscription ID
- Update resource group and workspace names
- Update DCE resource path
- Update region/location

---

#### **test-payload.json** (2 KB)
Sample webhook payload for testing including:
- All required fields
- Realistic test data
- Properly formatted JSON structure

**Use this for**: Testing the webhook integration

**Usage:**
```bash
curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -H "X-Automation-Webhook-Token: YOUR_TOKEN" \
  -d @test-payload.json
```

---

#### **.gitignore** (Not listed)
Standard .gitignore file for:
- Azure credentials
- Secrets and keys
- Logs and temporary files
- IDE configurations
- OS-specific files

**Use this for**: Protecting sensitive data in version control

---

### Deployment Scripts

#### **deploy.sh** (15 KB)
Automated deployment script that:
- Validates prerequisites (Azure CLI, jq)
- Creates all Azure resources
- Configures permissions
- Generates and stores webhook token
- Updates configuration files
- Deploys Logic App
- Assigns RBAC roles
- Retrieves webhook URL

**Use this for**: Automated end-to-end deployment

**Prerequisites:**
- Azure CLI installed
- Logged into Azure (`az login`)
- jq installed
- Bash shell environment

**Usage:**
```bash
chmod +x deploy.sh
./deploy.sh
```

---

### Visual Assets

#### **architecture-diagram.mmd** (1 KB)
Mermaid diagram source code showing:
- Complete architecture flow
- Azure resource relationships
- Data flow from Atlassian to Sentinel
- Color-coded components

**Use this for**: Understanding the architecture visually

**To render:**
- Use Mermaid Live Editor: https://mermaid.live/
- Use in GitHub (automatically renders)
- Use in documentation tools supporting Mermaid

---

## 🚀 Quick Start Paths

### Path 1: Automated Deployment (Recommended)
1. Read: `QUICKSTART.md`
2. Run: `deploy.sh`
3. Configure: Atlassian Guard webhook
4. Test: Using `test-payload.json`
5. Query: Using queries from `SENTINEL-QUERIES.md`

### Path 2: Manual Deployment (Full Control)
1. Read: `README.md` (complete guide)
2. Follow: Step-by-step instructions
3. Use: `DEPLOYMENT-CHECKLIST.md` to track progress
4. Deploy: Using `logic-app-definition.json` and `dcr-atlassian-guard.json`
5. Test: Using `test-payload.json`

### Path 3: Understanding First (Learning)
1. Read: `README.md` (overview and architecture)
2. View: `architecture-diagram.mmd`
3. Review: `logic-app-definition.json` (understand the logic)
4. Explore: `SENTINEL-QUERIES.md` (understand the data)
5. Deploy: Using either automated or manual path

---

## 📊 File Summary

| File | Size | Type | Required Customization |
|------|------|------|------------------------|
| README.md | 17 KB | Documentation | None |
| QUICKSTART.md | 5 KB | Documentation | None |
| DEPLOYMENT-CHECKLIST.md | 6 KB | Documentation | None |
| SENTINEL-QUERIES.md | 10 KB | Documentation | None |
| CONTRIBUTING.md | 4 KB | Documentation | None |
| LICENSE | 1 KB | Legal | None |
| logic-app-definition.json | 23 KB | Configuration | Yes - 5 values |
| dcr-atlassian-guard.json | 3 KB | Configuration | Yes - 4 values |
| test-payload.json | 2 KB | Testing | Optional |
| deploy.sh | 15 KB | Script | None (interactive) |
| architecture-diagram.mmd | 1 KB | Diagram | None |
| .gitignore | <1 KB | Config | None |

**Total Size**: ~87 KB

---

## 🔧 Customization Required

### Before Manual Deployment

1. **logic-app-definition.json** (5 replacements)
   - `YOUR-DCE-ENDPOINT`
   - `dcr-YOUR-DCR-IMMUTABLE-ID`
   - `YOUR_SUBSCRIPTION_ID` (3 times)
   - `YOUR_RESOURCE_GROUP`
   - `YOUR_REGION`

2. **dcr-atlassian-guard.json** (4 replacements)
   - `YOUR_SUBSCRIPTION_ID` (2 times)
   - Resource group names
   - Workspace names
   - Region/location

### Using Automated Script

No manual customization needed - the `deploy.sh` script will:
- Prompt for configuration values
- Update files automatically
- Deploy resources with correct values

---

## 📋 Deployment Order

If deploying manually, follow this order:

1. **Prerequisites**: Verify Azure CLI, permissions
2. **Resource Group**: Create container
3. **Log Analytics**: Create workspace, enable Sentinel
4. **Custom Table**: Create schema in workspace
5. **DCE**: Create endpoint, get URL
6. **DCR**: Create rule with `dcr-atlassian-guard.json`
7. **Key Vault**: Create vault, store token
8. **Logic App**: Deploy with `logic-app-definition.json`
9. **Managed Identity**: Enable and assign roles
10. **Testing**: Use `test-payload.json`
11. **Atlassian**: Configure webhook
12. **Validation**: Query using `SENTINEL-QUERIES.md`

---

## 🆘 Getting Help

1. **Deployment Issues**: See README.md → Troubleshooting section
2. **Query Help**: See SENTINEL-QUERIES.md
3. **Quick Reference**: See QUICKSTART.md
4. **Checklist**: Use DEPLOYMENT-CHECKLIST.md
5. **Contributing**: See CONTRIBUTING.md
6. **GitHub Issues**: Report problems or ask questions

---

## 📝 Notes

- All files are text-based for easy version control
- JSON files use consistent formatting
- Scripts include extensive error handling
- Documentation includes real-world examples
- Queries are tested and production-ready

---

## ✅ Quality Checklist

- [x] Complete documentation
- [x] Automated deployment script
- [x] Manual deployment guide
- [x] Testing procedures
- [x] Sample queries
- [x] Architecture diagram
- [x] Security best practices
- [x] Troubleshooting guide
- [x] Contribution guidelines
- [x] License included

---

**Last Updated**: October 2025
**Version**: 1.0.0
**Maintained By**: Community
**License**: MIT
