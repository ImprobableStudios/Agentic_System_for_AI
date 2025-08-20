# Monitoring Guide - Agentic AI System

**Last Updated:** July 25, 2025

## Overview

The Agentic AI System includes a comprehensive monitoring stack built on industry-standard tools. This guide covers accessing monitoring interfaces, understanding key metrics, creating custom dashboards, and responding to alerts.

## Monitoring Stack Components

### Core Components
- **Prometheus**: Time-series metrics database
- **Grafana**: Visualization and dashboarding
- **Loki**: Log aggregation system
- **Promtail**: Log collection agent
- **AlertManager**: Alert routing and management

### Metrics Exporters
- **Node Exporter**: System-level metrics
- **cAdvisor**: Container metrics
- **PostgreSQL Exporter**: Database metrics
- **Redis Exporter**: Cache metrics
- **Blackbox Exporter**: Endpoint monitoring

## Accessing Monitoring Interfaces

### Grafana (Primary Dashboard)
- **URL**: http://grafana.local
- **Default Login**: admin / [your-configured-password]
- **Purpose**: Centralized metrics visualization

### Prometheus
- **URL**: http://prometheus.local
- **Authentication**: Basic auth configured in .env
- **Purpose**: Direct metric queries and debugging

### AlertManager
- **URL**: http://alertmanager.local
- **Authentication**: Basic auth configured in .env
- **Purpose**: Alert management and silencing

### cAdvisor (Container Metrics)
- **URL**: http://cadvisor.local
- **Authentication**: No authentication required
- **Purpose**: Real-time container resource usage and performance metrics

## Key Metrics to Monitor

### System Health Metrics

#### CPU Usage
```promql
# Overall CPU usage
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Per-core CPU usage
100 - (rate(node_cpu_seconds_total{mode="idle"}[5m]) * 100)
```

#### Memory Usage
```promql
# Total memory usage percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Memory usage by container
sum(container_memory_usage_bytes) by (name) / 1024 / 1024 / 1024
```

#### Disk Usage
```promql
# Disk usage percentage
100 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100)

# Disk I/O rate
rate(node_disk_read_bytes_total[5m]) + rate(node_disk_written_bytes_total[5m])
```

### Service-Specific Metrics

#### Ollama/LiteLLM Metrics
```promql
# Request rate
rate(litellm_request_total[5m])

# Request latency (p95)
histogram_quantile(0.95, rate(litellm_request_duration_seconds_bucket[5m]))

# Model usage by name
sum(rate(litellm_model_request_total[5m])) by (model)

# Token generation rate
rate(litellm_tokens_generated_total[5m])
```

#### PostgreSQL Metrics
```promql
# Active connections
pg_stat_database_numbackends{datname="agentic_ai"}

# Transaction rate
rate(pg_stat_database_xact_commit{datname="agentic_ai"}[5m])

# Cache hit ratio
pg_stat_database_blks_hit / (pg_stat_database_blks_hit + pg_stat_database_blks_read) * 100

# Replication lag (if applicable)
pg_replication_lag_seconds
```

#### Redis Metrics
```promql
# Memory usage
redis_memory_used_bytes / 1024 / 1024 / 1024

# Hit rate
rate(redis_keyspace_hits_total[5m]) / (rate(redis_keyspace_hits_total[5m]) + rate(redis_keyspace_misses_total[5m])) * 100

# Connected clients
redis_connected_clients

# Operations per second
rate(redis_commands_processed_total[5m])
```

#### Container Metrics
```promql
# Container CPU usage
sum(rate(container_cpu_usage_seconds_total[5m])) by (name) * 100

# Container memory usage
sum(container_memory_usage_bytes) by (name) / 1024 / 1024 / 1024

# Container restart count
increase(container_restart_count[1h])
```

## Pre-configured Dashboards

### 1. System Overview Dashboard
Provides a high-level view of system health:
- Total CPU and memory usage
- Disk usage and I/O
- Network traffic
- Container status overview
- Service health status

### 2. AI Service Dashboard
Monitors AI-specific metrics:
- Model request rates
- Inference latency percentiles
- Token generation statistics
- Model-specific performance
- Error rates and types

