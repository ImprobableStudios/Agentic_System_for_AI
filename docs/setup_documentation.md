# Setup Documentation - Agentic AI System

**Last Updated:** July 25, 2025

## Overview

This document provides instructions for setting up the Agentic AI System. The primary method of installation is via the `setup.sh` script, which automates the entire process, from installing prerequisites to deploying the services.

## Quick Start

### Prerequisites
- Mac Studio M3 Ultra (or similar Apple Silicon Mac with 64GB+ RAM)
- macOS Sonoma or later
- Docker Desktop for Mac
- 500GB+ available storage

### Manual Setup
```bash
# Clone the repository
git clone https://github.com/ImprobableStudios/Agentic_System_for_AI.git
cd Agentic-System_for_AI

# Run the setup script
./setup.sh
```

## The Setup Script

The `setup.sh` script is designed to be idempotent and can be run multiple times. It performs the following actions:

1.  **Checks Prerequisites**: Verifies that the system meets the hardware and software requirements.
2.  **Installs Dependencies**: Uses Homebrew to install necessary tools like Ollama, Colima, jq, and more.
3.  **Configures the Environment**: Generates a `.env` file with all the necessary secrets and configurations.
4.  **Pulls AI Models**: Downloads the required models for Ollama.
5.  **Deploys Services**: Starts all the services using Docker Compose.
6.  **Verifies Installation**: Performs health checks to ensure all services are running correctly.

### Script Arguments

You can customize the script's behavior with the following arguments:

-   `--dev-mode`: Runs the setup in development mode with debug logging.
-   `--skip-prereqs`: Skips the prerequisite checks (for re-runs).
-   `--clean`: Stops and removes all running containers and deletes the data directories before starting the setup.

Example:
```bash
# Run setup in development mode and skip prerequisite checks
./setup.sh --dev-mode --skip-prereqs
```

## Post-Installation

### Verify Installation

After the script completes, you can verify that everything is working correctly.

#### Check Service Health
```bash
# Check all containers are running
docker-compose ps

# Check Ollama is responding
curl http://localhost:11434/api/tags

# Check LiteLLM is responding
curl http://localhost:4000/health

# Check Open WebUI
curl http://localhost:8080/health
```

#### Access Web Interfaces

The script will output a list of URLs for the various services. You can also find them in the `credentials.txt` file.

| Service           | URL                     | Credentials                |
| ----------------- | ----------------------- | -------------------------- |
| Open WebUI        | http://localhost or http://ai.local | Create on first visit      |
| n8n               | http://n8n.local        | admin / your-password      |
| Grafana           | http://grafana.local    | admin / your-password      |
| Prometheus        | http://prometheus.local | admin / your-password      |
| Traefik Dashboard | http://traefik.local    | admin / your-password      |
| LiteLLM API       | http://localhost:4000   | API Key from `.env`        |

### Initial Configuration

#### Configure Open WebUI
1.  Access http://localhost
2.  Create an admin account.
3.  Go to **Settings > Models**.
4.  Verify all models are available.
5.  Test the chat with different models.

#### Configure n8n
1.  Access http://n8n.local
2.  Log in with the credentials from `credentials.txt`.
3.  Create a test workflow.
4.  Configure AI credentials pointing to LiteLLM.

#### Configure Monitoring
1.  Access Grafana at http://grafana.local
2.  Import dashboards from `config/grafana/dashboards/`.
3.  Configure alert notifications in AlertManager.

## Configuration Files

### Docker Compose Services
The `docker-compose.yml` file defines all services:
- **Traefik**: Reverse proxy and load balancer
- **PostgreSQL**: Primary database
- **Redis**: Caching and queuing
- **LiteLLM**: AI model API gateway
- **Qdrant**: Vector database
- **SearXNG**: Privacy-focused search
- **n8n**: Workflow automation
- **Open WebUI**: Chat interface
- **Monitoring Stack**: Prometheus, Grafana, Loki, etc.

### Service Configurations
Configuration files are in the `config/` directory:
- `traefik/`: Reverse proxy rules
- `litellm/config.yaml`: Model configurations
- `postgresql/postgresql.conf`: Database tuning
- `prometheus/prometheus.yml`: Metrics scraping
- `grafana/`: Dashboards and datasources

## Troubleshooting

### Common Issues

#### 1. Ollama Connection Failed
```bash
# Check Ollama is running
brew services list | grep ollama

# Restart Ollama
brew services restart ollama

# Check Ollama logs
tail -f ~/.ollama/logs/server.log
```

#### 2. Container Won't Start
```bash
# Check logs
docker-compose logs [service-name]

# Check resources
docker system df

# Clean up if needed
docker system prune -a
```

#### 3. Out of Memory
```bash
# Check Docker Desktop memory allocation
# Increase memory in Docker Desktop settings
```

### Logging Locations

Logs are stored in various locations depending on the service:

#### Docker Containers
- **Location**: Docker's default logging system
- **Access**: `docker logs [container-name]`
- **Services**: All containerized services (Traefik, PostgreSQL, Grafana, Prometheus, etc.)

#### PostgreSQL
- **Location**: `data/postgresql/log/`
- **Files**: `postgresql-YYYY-MM-DD_HHMMSS.log`
- **Access**: View directly in the file or through PostgreSQL client

#### Ollama
- **Location**: `~/.ollama/logs/`
- **Files**:
  - `server.log`: Current server log
  - `server-[N].log`: Rotated server logs
  - `app.log`: Application logs

#### n8n
- **Location**: `data/n8n/n8nEventLog.log`
- **Access**: View directly in the file

### Viewing Logs

#### For Docker Services
```bash
# View logs for a specific service
docker-compose logs [service-name]

# Follow logs in real-time
docker-compose logs -f [service-name]
```

#### For Ollama
```bash
# View Ollama server logs
tail -f ~/.ollama/logs/server.log
```

#### For PostgreSQL
```bash
# View latest PostgreSQL log
tail -f data/postgresql/log/postgresql-$(date +"%Y-%m-%d")*.log
```
