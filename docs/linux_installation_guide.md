# Ubuntu Server 24.04 Installation Guide

This guide provides detailed instructions for setting up the Agentic AI System on Ubuntu Server 24.04 with NVIDIA GPU support.

## System Requirements

- **OS**: Ubuntu Server 24.04 LTS
- **RAM**: 256GB minimum
- **GPU**: NVIDIA RTX PRO 6000 Blackwell Workstation Edition
  - 96GB GDDR7 VRAM
  - 24,064 CUDA cores
  - 752 Tensor cores
  - 1.79 TB/s memory bandwidth
- **Storage**: 500GB+ NVMe SSD recommended
- **Power**: 850W+ PSU recommended (GPU uses 600W TDP)
- **Network**: Stable internet connection for downloading models

## Pre-Installation Checklist

1. **Ubuntu Server Installation**
   - Fresh Ubuntu Server 24.04 LTS installation
   - Updated system packages: `sudo apt update && sudo apt upgrade -y`
   - SSH access configured
   - Static IP address (recommended for production)

2. **Hardware Verification**
   ```bash
   # Check system specs
   free -h                    # Verify RAM
   lspci | grep -i nvidia     # Verify GPU presence
   df -h                      # Check disk space
   ```

## 🚀 Installation Steps

The installation process is automated via a single setup script that handles all dependencies, configurations, and service initializations.

### 1. Clone the Repository

First, clone the project repository to your local machine.

```bash
git clone https://github.com/ImprobableStudios/Agentic_System_for_AI.git
cd Agentic_System_for_AI
```

### 2. Run the Setup Script

The `setup.sh` script is the entry point for the installation. It will automatically detect that it's running on Ubuntu and perform the necessary steps, including:
- Installing Docker and Docker Compose.
- Installing the NVIDIA Container Toolkit to enable GPU access for Docker.
- Installing and configuring native Ollama for GPU-accelerated inference.
- Generating secure credentials for all services.
- Pulling all required AI models.
- Starting all services using Docker Compose.

To run the script, make it executable and then run it:

```bash
chmod +x setup.sh
./setup.sh
```

**Alternative: Using Remote Ollama**

If you have Ollama running on another machine (such as a dedicated GPU server), you can configure the system to use it remotely:

```bash
# Use remote Ollama instance
./setup.sh --remote-ollama 192.168.1.100:11434
```

This approach is useful for:
- Sharing a powerful GPU server across multiple client machines
- Running the system on machines without GPU capabilities
- Centralized model management

The script will prompt you for `sudo` access at various points to install system-level packages.

The script will automatically:
- Install NVIDIA drivers and CUDA toolkit
- Configure Docker with NVIDIA runtime support
- Install and configure Ollama with GPU acceleration
- Set up all containerized services
- Download and configure AI models
- Apply system optimizations

### 3. NVIDIA GPU Configuration

The installation script handles GPU setup automatically, but you can verify:

```bash
# Check NVIDIA driver installation
nvidia-smi

# Verify CUDA installation
nvcc --version

# Test Docker GPU access
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

### 4. Model Configuration

Models are automatically configured from `config/models.conf` during setup (default: identical to `models-4gb.conf`).
For high-VRAM systems, copy the appropriate file:
```bash
cp config/models-96gb.conf config/models.conf   # For 96GB+ VRAM systems
cp config/models-200gb.conf config/models.conf  # For 200GB+ VRAM systems
```
- **Primary Model**: General-purpose reasoning (default: Llama4:Scout)
- **Code Model**: Code generation and analysis (default: codellama:34b)
- **Embedding Model**: Vector operations (default: jeffh/intfloat-e5-base-v2:f16)
- **Reranking Model**: Search optimization (default: jeffh/intfloat-e5-base-v2:f16)
- **Fast Model**: Quick tasks (default: mistral:7b-instruct-q8_0)

To customize models before installation:
```bash
# Edit the configuration file
nano config/models.conf

# Example: Change primary model
PRIMARY_MODEL="llama3.1:70b"
```

To add additional models after installation:
```bash
# List installed models
ollama list

# Pull additional models - these fit well in 96GB VRAM
ollama pull llama3.1:70b
ollama pull mixtral:8x22b

# Update configuration and regenerate LiteLLM config
./setup.sh --skip-prereqs
```

## Post-Installation Configuration

### 1. Firewall Configuration

The setup script configures UFW automatically. To modify:

```bash
# Check firewall status
sudo ufw status

# Add custom rules if needed
sudo ufw allow from 192.168.1.0/24 to any port 8080  # Example: Allow LAN access
```

### 2. GPU Performance Tuning

```bash
# Set GPU to persistence mode
sudo nvidia-smi -pm 1

# Set maximum performance mode
sudo nvidia-smi -pl 450  # Adjust based on your GPU's TDP

# Configure GPU boost clocks (optional)
sudo nvidia-smi -ac 8001,1980  # Memory,GPU clocks (check your GPU specs)
```

### 3. System Resource Limits

The script sets optimal limits, but you can adjust in `/etc/security/limits.d/99-agentic-ai.conf`:

* soft memlock unlimited
* hard memlock unlimited
* soft stack unlimited
* hard stack unlimited

### 3.5 GPU Performance Tuning for Blackwell GPU (600W TDP)

To optimize your Blackwell GPU for higher performance (600W TDP), apply the following settings:

```bash
# Set GPU to persistence mode
sudo nvidia-smi -pm 1

# Set maximum performance mode (600W TDP for Blackwell)
sudo nvidia-smi -pl 600

