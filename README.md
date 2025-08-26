# Agentic AI System

A production-ready, hybrid AI platform combining native Ollama for maximum GPU performance with containerized services for enterprise-grade features. Supports both Mac Studio (Apple Silicon) and Linux Server (NVIDIA GPU) deployments.

## 🚀 Features

- **Hybrid Architecture**: Native Ollama for GPU acceleration + Docker services for portability
- **Multi-Platform Support**: Optimized for Mac Studio M3 Ultra and Linux Server with NVIDIA GPUs
- **Multiple AI Models**: Platform-specific models with easy customization via configuration files
- **Enterprise Ready**: Full monitoring, security, authentication, and backup capabilities
- **Workflow Automation**: Built-in n8n for complex AI agent workflows
- **Vector Search**: Qdrant database for semantic search and RAG applications
- **Privacy Focused**: Self-hosted with SearXNG for private web search
- **High Performance**: GPU-optimized for both Apple Silicon and NVIDIA architectures

## 📋 Prerequisites

### Mac Studio / Linux Server
- **Operating System**: macOS 14+ (Sonoma) or Debian/Ubuntu Linux
- **Memory**: 64GB RAM minimum (128GB+ recommended)
- **Storage**: 1TB NVMe SSD minimum (2TB+ recommended)
- **GPU**:
    - **Mac**: M1/M2/M3 Ultra with maximum GPU cores
    - **Linux**: NVIDIA RTX 3090 / 4090 or higher, with appropriate drivers
- **Software**:
    - **macOS**: Homebrew, Docker Desktop with Colima
    - **Linux**: Docker, Docker Compose, NVIDIA Container Toolkit
- **Connectivity**: Internet access for downloading models and dependencies

## 🚀 Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ImprobableStudios/Agentic_System_for_AI.git
   cd Agentic_System_for_AI
   ```

2. **Run the setup script:**
  This will install all prerequisites, configure the environment, and start all services.
  ```bash
  chmod +x setup.sh
  ./setup.sh
  ```

  **Set admin password manually:**
  You can supply an admin password directly (instead of auto-generating):
  ```bash
  ./setup.sh --admin-password MySecretPass
  ```

  **For remote Ollama setup:**
  If you have an existing Ollama instance running on another machine, you can use it instead of installing locally:
  ```bash
  ./setup.sh --remote-ollama 192.168.1.100:11434
  ```

3. **Access the services:**
   Once the setup is complete, you can access the various services via their respective URLs (e.g., `http://ai.local`, `http://n8n.local`). Refer to the `credentials.txt` file for initial login details.

## 🔧 Configuration
The system is highly configurable via the `.env` file and the configuration files in the `config` directory.

- **`.env`**: Main environment variables, including domain names, passwords, and API keys.
- **`config/models.conf`**: Define the AI models to be used for all platforms.
- **`config/litellm/config.yaml`**: LiteLLM configuration for model routing and fallbacks.
- **`docker-compose.yml`**: Defines all the containerized services and their configurations.

## Architecture
The system uses a hybrid architecture:
- **Native Ollama**: Runs directly on the host OS to leverage maximum GPU performance for model inference.
- **Remote Ollama**: Alternatively, connect to an existing Ollama instance running on another machine.
- **Dockerized Services**: All other components (databases, monitoring, applications) are containerized for portability and easy management.

For a detailed architecture overview, see `docs/architecture_evaluation.md`.

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏗️ Architecture

The system uses a hybrid approach for optimal performance:

### Mac Studio Architecture
```
┌─────────────────────────────────────────────────────┐
│                Mac Studio M3 Ultra                  │
│         Unified Memory Architecture (256GB)         │
│                                                     │
│  Native Ollama (Metal)  ←→  Docker Services         │
│                            - LiteLLM Gateway        │
│                            - Open WebUI             │
│                            - PostgreSQL             │
│                            - Redis                  │
│                            - Qdrant                 │
│                            - Monitoring Stack       │
└─────────────────────────────────────────────────────┘
```

### Linux Server Architecture
```
┌─────────────────────────────────────────────────────┐
│              Linux Server + NVIDIA GPU              │
│      RTX PRO 6000 Blackwell (96GB GDDR7)            │
│                                                     │
│  Native Ollama (CUDA)  ←→  Docker Services          │
│  24,064 CUDA Cores        - LiteLLM Gateway         │
│  752 Tensor Cores         - Open WebUI              │
│                           - PostgreSQL              │
│                           - Redis                   │
│                           - Qdrant                  │
│                           - Monitoring Stack        │
└─────────────────────────────────────────────────────┘
```

### Remote Ollama Architecture
```
┌─────────────────────────────────────────────────────┐
│               Client Machine                        │
│                                                     │
│  Docker Services          ←→  Remote Ollama         │
│  - LiteLLM Gateway              (192.168.1.100)     │
│  - Open WebUI                                       │
│  - PostgreSQL                                       │
│  - Redis                                            │
│  - Qdrant                                           │
│  - Monitoring Stack                                 │
└─────────────────────────────────────────────────────┘
```

## 📦 Components

### AI Services
- **Ollama**: Native GPU inference engine (Metal for Mac, CUDA for NVIDIA) or remote instance
- **LiteLLM**: Unified API gateway with caching
- **Open WebUI**: Modern chat interface
- **Qdrant**: Vector database for embeddings

