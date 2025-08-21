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
-   `--remote-ollama HOST:PORT`: Use an existing remote Ollama instance instead of installing locally.

Examples:
```bash
# Run setup in development mode and skip prerequisite checks
./setup.sh --dev-mode --skip-prereqs

# Use a remote Ollama instance
./setup.sh --remote-ollama 192.168.1.100:11434

# Combine options
./setup.sh --skip-prereqs --remote-ollama 10.0.0.50:11434
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
| Open WebUI        | http://ai.local         | Create on first visit      |
| n8n               | http://n8n.local        | admin / your-password      |
| Grafana           | http://grafana.local    | admin / your-password      |
| Prometheus        | http://prometheus.local | admin / your-password      |
| Traefik Dashboard | http://traefik.local    | admin / your-password      |
| cAdvisor          | http://cadvisor.local   | No authentication required |
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
- `models-mac.conf`: AI model definitions for Mac platform
- `models-linux.conf`: AI model definitions for Linux platform
- `traefik/`: Reverse proxy rules
- `litellm/config.yaml`: Model configurations (generated from template)
- `postgresql/postgresql.conf`: Database tuning
- `prometheus/prometheus.yml`: Metrics scraping
- `grafana/`: Dashboards and datasources

### mDNS Service Discovery

#### Optional Traefik mDNS Helper

The system includes an optional `traefik-avahi-helper` container that enables mDNS (multicast DNS) service discovery for Traefik. This service helps in resolving local `.local` domain names across different platforms.

##### Windows Compatibility

On Windows systems, you'll need to install Bonjour Print Services from Apple to enable mDNS resolution. You can download it from: https://support.apple.com/en-us/106380

##### Enabling the Service

The mDNS helper is currently commented out in the `docker-compose.yml` file. To enable it:

1. Uncomment the `traefik-avahi-helper` service block in `docker-compose.yml`
2. Restart the Docker Compose services

```bash
# Uncomment the service in docker-compose.yml
# Restart services
docker-compose up -d
```

##### How It Works

- Uses the `hardillb/traefik-avahi-helper` image
- Provides service discovery via mDNS
- Allows resolution of `.local` domain names
- Requires host networking mode to function properly

**Note:** This service is optional and primarily useful for local network service discovery.

## Remote Ollama Configuration

The system supports using a remote Ollama instance instead of installing Ollama locally. This is useful when:

- You have a dedicated GPU server running Ollama
- You want to share Ollama across multiple client machines
- You're running the system on a machine without GPU capabilities

### Prerequisites for Remote Ollama

1. **Remote Ollama Setup**: Ensure Ollama is running on the remote machine
2. **Network Access**: The remote Ollama instance must be accessible from the client machine
3. **Firewall Configuration**: Port 11434 must be open on the remote machine
4. **Model Availability**: Required models should be available on the remote instance

### Configuration Steps

1. **Use the remote-ollama flag:**
   ```bash
   ./setup.sh --remote-ollama 192.168.1.100:11434
   ```

2. **Verify connectivity:**
   ```bash
   # Test remote Ollama before setup
   curl http://192.168.1.100:11434/api/tags
   ```

3. **Check models:**
   ```bash
   # List available models on remote instance
   curl http://192.168.1.100:11434/api/tags | jq '.models[].name'
   ```

### Remote Ollama Server Setup

On the remote machine running Ollama:

1. **Configure Ollama to accept external connections:**
   ```bash
   # Set environment variable
   export OLLAMA_HOST=0.0.0.0:11434
   
   # Or for systemd service
   sudo systemctl edit ollama
   # Add:
   [Service]
   Environment="OLLAMA_HOST=0.0.0.0:11434"
   
   sudo systemctl daemon-reload
   sudo systemctl restart ollama
   ```

2. **Configure firewall:**
   ```bash
   # Ubuntu/Linux
   sudo ufw allow 11434
   
   # Or iptables
   sudo iptables -A INPUT -p tcp --dport 11434 -j ACCEPT
   ```

### Differences from Local Setup

When using remote Ollama:
- Local Ollama installation is skipped
- Docker containers connect directly to the remote IP
- Model pulling is done via API calls to the remote instance
- No `host.docker.internal` mapping is used
- Health checks target the remote instance

## Troubleshooting

### Common Issues

#### 1. Ollama Connection Failed

**For Local Ollama:**
```bash
# Check Ollama is running
brew services list | grep ollama

# Restart Ollama
brew services restart ollama

# Check Ollama logs
tail -f ~/.ollama/logs/server.log
```

**For Remote Ollama:**
```bash
# Test remote Ollama connectivity
curl http://REMOTE_IP:11434/api/tags

# Check network connectivity
ping REMOTE_IP

# Verify remote Ollama is running
ssh user@REMOTE_IP "systemctl status ollama"
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