# Configure GPU boost clocks (check your specific GPU capabilities)
# Blackwell GPUs have different clock profiles
sudo nvidia-smi -lgc 2100,2800  # Min,Max GPU clocks (example values)
```

### 4. Service Management

```bash
# View all services
docker-compose ps

# Restart a specific service
docker-compose restart litellm

# View logs
docker-compose logs -f open-webui

# Stop all services
docker-compose down

# Start all services
docker-compose up -d
```

## Monitoring and Maintenance

### 1. GPU Monitoring

```bash
# Real-time GPU monitoring
nvidia-smi -l 1

# Detailed GPU metrics
nvidia-smi --query-gpu=timestamp,name,utilization.gpu,utilization.memory,memory.used,memory.free,memory.total,temperature.gpu --format=csv -l 1

# Watch GPU usage in htop-like interface
nvtop  # Install with: sudo apt install nvtop
```

### 2. System Monitoring

Access monitoring dashboards:
- **Grafana**: http://grafana.local
  - Default user: admin
  - Password: Check `.env` file
- **Prometheus**: http://prometheus.local
- **GPU Dashboard**: Pre-configured in Grafana

### 3. Log Management

```bash
# View consolidated logs
docker-compose logs -f

# Check Ollama logs
journalctl -u ollama -f

# View GPU driver logs
dmesg | grep -i nvidia
```

## Troubleshooting

### Common Issues

1. **GPU Not Detected**
   ```bash
   # Reinstall NVIDIA drivers
   sudo apt remove --purge nvidia-*
   sudo apt autoremove
   sudo ubuntu-drivers autoinstall
   sudo reboot
   ```

2. **Ollama GPU Issues**
   
   **For Local Ollama:**
   ```bash
   # Check Ollama GPU usage
   curl http://localhost:11434/api/ps

   # Restart Ollama service
   sudo systemctl restart ollama
   ```
   
   **For Remote Ollama:**
   ```bash
   # Check remote Ollama GPU usage
   curl http://REMOTE_IP:11434/api/ps
   
   # Check connectivity
   ping REMOTE_IP
   
   # Check remote service (if you have SSH access)
   ssh user@REMOTE_IP "sudo systemctl status ollama"
   ```

3. **Out of Memory Errors**
   ```bash
   # Check memory usage
   free -h
   nvidia-smi

   # With 96GB VRAM, this is rare but if it happens:
   # Adjust Ollama memory limits
   sudo systemctl edit ollama
   # Add: Environment="OLLAMA_MAX_VRAM=92000000000"  # Leave 4GB free
   ```
   ```bash
   # Check memory usage
   free -h

   # Adjust Ollama memory limits
   sudo systemctl edit ollama
   # Add: Environment="OLLAMA_MAX_LOADED_MODELS=1"
   ```

4. **Docker GPU Runtime Issues**
   ```bash
   # Reconfigure NVIDIA runtime
   sudo nvidia-ctk runtime configure --runtime=docker
   sudo systemctl restart docker
   ```

### Performance Optimization

1. **CPU Governor Settings**
   ```bash
   # Set to performance mode
   echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
   ```

2. **Disable CPU Frequency Scaling**
   ```bash
   # Install cpufrequtils
   sudo apt install cpufrequtils

   # Set to maximum frequency
   sudo cpufreq-set -r -g performance
   ```

3. **NUMA Optimizations** (for multi-CPU systems)
   ```bash
   # Check NUMA topology
   numactl --hardware

   # Run Ollama with NUMA binding
   numactl --cpunodebind=0 --membind=0 ollama serve
   ```

## Security Considerations

1. **Network Security**
   - Services are bound to localhost by default
   - Use reverse proxy (Traefik) for external access
   - Configure SSL certificates for production

2. **Access Control**
   - Change default passwords in `.env`
   - Enable 2FA where supported
   - Regularly rotate API keys

3. **System Hardening**
   ```bash
   # Disable unnecessary services
   sudo systemctl disable bluetooth
   sudo systemctl disable cups

   # Enable automatic security updates
   sudo apt install unattended-upgrades
   sudo dpkg-reconfigure unattended-upgrades
   ```

## Backup and Recovery

1. **Automated Backups**
   ```bash
   # Run backup script
   ./scripts/backup.sh

   # Schedule daily backups
   sudo crontab -e
   # Add: 0 2 * * * /path/to/Agentic_System_for_AI/scripts/backup.sh
   ```

2. **Model Backup**
   ```bash
   # Backup Ollama models
   tar -czf ollama-models-backup.tar.gz ~/.ollama/models/
   ```

3. **Data Recovery**
   ```bash
   # Restore from backup
   ./scripts/backup.sh --restore /path/to/backup.tar.gz
   ```

## Integration with Existing Infrastructure

### Using External PostgreSQL
```bash
# Edit .env file
POSTGRES_HOST=your-postgres-server
POSTGRES_PORT=5432
POSTGRES_SSL_MODE=require
```

### Custom Domain Configuration
```bash
# Edit .env file
DOMAIN_NAME=ai.yourcompany.com

# Configure DNS A records pointing to your server
```

### LDAP/AD Integration
Configure in respective service settings:
- Open WebUI: Supports OIDC/OAuth2
- n8n: Supports LDAP authentication
- Grafana: Supports LDAP/OAuth2

## Support and Resources

- **Documentation**: Check `/docs` directory
- **Logs**: All logs in `/data/logs`
- **Community**: GitHub Issues and Discussions
- **GPU Support**: NVIDIA Developer Forums

Remember to regularly update the system and monitor resource usage for optimal performance.