# Deployment Checklist

Use this checklist to ensure all steps are completed correctly.

## Pre-Deployment

- [ ] Azure CLI installed and configured
- [ ] Logged into Azure (`az login`)
- [ ] Correct subscription selected (`az account set`)
- [ ] Contributor or higher role on subscription
- [ ] Atlassian organization with Guard Enterprise
- [ ] Organization Admin access in Atlassian
- [ ] `jq` installed (for automated script)

## Azure Resources

### Resource Group
- [ ] Resource group created
- [ ] Location selected (e.g., norwayeast)
- [ ] Resource group name documented

### Log Analytics Workspace
- [ ] Workspace created
- [ ] Workspace ID obtained
- [ ] Azure Sentinel enabled on workspace

### Custom Table
- [ ] Table `atlassian_guard_detect_CL` created
- [ ] Schema matches DCR definition
- [ ] All 24 columns defined correctly
- [ ] Data types match specification

### Data Collection Endpoint (DCE)
- [ ] DCE created
- [ ] Public network access enabled
- [ ] DCE URL obtained and documented
- [ ] DCE linked to correct region

### Data Collection Rule (DCR)
- [ ] DCR created with correct schema
- [ ] DCR linked to DCE
- [ ] DCR linked to Log Analytics workspace
- [ ] DCR Immutable ID obtained
- [ ] Stream declaration matches table schema
- [ ] Transform KQL is set to "source"

### Key Vault
- [ ] Key Vault created
- [ ] RBAC authorization enabled
- [ ] Webhook token generated (32+ characters)
- [ ] Token stored as secret: `Atlassian-Guard-Detect-Webhook`
- [ ] Token documented securely (NOT in git)

### Logic App
- [ ] Logic App created
- [ ] Definition uploaded successfully
- [ ] Variables updated:
  - [ ] `DCELogsIngestionURL` = DCE URL
  - [ ] `DCRImmutableID` = DCR Immutable ID
  - [ ] `TableName` = atlassian_guard_detect_CL
- [ ] Key Vault connection configured
- [ ] Workflow enabled

### Managed Identity
- [ ] Managed Identity enabled on Logic App
- [ ] Principal ID obtained
- [ ] Key Vault Secrets User role assigned
- [ ] Monitoring Metrics Publisher role assigned to DCR
- [ ] Permissions propagated (wait 30 seconds)

### Webhook Configuration
- [ ] Logic App webhook URL obtained
- [ ] URL includes trigger name and SAS token
- [ ] URL documented securely (NOT in git)

## Atlassian Configuration

- [ ] Logged into Atlassian Admin
- [ ] Navigated to Security → Guard → Detect
- [ ] Accessed Settings → Integrations
- [ ] Created Generic Webhook integration
- [ ] Integration name set: "Azure Sentinel"
- [ ] Webhook URL configured
- [ ] Custom header added: `X-Automation-Webhook-Token`
- [ ] Token value matches Key Vault secret
- [ ] Alert types selected
- [ ] Integration saved and enabled

## Testing

### Unit Testing
- [ ] Sent test payload using curl
- [ ] Logic App run appeared in history
- [ ] Run status: Succeeded
- [ ] No authentication errors
- [ ] No parsing errors
- [ ] DCE ingestion successful (200/204 response)

### Integration Testing
- [ ] Waited 5-10 minutes for data propagation
- [ ] Queried Log Analytics workspace
- [ ] Data visible in `atlassian_guard_detect_CL` table
- [ ] All fields populated correctly
- [ ] TimeGenerated field has correct timezone
- [ ] ActorSessions field parsed as JSON (dynamic type)

### End-to-End Testing
- [ ] Triggered real alert in Atlassian (if possible)
- [ ] Alert received by webhook within 5 minutes
- [ ] Alert data ingested correctly
- [ ] Data queryable in Sentinel
- [ ] All expected fields present

## Monitoring Setup

- [ ] Logic App diagnostic logging enabled
- [ ] DCE diagnostic logging enabled
- [ ] Key Vault audit logging enabled
- [ ] Alert created for Logic App failures
- [ ] Alert created for DCE ingestion failures
- [ ] Dashboard created for alert metrics

## Documentation

- [ ] Webhook URL documented in secure location
- [ ] Webhook token documented in password manager
- [ ] DCR Immutable ID documented
- [ ] DCE URL documented
- [ ] Runbook created for troubleshooting
- [ ] Team members notified of new integration
- [ ] Knowledge base article created (if applicable)

## Security Validation

- [ ] Webhook token is strong (32+ characters)
- [ ] Token not stored in Logic App (only in Key Vault)
- [ ] Managed Identity used (no service principals)
- [ ] Least privilege permissions verified
- [ ] No sensitive data in Logic App run history
- [ ] Secure data properties configured correctly
- [ ] Network access restrictions configured (optional)

## Post-Deployment

- [ ] Integration running for 24 hours without errors
- [ ] Data volume matches expectations
- [ ] No authentication failures
- [ ] No data ingestion errors
- [ ] Logic App runs completing in < 30 seconds
- [ ] Cost within expected range
- [ ] Backup of configuration files created

## Sentinel Configuration

- [ ] Created detection/analytics rules for Guard alerts
- [ ] Configured incident creation
- [ ] Set up automation playbooks (optional)
- [ ] Created workbook/dashboard for visualization
- [ ] Configured email notifications (optional)
- [ ] Integrated with ticketing system (optional)

## Maintenance Plan

- [ ] Schedule for token rotation (quarterly)
- [ ] Review process for Logic App updates
- [ ] Monitoring dashboard reviewed weekly
- [ ] Data retention policy defined
- [ ] Backup and disaster recovery plan documented
- [ ] Contact list for support escalation

## Compliance

- [ ] Data residency requirements met
- [ ] Compliance tags applied to resources
- [ ] Privacy requirements documented
- [ ] Data retention complies with policy
- [ ] Access logging enabled
- [ ] Audit trail available

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Deployment Engineer | | | |
| Security Team Lead | | | |
| Operations Manager | | | |

---

**Deployment Status**: ⬜ Not Started | 🟡 In Progress | ✅ Complete

**Deployed By**: _________________

**Deployment Date**: _________________

**Production Ready**: ⬜ Yes | ⬜ No | ⬜ Pending Review