### 3. Database Performance Dashboard
PostgreSQL and Redis monitoring:
- Query performance
- Connection pools
- Cache hit ratios
- Slow query analysis
- Replication status

### 4. Container Metrics Dashboard
Detailed container monitoring:
- Per-container resource usage
- Container health status
- Restart frequencies
- Network statistics
- Volume usage

## Creating Custom Dashboards

### Step 1: Access Grafana
1. Navigate to http://grafana.local
2. Login with admin credentials
3. Click "+" → "Dashboard" → "New Dashboard"

### Step 2: Add Panels
Example panel for AI response time:

```json
{
  "targets": [
    {
      "expr": "histogram_quantile(0.95, rate(litellm_request_duration_seconds_bucket[5m]))",
      "legendFormat": "p95 latency"
    }
  ],
  "title": "AI Response Time (p95)",
  "type": "graph"
}
```

### Step 3: Configure Visualizations
1. Choose visualization type (Graph, Gauge, Table, etc.)
2. Set thresholds for visual alerts
3. Configure axes and legends
4. Add annotations for events

### Step 4: Save and Share
1. Save dashboard with descriptive name
2. Set appropriate tags
3. Configure auto-refresh interval
4. Share via URL or snapshot

## Alert Configuration

### Default Alert Rules

#### System Alerts
```yaml
# High CPU usage
- alert: HighCPUUsage
  expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
  for: 5m
  annotations:
    summary: "High CPU usage detected"
    description: "CPU usage is above 80% for 5 minutes"

# High Memory usage
- alert: HighMemoryUsage
  expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
  for: 5m
  annotations:
    summary: "High memory usage detected"
    description: "Memory usage is above 90% for 5 minutes"

# Disk space low
- alert: LowDiskSpace
  expr: node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"} * 100 < 10
  for: 5m
  annotations:
    summary: "Low disk space"
    description: "Less than 10% disk space remaining"
```

#### Service Alerts
```yaml
# Service down
- alert: ServiceDown
  expr: up{job=~"litellm|postgresql|redis|grafana"} == 0
  for: 2m
  annotations:
    summary: "Service {{ $labels.job }} is down"
    description: "{{ $labels.job }} has been down for 2 minutes"

# High error rate
- alert: HighErrorRate
  expr: rate(litellm_request_total{status=~"5.."}[5m]) > 0.05
  for: 5m
  annotations:
    summary: "High error rate detected"
    description: "Error rate is above 5% for 5 minutes"

# Database connection pool exhausted
- alert: DatabaseConnectionPoolExhausted
  expr: pg_stat_database_numbackends / pg_settings_max_connections > 0.8
  for: 5m
  annotations:
    summary: "Database connection pool nearly exhausted"
    description: "Database using >80% of available connections"
```

### Creating Custom Alerts

1. **Edit Prometheus configuration**:
```yaml
# In config/prometheus/alerts/custom.yml
groups:
  - name: custom_alerts
    rules:
      - alert: YourAlertName
        expr: your_prometheus_query > threshold
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Alert summary"
          description: "Detailed description"
```

2. **Reload Prometheus**:
```bash
docker-compose exec prometheus kill -HUP 1
```

### Alert Routing

AlertManager configuration (`config/alertmanager/alertmanager.yml`):
```yaml
route:
  group_by: ['alertname', 'severity']
  group_wait: 10s
  group_interval: 5m
  repeat_interval: 12h
  receiver: 'default'
  routes:
    - match:
        severity: critical
      receiver: 'critical-alerts'
      continue: true
    - match:
        severity: warning
      receiver: 'warning-alerts'

receivers:
  - name: 'default'
    email_configs:
      - to: 'admin@example.com'
        
  - name: 'critical-alerts'
    email_configs:
      - to: 'oncall@example.com'
    webhook_configs:
      - url: 'http://your-webhook-url'
        
  - name: 'warning-alerts'
    email_configs:
      - to: 'team@example.com'
```

## Log Management

### Accessing Logs via Loki

1. **In Grafana**:
   - Go to "Explore" (compass icon)
   - Select "Loki" as data source
   - Use LogQL queries

