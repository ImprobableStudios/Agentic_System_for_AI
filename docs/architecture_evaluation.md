# Agentic AI System Architecture
**Current Environment:** Mac Studio M3 Ultra (256GB Unified Memory)  
**Implementation Status:** Production-Ready  
**Last Updated:** July 25, 2025  

## Executive Summary

The Agentic AI System implements a hybrid architecture combining native Ollama for maximum GPU performance with containerized supporting services for isolation and easy management. This design leverages the Mac Studio M3 Ultra's unified memory architecture while providing enterprise-grade monitoring, security, and scalability.

**Key Architecture Decisions:**
- **Native Ollama**: Direct GPU/Metal access for optimal inference performance
- **Containerized Services**: All supporting services in Docker for portability and isolation
- **LiteLLM Bridge**: Unified API gateway connecting containerized services to native Ollama
- **Network Segmentation**: Four isolated networks for security and performance
- **Comprehensive Monitoring**: Full observability with Prometheus, Grafana, and Loki

## 1. System Architecture Overview

### 1.1 Hybrid Native-Container Design

```
┌─────────────────────────────────────────────────────────────────┐
│                    Mac Studio M3 Ultra Host                     │
│                                                                 │
│  ┌─────────────────┐       ┌──────────────────────────────────┐ │
│  │  Native Ollama  │       │      Docker Environment          │ │
│  │                 │       │                                  │ │
│  │  - Direct GPU   │◄─────►│  ┌──────────────┐                │ │
│  │  - Metal API    │       │  │   LiteLLM    │                │ │
│  │  - 256GB Memory │       │  │  API Gateway │                │ │
│  └─────────────────┘       │  └──────┬───────┘                │ │
│                            │         │                        │ │
│                            │  ┌──────┴───────┐                │ │
│                            │  │ Open WebUI   │                │ │
│                            │  │     n8n      │                │ │
│                            │  │   SearXNG    │                │ │
│                            │  └──────────────┘                │ │
│                            │                                  │ │
│                            │  ┌──────────────────────────────┐│ │
│                            │  │  Data Layer: PostgreSQL,     ││ │
│                            │  │  Redis, Qdrant               ││ │
│                            │  └──────────────────────────────┘│ │
│                            │                                  │ │
│                            │  ┌──────────────────────────────┐│ │
│                            │  │  Monitoring: Prometheus,     ││ │
│                            │  │  Grafana, Loki, AlertManager ││ │
│                            │  └──────────────────────────────┘│ │
│                            └──────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Network Architecture

The system implements four isolated Docker networks for security and performance:

1. **agentic-ai-frontend (172.20.0.0/16)**: Public-facing services
   - Traefik reverse proxy
   - Open WebUI
   - API endpoints

2. **agentic-ai-backend (172.21.0.0/16)**: Internal application services
   - LiteLLM
   - n8n workflow engine
   - Internal APIs

3. **agentic-ai-data (172.22.0.0/16)**: Data persistence layer
   - PostgreSQL
   - Redis
   - Qdrant vector database

4. **agentic-ai-monitoring (172.23.0.0/16)**: Observability stack
   - Prometheus
   - Grafana
   - Loki
   - AlertManager

## 2. Service Components

### 2.1 AI Inference Layer

**Native Ollama Configuration:**
- Runs directly on macOS for maximum GPU utilization
- Optimized for M3 Ultra with Metal acceleration
- Memory configuration: Up to 200GB for model loading
- Performance: ~1,100 tokens/sec single-user, 63-88 tokens/sec multi-user

**LiteLLM API Gateway:**
- Unified API interface for all AI models
- Authentication and rate limiting
- Load balancing across model instances
- Redis-based caching for improved response times
- Fallback routing for high availability

**Supported Models:**
- Qwen3 235B-A22B (primary general-purpose)
- mychen76/qwen3_cline_roocode:14b (code generation)
- Qwen3-Embedding-8B (RAG embeddings)
- Qwen3-Reranker-8B (document reranking)
- Mistral 7B (fast inference)
- OpenAI GPT-3.5/4 (cloud fallback)

### 2.2 Application Services

**Open WebUI:**
- Primary user interface for AI interactions
- Multi-user support with authentication
- Model selection and configuration
- Chat history and session management
- SQLite database (transitioning to PostgreSQL)

**n8n Workflow Engine:**
- Visual workflow automation
- AI agent orchestration
- Webhook integrations
- PostgreSQL-backed persistence
- Redis queue for job processing

**SearXNG Search:**
- Privacy-focused web search
- Multiple search engine aggregation
- Rate-limited API access
- No user tracking

### 2.3 Data Persistence Layer

**PostgreSQL 16:**
- Primary database for all services
- Optimized configuration:
  - 64GB shared buffers
  - 80GB memory limit
  - Connection pooling enabled
  - UTF-8 encoding with C collation

**Redis 7:**
- Caching layer for LiteLLM
- Session storage
- n8n job queue
- 32GB memory allocation
- Persistence enabled

**Qdrant Vector Database:**
- Semantic search capabilities
- Document embeddings storage
- 16GB memory allocation
- GPU-accelerated indexing

### 2.4 Infrastructure Services

**Traefik 3.0:**
- Reverse proxy and load balancer
- Automatic service discovery
- SSL/TLS termination (when configured)
- Rate limiting middleware
- Security headers

**Monitoring Stack:**
- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization and dashboards
- **Loki**: Log aggregation
- **Promtail**: Log shipping
- **AlertManager**: Alert routing and management
- **Exporters**: Node, PostgreSQL, Redis, Blackbox, cAdvisor

## 3. Security Architecture

### 3.1 Network Security
- Internal network isolation
- No direct external access to data services
- All traffic routed through Traefik
- Host firewall configured for minimal exposure

### 3.2 Authentication & Authorization
- Service-level authentication:
  - LiteLLM: API key authentication
  - Open WebUI: User management system
  - n8n: Basic auth with encryption
  - Monitoring: Basic auth for dashboards

### 3.3 Data Security
- Encrypted secrets management
- PostgreSQL SSL connections (when enabled)
- Redis password protection
- No data persistence in temporary containers

## 4. Performance Optimization

### 4.1 Hardware Utilization
- Native Ollama: Direct GPU access via Metal
- Docker Desktop: 200GB memory allocation
- CPU optimization: Performance cores for AI inference
- Disk I/O: Separate volumes for data and logs

### 4.2 Service Optimization
- LiteLLM: 8 workers for concurrent requests
- PostgreSQL: Optimized for OLTP workloads
- Redis: LRU eviction for cache management
- Monitoring: 30-day retention with compression

### 4.3 Resource Allocation
```yaml
Total System Memory: 256GB

