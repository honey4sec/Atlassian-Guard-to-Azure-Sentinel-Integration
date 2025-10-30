# Azure Sentinel KQL Queries for Atlassian Guard Alerts

## Basic Queries

### View All Recent Alerts
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(24h)
| project TimeGenerated, AlertTitle, ActorName, AlertProduct, AlertSite
| order by TimeGenerated desc
```

### Count Alerts by Title
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(7d)
| summarize Count = count() by AlertTitle
| order by Count desc
```

### Count Alerts by Product
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(30d)
| summarize Count = count() by AlertProduct
| render piechart
```

## User Activity Analysis

### Most Active Users
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(30d)
| summarize AlertCount = count() by ActorName, ActorAccountId
| order by AlertCount desc
| take 10
```

### User Activity Timeline
```kql
atlassian_guard_detect_CL
| where ActorName == "USER_NAME_HERE"
| project TimeGenerated, AlertTitle, ActivityAction, AlertProduct
| order by TimeGenerated desc
```

### Users with Multiple Alert Types
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(30d)
| summarize AlertTypes = make_set(AlertTitle) by ActorName
| extend AlertTypeCount = array_length(AlertTypes)
| where AlertTypeCount > 1
| order by AlertTypeCount desc
```

## Network Analysis

### Alerts by IP Address
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(7d)
| extend Sessions = parse_json(ActorSessions)
| mv-expand Sessions
| extend IPAddress = tostring(Sessions.ipAddress)
| summarize AlertCount = count() by IPAddress, ActorName
| order by AlertCount desc
```

### Geographic IP Analysis (with enrichment)
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(7d)
| extend Sessions = parse_json(ActorSessions)
| mv-expand Sessions
| extend IPAddress = tostring(Sessions.ipAddress)
| summarize Count = count() by IPAddress
| order by Count desc
```

### Multiple IPs per User
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(7d)
| extend Sessions = parse_json(ActorSessions)
| mv-expand Sessions
| extend IPAddress = tostring(Sessions.ipAddress)
| summarize UniqueIPs = dcount(IPAddress), IPList = make_set(IPAddress) by ActorName
| where UniqueIPs > 3
| order by UniqueIPs desc
```

## Session Analysis

### User Agent Analysis
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(7d)
| extend Sessions = parse_json(ActorSessions)
| mv-expand Sessions
| extend UserAgent = tostring(Sessions.userAgent)
| summarize Count = count() by UserAgent
| order by Count desc
| take 10
```

### Session Duration Analysis
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(7d)
| extend Sessions = parse_json(ActorSessions)
| mv-expand Sessions
| extend LoginTime = todatetime(Sessions.loginTime)
| extend LastActiveTime = todatetime(Sessions.lastActiveTime)
| extend SessionDuration = LastActiveTime - LoginTime
| project ActorName, SessionDuration, TimeGenerated
| order by SessionDuration desc
```

## Time-Based Analysis

### Alerts by Hour of Day
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(30d)
| extend Hour = hourofday(TimeGenerated)
| summarize Count = count() by Hour
| render columnchart
```

### Alerts by Day of Week
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(30d)
| extend DayOfWeek = dayofweek(TimeGenerated)
| summarize Count = count() by DayOfWeek
| render columnchart
```

### Alert Trends Over Time
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(30d)
| summarize Count = count() by bin(TimeGenerated, 1d), AlertTitle
| render timechart
```

## Activity Analysis

### Most Common Actions
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(30d)
| summarize Count = count() by ActivityAction
| order by Count desc
| take 10
```

### Actions by User
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(7d)
| summarize Actions = make_set(ActivityAction) by ActorName
| extend ActionCount = array_length(Actions)
| order by ActionCount desc
```

## Workspace Analysis

### Alerts by Workspace
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(30d)
| summarize Count = count() by WorkspaceId, AlertSite
| order by Count desc
```

### Multi-Workspace Activity
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(7d)
| summarize Workspaces = dcount(WorkspaceId) by ActorName
| where Workspaces > 1
| order by Workspaces desc
```

## Anomaly Detection

### Unusual Activity Hours
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(30d)
| extend Hour = hourofday(TimeGenerated)
| where Hour < 6 or Hour > 22  // Outside business hours
| project TimeGenerated, ActorName, AlertTitle, Hour
| order by TimeGenerated desc
```

### Rapid Sequential Alerts
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(24h)
| order by ActorName, TimeGenerated asc
| serialize
| extend PrevTime = prev(TimeGenerated)
| extend PrevActor = prev(ActorName)
| where ActorName == PrevActor
| extend TimeDiff = datetime_diff('minute', TimeGenerated, PrevTime)
| where TimeDiff < 5  // Less than 5 minutes apart
| project TimeGenerated, ActorName, AlertTitle, TimeDiff
```

### High Volume Users
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(1h)
| summarize AlertCount = count() by ActorName
| where AlertCount > 10  // More than 10 alerts in an hour
| order by AlertCount desc
```