### Common LogQL Queries

```logql
# All logs from a specific service
{container_name="agentic-litellm"}

# Error logs only
{container_name="agentic-litellm"} |= "error"

# Logs with response time > 1s
{container_name="agentic-litellm"} |= "response_time" | json | response_time > 1000

# Count of errors per minute
sum(rate({container_name=~"agentic-.*"} |= "error" [1m])) by (container_name)
```

### Log Retention

Configured in `config/loki/loki-config.yml`:
```yaml
limits_config:
  retention_period: 720h  # 30 days

chunk_store_config:
  max_look_back_period: 720h
```

## Performance Optimization

### Query Optimization

1. **Use recording rules** for frequently-used queries:
```yaml
# In prometheus configuration
groups:
  - name: recording_rules
    interval: 30s
    rules:
      - record: instance:node_cpu:rate5m
        expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

2. **Optimize cardinality**:
   - Limit label combinations
   - Use metric relabeling
   - Drop unnecessary metrics

### Dashboard Optimization

1. **Set appropriate refresh intervals**:
   - Real-time: 5-10s
   - Standard: 30s-1m
   - Historical: 5m+

2. **Limit query ranges**:
   - Use `$__range` variable
   - Set max data points
   - Use step parameter

3. **Cache dashboard queries**:
   - Enable query caching in Grafana
   - Use Redis for cache backend

## Troubleshooting Monitoring Issues

### Prometheus Issues

```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Verify service discovery
docker-compose exec prometheus promtool check config /etc/prometheus/prometheus.yml

# Check Prometheus logs
docker-compose logs prometheus
```

### Grafana Issues

```bash
# Test data source connection
curl -H "Authorization: Bearer $API_KEY" \
  http://localhost:3000/api/datasources/1/health

# Check Grafana logs
docker-compose logs grafana
```

### Missing Metrics

1. Verify exporter is running:
```bash
docker-compose ps | grep exporter
```

2. Check exporter metrics:
```bash
curl http://localhost:9100/metrics  # node-exporter
curl http://localhost:9187/metrics  # postgres-exporter
```

3. Verify Prometheus scraping:
```bash
# In Prometheus UI, check Targets page
http://prometheus.local/targets
```

## Best Practices

### 1. Metric Naming
- Use consistent naming conventions
- Include unit in metric name (_bytes, _seconds)
- Follow Prometheus naming guidelines

### 2. Label Usage
- Keep cardinality under control
- Use meaningful label names
- Avoid high-cardinality labels (user_id, request_id)

### 3. Alert Design
- Alert on symptoms, not causes
- Include runbook links in descriptions
- Set appropriate severity levels
- Avoid alert fatigue

### 4. Dashboard Design
- Group related metrics
- Use consistent color schemes
- Include documentation panels
- Set meaningful titles and descriptions

### 5. Retention Policies
- Balance storage vs. history needs
- Use recording rules for long-term trends
- Consider downsampling old data
- Regular cleanup of unused metrics

## Monitoring Maintenance

### Daily Tasks
- Check alert status in AlertManager
- Review error rates and anomalies
- Verify all services are being scraped

### Weekly Tasks
- Review dashboard performance
- Check disk usage for monitoring data
- Update alerting thresholds if needed
- Review and acknowledge recurring alerts

### Monthly Tasks
- Analyze long-term trends
- Optimize slow queries
- Review and update documentation
- Plan capacity based on growth trends

## Integration with External Tools

### Slack Integration
```yaml
# In alertmanager config
receivers:
  - name: 'slack-notifications'
    slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#alerts'
        title: 'Agentic AI Alert'
```

### PagerDuty Integration
```yaml
receivers:
  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_SERVICE_KEY'
```

### Custom Webhooks
```yaml
receivers:
  - name: 'webhook'
    webhook_configs:
      - url: 'http://your-webhook-endpoint'
        send_resolved: true
```

## Conclusion

The monitoring stack provides comprehensive visibility into the Agentic AI System's health and performance. Regular monitoring, proper alert configuration, and dashboard maintenance ensure optimal system operation and quick issue resolution. Use this guide as a reference for daily operations and customize based on your specific needs.