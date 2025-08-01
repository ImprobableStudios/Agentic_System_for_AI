# Port Mapping for Agentic AI System

This document provides a comprehensive overview of all ports exposed by the Docker containers in this project, including both direct port mappings and services exposed through Traefik reverse proxy.

## Port Mapping Table

| Exposed Port | Bound Addr | Traefik Alias | Service | Description |
|--------------|------------|---------------|---------|-------------|
| 80   | 0.0.0.0    | -         | traefik          | HTTP entry point for reverse proxy                 |
| 443  | 0.0.0.0    | -         | traefik          | HTTPS entry point for reverse proxy                |
| 3000 | 0.0.0.0    | grafana   | grafana          | Grafana dashboards and alerting UI                  |
| 3100 | 127.0.0.1  | -         | loki             | Log aggregation API queried by Grafana             |
| 4000 | 0.0.0.0    | api       | litellm          | OpenAI-compatible inference API                     |
| 4001 | 127.0.0.1  | -         | litellm          | Prometheus metrics endpoint for LiteLLM             |
| 5432 | 127.0.0.1  | -         | postgresql       | Primary Postgres database used by the stack         |
| 5678 | 0.0.0.0    | n8n       | n8n              | Workflow automation platform (internal port 5678)  |
| 6333 | 0.0.0.0    | qdrant    | qdrant           | Vector database API                                 |
| 6379 | 127.0.0.1  | -         | redis            | In-memory cache / message queue backend             |
| 8080 | 0.0.0.0    | traefik   | traefik          | Traefik dashboard / API                             |
| 8081 | 0.0.0.0    | cadvisor  | cadvisor         | Container resource-usage metrics and UI             |
| 8082 | 0.0.0.0    | ai        | open-webui       | AI chat interface (internal port 8080)              |
| 8083 | 0.0.0.0    | search    | searxng          | Privacy-focused search engine (internal port 8080) |
| 9090 | 0.0.0.0    | prometheus| prometheus       | Prometheus UI and API for scraping / querying metrics|
| 9093 | 0.0.0.0    | alertmanager| alertmanager    | Alertmanager UI and webhook receiver for Prometheus alerts |
| 9100 | 127.0.0.1  | -         | node-exporter    | Host-level CPU / memory / disk metrics exporter     |
| 9115 | 127.0.0.1  | -         | blackbox-exporter| HTTP/ICMP/TCP endpoint probing exporter             |
| 9121 | 127.0.0.1  | -         | redis-exporter   | Redis metrics exporter                              |
| 9187 | 127.0.0.1  | -         | postgres-exporter| PostgreSQL metrics exporter                         |

## Notes

- **Services with Traefik aliases** are accessible via the reverse proxy on ports 80/443 using the configured domain (i.e. `http://ai.local` or your custom domain)
- **Services without exposed ports** are only accessible through Traefik routing
- **All localhost-bound services (127.0.0.1)** are intended for internal access or SSH tunneling

## Access Patterns

### Direct Access
Services bound to `0.0.0.0` can be accessed directly:
- HTTP/HTTPS traffic: `http://your-host:80` or `https://your-host:443`
- LiteLLM API: `http://your-host:4000`

### Traefik Routed Access
Services with Traefik aliases are accessed via domain names:
- Main UI: `http://ai.local` (or your configured domain)
- API: `http://api.local`
- Monitoring: `http://grafana.local`, `http://prometheus.local`, `http://cadvisor.local`
- Tools: `http://n8n.local`, `http://search.local`
- Data: `http://qdrant.local`

### Localhost Only
Services bound to `127.0.0.1` require local access or SSH tunneling:
```bash
# Example SSH tunnel for Grafana
ssh -L 3000:localhost:3000 user@your-host
```