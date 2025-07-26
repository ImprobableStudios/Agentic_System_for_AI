# Agentic AI System

A production-ready, hybrid AI platform combining native Ollama for maximum GPU performance with containerized services for enterprise-grade features. Optimized for Mac Studio M3 Ultra with 256GB unified memory.

## 🚀 Features

- **Hybrid Architecture**: Native Ollama for GPU acceleration + Docker services for portability
- **Multiple AI Models**: Qwen3 235B, Code-optimized models, embeddings, and OpenAI fallback
- **Enterprise Ready**: Full monitoring, security, authentication, and backup capabilities
- **Workflow Automation**: Built-in n8n for complex AI agent workflows
- **Vector Search**: Qdrant database for semantic search and RAG applications
- **Privacy Focused**: Self-hosted with SearXNG for private web search
- **High Performance**: Optimized for Apple Silicon M3 Ultra architecture

## 📋 Prerequisites

- Mac Studio M3 Ultra (or Apple Silicon Mac with 64GB+ RAM)
- macOS Sonoma or later
- Docker Desktop for Mac
- 500GB+ available storage
- Homebrew package manager

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/ImprobableStudios/Agentic_System_for_AI.git
cd Agentic_System_for_AI

# Run automated setup
./setup.sh
```

The setup script will:
1. Install required dependencies (Ollama, tools)
2. Configure Docker Desktop resources
3. Generate secure credentials
4. Deploy all services
5. Verify system health

## 🏗️ Architecture

The system uses a hybrid approach for optimal performance:

```
┌─────────────────────────────────────────────────────┐
│                Mac Studio M3 Ultra                  │
│                                                     │
│  Native Ollama (GPU/Metal)  ←→  Docker Services     │
│                                  - LiteLLM Gateway  │
│                                  - Open WebUI       │
│                                  - PostgreSQL       │
│                                  - Redis            │
│                                  - Qdrant           │
│                                  - Monitoring Stack │
└─────────────────────────────────────────────────────┘
```

## 📦 Components

### AI Services
- **Ollama**: Native GPU inference engine
- **LiteLLM**: Unified API gateway with caching
- **Open WebUI**: Modern chat interface
- **Qdrant**: Vector database for embeddings

### Infrastructure
- **PostgreSQL**: Primary database (80GB allocated)
- **Redis**: High-performance caching (32GB)
- **Traefik**: Reverse proxy with SSL support
- **n8n**: Workflow automation platform

### Monitoring
- **Prometheus**: Metrics collection
- **Grafana**: Dashboards and visualization
- **Loki**: Log aggregation
- **AlertManager**: Alert routing

## 🔧 Configuration

### Environment Setup

Create a `.env` file with your settings:

```bash
# Copy template
cp .env.example .env

# Edit with your values
nano .env
```

Key configurations:
- `DOMAIN_NAME`: Your domain (default: local)
- `POSTGRES_PASSWORD`: Strong database password
- `LITELLM_MASTER_KEY`: API authentication key
- OpenAI API key (optional, for fallback)

### Available Models

The system comes pre-configured with:
- `qwen3:235b-a22b` - Primary general-purpose model
- `mychen76/qwen3_cline_roocode:14b` - Code generation
- `mistral:7b` - Fast inference
- `Qwen3-Embedding-8B` - Semantic search
- `Qwen3-Reranker-8B` - Document ranking

## 🖥️ Usage

### Web Interfaces

After deployment, access:

| Service | URL | Purpose |
|---------|-----|---------|
| Open WebUI | http://ai.local | AI Chat Interface |
| n8n | http://n8n.local | Workflow Automation |
| Grafana | http://grafana.local | Monitoring Dashboards |
| Traefik | http://traefik.local | Proxy Dashboard |

### API Access

```bash
# Test LiteLLM API
curl http://localhost:4000/v1/completions \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3:235b-a22b",
    "prompt": "Hello, world!",
    "max_tokens": 100
  }'
```

## 📊 Monitoring

### Pre-configured Dashboards
- System Overview
- AI Service Metrics
- Database Performance
- Container Resources

### Key Metrics
- Model inference latency
- Token generation rate
- Cache hit ratios
- Resource utilization

## 🔐 Security

- **Network Isolation**: Four separate Docker networks
- **Authentication**: Service-level auth on all endpoints
- **Encryption**: TLS support via Traefik
- **Access Control**: Basic auth on admin interfaces
- **Secrets Management**: Environment-based configuration

## 🛠️ Maintenance

### Backups
```bash
# Automated backup
./scripts/backup-all.sh

# Restore from backup
./scripts/restore-backup.sh --date 2024-01-15
```

### Updates
```bash
# Update all services
docker-compose pull
docker-compose up -d

# Update Ollama models
ollama pull qwen3:235b-a22b
```

## 📖 Documentation

- [Architecture Overview](docs/architecture_evaluation.md)
- [Setup Guide](docs/setup_documentation.md)
- [Monitoring Guide](docs/monitoring_guide.md)
- [Implementation Plan](docs/implementation_plan.md)

## 🐛 Troubleshooting

### Common Issues

**Ollama Connection Failed**
```bash
# Check Ollama service
brew services list | grep ollama
brew services restart ollama
```

**High Memory Usage**
```bash
# Check resource allocation
docker stats
# Adjust in Docker Desktop settings
```

**Service Won't Start**
```bash
# Check logs
docker-compose logs [service-name]
# Verify dependencies
docker-compose ps
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

## 🙏 Acknowledgments

- Ollama team for the excellent inference engine
- Open WebUI for the modern interface
- All open source projects that make this possible

## 📞 Support

- GitHub Issues: Bug reports and feature requests
- Discussions: Community help and questions

---

**Current Version**: 1.0.0 | **Last Updated**: July 25, 2025