Native Services:
  - Ollama: Up to 200GB (dynamic)
  - macOS System: ~20GB

Containerized Services:
  - PostgreSQL: 64-80GB
  - Redis: 16-32GB
  - Qdrant: 8-16GB
  - Application Services: ~20GB
  - Monitoring Stack: ~10GB
```

## 5. Operational Procedures

### 5.1 Startup Sequence
1. Ensure Docker Desktop is running
2. Start native Ollama service
3. Deploy containerized services via docker-compose
4. Verify health checks pass
5. Access services through configured URLs

### 5.2 Monitoring & Alerting
- Real-time metrics via Prometheus
- Pre-configured Grafana dashboards
- Log aggregation with Loki
- Alert routing through AlertManager
- Email notifications for critical alerts

### 5.3 Backup & Recovery
- Automated PostgreSQL backups
- Redis persistence snapshots
- Configuration version control
- Volume-based data persistence

## 6. Scaling Considerations

### 6.1 Vertical Scaling
- Current hardware supports significant vertical scaling
- Memory can be dynamically allocated between services
- GPU sharing possible with model management

### 6.2 Horizontal Scaling Options
- Additional Ollama instances on separate hosts
- Read replicas for PostgreSQL
- Redis clustering for cache distribution
- Load balancer configuration in Traefik

## 7. Known Limitations & Workarounds

### 7.1 Current Limitations
- Open WebUI PostgreSQL integration temporarily disabled (bug #15300)
- Single-host deployment (no built-in HA)
- Manual Ollama management required
- No automatic SSL certificate management

### 7.2 Planned Improvements
- Full PostgreSQL integration for Open WebUI
- Automated SSL with Let's Encrypt
- Kubernetes deployment option
- Enhanced multi-tenancy support
- Automated backup scheduling

## 8. Conclusion

The current architecture successfully balances performance, security, and operational complexity. The hybrid native-container approach maximizes the M3 Ultra's capabilities while maintaining deployment flexibility. The comprehensive monitoring stack ensures operational visibility, and the network segmentation provides defense-in-depth security.

This architecture is production-ready for single-site deployments and provides a solid foundation for future scaling and enhancement.