### Infrastructure
- **PostgreSQL**: Primary database
- **Redis**: High-performance caching
- **Traefik**: Reverse proxy with SSL support
- **n8n**: Workflow automation platform
- **SearXNG**: Private search engine

### Monitoring
- **Prometheus**: Metrics collection
- **Grafana**: Dashboards and visualization
- **Loki**: Log aggregation
- **AlertManager**: Alert routing

## 🔧 Configuration

### Environment Setup

The setup scripts automatically generate a `.env` file. To modify:

```bash
# Edit configuration
nano .env
```

Key configurations:
- `DOMAIN_NAME`: Your domain (default: local)
- `POSTGRES_PASSWORD`: Database password (auto-generated)
- `LITELLM_MASTER_KEY`: API authentication key (auto-generated)
- `OPENAI_API_KEY`: OpenAI key for fallback (optional)

### Available Models


Models are configured in a single file for all platforms:
- **`config/models.conf`**: Main model configuration file used by the setup script.
  - For high-VRAM systems, use `models-96gb.conf` or `models-200gb.conf` as needed.

**Note:** By default, `config/models.conf` is identical to `models-4gb.conf` and suitable for systems with limited VRAM (4GB or more). For high-performance systems, you may copy `models-96gb.conf` or `models-200gb.conf` to `models.conf`:

```bash
cp config/models-96gb.conf config/models.conf   # For 96GB+ VRAM systems
cp config/models-200gb.conf config/models.conf  # For 200GB+ VRAM systems
```

Each platform includes:
- Primary general-purpose model
- Code-specialized model
- Embedding model for vector operations
- Reranking model for search optimization
- Small model for quick tasks

See [Model Configuration Guide](config/README.md) for customization instructions.

## 🖥️ Usage

### Web Interfaces

After deployment, access:

| Service | URL | Purpose |
|---------|-----|---------|
| Open WebUI | http://ai.local | AI Chat Interface |
| LiteLLM API | http://api.local | Lightweight Language Model API |
| n8n | http://n8n.local | Workflow Automation |
| SearXNG | http://search.local | Private Search |
| Traefik | http://traefik.local | Proxy Dashboard |
| Qdrant | http://qdrant.local | Vector Database |
| Grafana | http://grafana.local | Monitoring Dashboards |
| Prometheus | http://prometheus.local | Metrics Browser |
| AlertManager | http://alertmanager.local | Alert Management |

#### mDNS Service Discovery

The system supports optional local `.local` domain resolution via an optional mDNS helper service. On Windows, you'll need to install [Bonjour Print Services](https://support.apple.com/en-us/106380) to enable this feature. See the [setup documentation](docs/setup_documentation.md#mdns-service-discovery) for more details. This feature is not enabled by default.

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

### GPU Monitoring

**Mac Studio**:
```bash
# CPU/GPU usage via Activity Monitor
# Power metrics
sudo powermetrics --samplers gpu_power -i1000
```

**Linux Server**:
```bash
# Real-time GPU monitoring
nvidia-smi -l 1
# Or use nvtop for better interface
nvtop
```

### Pre-configured Dashboards
- System Overview
- GPU Utilization (NVIDIA)
- AI Service Metrics
- Database Performance
- Container Resources

## 🔐 Security

- **Network Isolation**: Four separate Docker networks
- **Authentication**: Service-level auth on all endpoints
- **Firewall**: UFW configured (Linux) / macOS firewall (Mac)
- **Access Control**: Basic auth on admin interfaces
- **Secrets Management**: Auto-generated, environment-based secure credentials

## 🛠️ Maintenance

### Backups
```bash
# Run backup
./scripts/backup.sh

# Schedule automated backups (cron)
0 2 * * * /path/to/scripts/backup.sh

# Restore from backup
./scripts/restore-backup.sh --date 2025-08-15
```

### Updates
```bash
# Update all services
docker-compose pull
docker-compose up -d

# Update Ollama models
ollama pull qwen3:235b-a22b
```

### Platform-Specific Maintenance

**Ubuntu Server**:
```bash
# Update NVIDIA drivers
sudo ubuntu-drivers autoinstall

# Update system
sudo apt update && sudo apt upgrade
```

**Mac Studio**:
```bash
# Update Ollama
brew upgrade ollama

# Update system via System Settings
```

## 📖 Documentation

- [Architecture Overview](docs/architecture_evaluation.md)
- [Mac Setup Guide](docs/setup_documentation.md)
- [Linux Installation Guide](docs/linux_installation_guide.md)
- [Monitoring Guide](docs/monitoring_guide.md)

## 🐛 Troubleshooting

### Common Issues

**GPU Not Detected (Ubuntu)**
```bash
# Check NVIDIA driver
nvidia-smi
# Reinstall if needed
sudo ubuntu-drivers autoinstall
```

**Ollama Connection Failed**
```bash
# Mac
brew services restart ollama

# Linux
sudo systemctl restart ollama
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
4. Test on your target platform
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file.

## 🙏 Acknowledgments

- Ollama team for the excellent inference engine
- Open WebUI for the modern interface
- NVIDIA for CUDA ecosystem
- Apple for Metal performance shaders
- All open source projects that make this possible
- CodeLLM from Abacus.AI for co-authoring this project

## 📞 Support

- GitHub Issues: Bug reports and feature requests
- Discussions: Community help and questions

---

**Current Version**: 1.1.0 | **Last Updated**: July 25, 2025