## Correlation Queries

### Alerts with Multiple Sessions
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(7d)
| extend Sessions = parse_json(ActorSessions)
| extend SessionCount = array_length(Sessions)
| where SessionCount > 1
| project TimeGenerated, ActorName, AlertTitle, SessionCount
| order by SessionCount desc
```

### Same IP, Multiple Users
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(7d)
| extend Sessions = parse_json(ActorSessions)
| mv-expand Sessions
| extend IPAddress = tostring(Sessions.ipAddress)
| summarize Users = make_set(ActorName) by IPAddress
| extend UserCount = array_length(Users)
| where UserCount > 3
| order by UserCount desc
```

## Detection Rules

### Suspicious After-Hours Activity
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(1h)
| extend Hour = hourofday(TimeGenerated)
| where Hour < 6 or Hour > 20
| summarize AlertCount = count() by ActorName, AlertTitle, bin(TimeGenerated, 5m)
| where AlertCount > 3
```

### Mass Data Access
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(1h)
| where ActivityAction contains "view" or ActivityAction contains "download"
| summarize Count = count() by ActorName, bin(TimeGenerated, 5m)
| where Count > 20
```

### Privilege Escalation Detection
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(24h)
| where AlertTitle contains "privilege" or AlertTitle contains "admin" or AlertTitle contains "permission"
| project TimeGenerated, ActorName, AlertTitle, ActivityAction
| order by TimeGenerated desc
```

## Performance Queries

### Data Ingestion Rate
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(1h)
| summarize Count = count() by bin(TimeGenerated, 5m)
| render timechart
```

### Average Ingestion Lag
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(1h)
| extend IngestionTime = ingestion_time()
| extend Lag = IngestionTime - TimeGenerated
| summarize AvgLag = avg(Lag), MaxLag = max(Lag)
```

## Export and Reporting

### Daily Summary Report
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(1d)
| summarize 
    TotalAlerts = count(),
    UniqueUsers = dcount(ActorName),
    UniqueAlertTypes = dcount(AlertTitle),
    MostCommonAlert = arg_max(AlertTitle, count()),
    MostActiveUser = arg_max(ActorName, count())
```

### Weekly Trend Analysis
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(7d)
| summarize Count = count() by bin(TimeGenerated, 1d)
| extend DayName = format_datetime(TimeGenerated, 'dddd')
| project DayName, Count
| order by TimeGenerated asc
```

## Advanced Threat Hunting

### Impossible Travel Detection
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(24h)
| extend Sessions = parse_json(ActorSessions)
| mv-expand Sessions
| extend IPAddress = tostring(Sessions.ipAddress)
| order by ActorName, TimeGenerated asc
| serialize
| extend PrevIP = prev(IPAddress, 1)
| extend PrevTime = prev(TimeGenerated, 1)
| extend PrevActor = prev(ActorName, 1)
| where ActorName == PrevActor and IPAddress != PrevIP
| extend TimeDiff = datetime_diff('hour', TimeGenerated, PrevTime)
| where TimeDiff < 2  // Same user, different IP within 2 hours
| project TimeGenerated, ActorName, IPAddress, PrevIP, TimeDiff
```

### Brute Force Pattern Detection
```kql
atlassian_guard_detect_CL
| where TimeGenerated > ago(1h)
| where AlertTitle contains "failed" or AlertTitle contains "denied"
| summarize FailureCount = count() by ActorName, bin(TimeGenerated, 5m)
| where FailureCount > 5
| order by FailureCount desc
```

---

## Tips for Creating Custom Queries

1. **Filter Early**: Use `where` clauses early in your query to reduce data processing
2. **Use Summarize**: Aggregate data to find patterns
3. **Parse JSON Carefully**: The `ActorSessions` field needs to be parsed with `parse_json()` and expanded with `mv-expand`
4. **Time Windows**: Use appropriate time windows to balance performance and relevance
5. **Visualization**: Use `render` commands for visual representation (timechart, piechart, columnchart)
6. **Testing**: Test queries on small time windows before expanding to larger datasets

## Query Performance Optimization

```kql
// Good - Filter first, then process
atlassian_guard_detect_CL
| where TimeGenerated > ago(1h)
| where ActorName == "specific_user"
| extend Sessions = parse_json(ActorSessions)

// Bad - Process everything, then filter
atlassian_guard_detect_CL
| extend Sessions = parse_json(ActorSessions)
| where ActorName == "specific_user"
| where TimeGenerated > ago(1h)
```

---

**Note**: Replace placeholder values like `USER_NAME_HERE` with actual values from your environment.
