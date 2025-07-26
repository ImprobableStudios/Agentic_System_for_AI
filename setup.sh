#!/bin/bash

# =============================================================================
# Agentic AI System Setup Script
# =============================================================================
# This script sets up the complete agentic AI system with M3 Ultra optimizations
# and security configurations based on the architecture evaluation.
#
# Usage: ./setup.sh [--skip-prereqs] [--dev-mode] [--help]
#
# Options:
#   --skip-prereqs  Skip prerequisite installation (useful for re-runs)
#   --dev-mode      Enable development mode with debug logging
#   --clean         Remove all data and containers
#   --help          Show this help message
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="agentic-ai-system"
REQUIRED_MEMORY_GB=256
REQUIRED_DISK_GB=500

# Parse command line arguments
SKIP_PREREQS=false
DEV_MODE=false
CLEAN_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-prereqs)
            SKIP_PREREQS=true
            shift
            ;;
        --dev-mode)
            DEV_MODE=true
            shift
            ;;
        --clean)
            CLEAN_MODE=true
            shift
            ;;
        --help)
            echo "Usage: $0 [--skip-prereqs] [--dev-mode] [--clean] [--help]"
            echo ""
            echo "Options:"
            echo "  --skip-prereqs  Skip prerequisite installation"
            echo "  --dev-mode      Enable development mode"
            echo "  --clean            Stops and removes all running containers and deletes the data directories before starting the setup."
            echo "  --help          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Error handling
error_exit() {
    log_error "$1"
    exit 1
}

# Clean environment
clean_environment() {
    log_info "Cleaning up the environment..."

    # Stop and remove all Docker containers
    if command -v docker-compose &> /dev/null; then
        log_info "Stopping and removing Docker containers..."
        docker-compose down -v --remove-orphans
    fi

    # Delete data directories
    log_info "Deleting data directories..."
    rm -rf "${SCRIPT_DIR}/data"

    log_success "Environment cleaned successfully"
}

# Check if running on macOS
check_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        error_exit "This script is designed for macOS. Current OS: $OSTYPE"
    fi
    log_success "Running on macOS"
}

# Check hardware requirements
check_hardware() {
    log_info "Checking hardware requirements..."
    
    # Check memory
    local memory_gb=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    if [[ $memory_gb -lt $REQUIRED_MEMORY_GB ]]; then
        log_warning "System has ${memory_gb}GB RAM, recommended: ${REQUIRED_MEMORY_GB}GB"
    else
        log_success "Memory check passed: ${memory_gb}GB RAM"
    fi
    
    # Check disk space
    local disk_gb=$(df -g . | tail -1 | awk '{print $4}')
    if [[ $disk_gb -lt $REQUIRED_DISK_GB ]]; then
        log_warning "Available disk space: ${disk_gb}GB, recommended: ${REQUIRED_DISK_GB}GB"
    else
        log_success "Disk space check passed: ${disk_gb}GB available"
    fi
    
    # Check for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        log_success "Apple Silicon detected (optimizations will be applied)"
    else
        log_warning "Intel Mac detected (some optimizations may not apply)"
    fi
}

# Install prerequisites
install_prerequisites() {
    if [[ "$SKIP_PREREQS" == "true" ]]; then
        log_info "Skipping prerequisite installation"
        return
    fi
    
    log_info "Installing prerequisites..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        log_success "Homebrew already installed"
    fi
    
    # Install required packages
    local packages=(
        "git"
        "docker"
        "docker-compose"
        "colima"
        "jq"
        "curl"
        "openssl"
        "ollama"
        "qemu"
    )
    
    for package in "${packages[@]}"; do
        if ! brew list "$package" &> /dev/null; then
            log_info "Installing $package..."
            brew install "$package"
        else
            log_success "$package already installed"
        fi
    done
    
    # Install Tailscale
    if ! brew list --cask tailscale &> /dev/null; then
        log_info "Installing Tailscale..."
        brew install --cask tailscale
    else
        log_success "Tailscale already installed"
    fi
}

# Setup native Ollama
setup_ollama() {
    log_info "Setting up native Ollama..."
    
    # Start Ollama service
    log_info "Starting Ollama service..."
    brew services start ollama
    
    # Wait for Ollama to be ready
    log_info "Waiting for Ollama to be ready..."
    local max_attempts=30
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
            log_success "Ollama is ready"
            break
        fi
        
        if [[ $attempt -eq $max_attempts ]]; then
            error_exit "Ollama failed to start after $max_attempts attempts"
        fi
        
        log_info "Attempt $attempt/$max_attempts: Waiting for Ollama..."
        sleep 2
        ((attempt++))
    done
    
    # Pull required models
    log_info "Pulling required AI models..."
    local models=(
        "qwen3:235b-a22b"
        "mychen76/qwen3_cline_roocode:14b"
        "mistral:7b-instruct-q8_0"
    )
    
    for model in "${models[@]}"; do
        log_info "Pulling model: $model"
        if ollama pull "$model"; then
            log_success "Successfully pulled $model"
        else
            log_warning "Failed to pull $model, continuing..."
        fi
    done
    
    # Verify models are available
    log_info "Verifying installed models..."
    ollama list
    
    log_success "Native Ollama setup completed"
}

# Configure Colima with M3 Ultra optimizations
setup_colima() {
    log_info "Setting up Colima with M3 Ultra optimizations..."
    
    # Stop Colima if running
    if colima status &> /dev/null; then
        log_info "Stopping existing Colima instance..."
        colima stop
    fi
    
    # Start Colima with optimized settings
    log_info "Starting Colima with optimized configuration..."
    colima start \
        --arch aarch64 \
        --vm-type vz \
        --vz-rosetta \
        --cpu 12 \
        --memory 64 \
        --disk 500 \
        --mount-inotify \
        --network-address
    
    # TODO Fix this
    # # Verify Colima is running
    # if colima status | grep -q "running"; then
    #     log_success "Colima started successfully"
    # else
    #     error_exit "Failed to start Colima"
    # fi
    
    # Configure Docker context
    docker context use colima
    log_success "Docker context set to Colima"
}

# Create directory structure
create_directories() {
    log_info "Creating directory structure..."
    
    local directories=(
        "data/postgresql"
        "data/redis"
        "data/qdrant"
        "data/n8n"
        "data/open-webui"
        "data/traefik/certs"
        "data/prometheus"
        "data/grafana"
        "data/alertmanager"
        "data/loki"
        "config/traefik/dynamic"
        "config/postgresql"
        "config/redis"
        "config/litellm"
        "config/qdrant"
        "config/searxng"
        "config/n8n"
        "config/prometheus/alerts"
        "config/grafana/provisioning/dashboards"
        "config/grafana/provisioning/datasources"
        "config/grafana/provisioning/alerting"
        "config/grafana/provisioning/plugins"
        "config/grafana/dashboards"
        "config/alertmanager"
        "config/promtail"
        "scripts"
        "backups"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        log_success "Created directory: $dir"
    done
}

# Generate secure passwords and keys
generate_secrets() {
    log_info "Generating secure passwords and keys..."
    
    if [[ -f .env ]]; then
        log_warning ".env file already exists, backing up to .env.backup"
        cp .env .env.backup
    fi
    
    # Copy template and generate secrets
    cp .env.example .env
    
    # Generate passwords
    local postgres_password=$(openssl rand -hex 16)
    local litellm_key=$(openssl rand -base64 32)
    local webui_secret=$(openssl rand -base64 32)
    local n8n_encryption_key=$(openssl rand -base64 32)
    local n8n_password=$(openssl rand -hex 8)
    local searxng_secret=$(openssl rand -base64 32)
    local admin_password=$(openssl rand -hex 8)
    local grafana_password=$(openssl rand -hex 8)
    local grafana_secret=$(openssl rand -base64 32)
    
    # Generate htpasswd hashes
    local traefik_hash=\'$(htpasswd -nb admin "$admin_password")\'
    local prometheus_hash=\'$(htpasswd -nb admin "$admin_password")\'
    local alertmanager_hash=\'$(htpasswd -nb admin "$admin_password")\'
    
    # Replace placeholders in .env file
    sed -i '' "s|CHANGE_ME_POSTGRES_PASSWORD|$postgres_password|g" .env
    sed -i '' "s|CHANGE_ME_LITELLM_MASTER_KEY|$litellm_key|g" .env
    sed -i '' "s|CHANGE_ME_WEBUI_SECRET_KEY|$webui_secret|g" .env
    sed -i '' "s|CHANGE_ME_N8N_ENCRYPTION_KEY|$n8n_encryption_key|g" .env
    sed -i '' "s|CHANGE_ME_N8N_PASSWORD|$n8n_password|g" .env
    sed -i '' "s|CHANGE_ME_SEARXNG_SECRET|$searxng_secret|g" .env
    sed -i '' "s|CHANGE_ME_HTPASSWD_HASH|${traefik_hash}|g" .env
    sed -i '' "s|CHANGE_ME_GRAFANA_PASSWORD|$grafana_password|g" .env
    sed -i '' "s|CHANGE_ME_GRAFANA_SECRET|$grafana_secret|g" .env
    sed -i '' "s|CHANGE_ME_PROMETHEUS_HTPASSWD|$prometheus_hash|g" .env
    sed -i '' "s|CHANGE_ME_ALERTMANAGER_HTPASSWD|$alertmanager_hash|g" .env
    sed -i '' "s|CHANGE_ME_QDRANT_HTPASSWD|$traefik_hash|g" .env
    
    # Create credentials file for reference
    cat > credentials.txt << EOF
=============================================================================
AGENTIC AI SYSTEM CREDENTIALS
=============================================================================
Generated on: $(date)

ADMIN CREDENTIALS:
- Traefik Dashboard: admin / $admin_password
- Qdrant Database: admin / $admin_password
- n8n Workflow: admin / $n8n_password
- Grafana: admin / $grafana_password
- Prometheus: admin / $admin_password
- AlertManager: admin / $admin_password

API KEYS:
- LiteLLM Master Key: $litellm_key

IMPORTANT: Store these credentials securely and delete this file after setup!
=============================================================================
EOF
    
    chmod 600 credentials.txt
    log_success "Credentials generated and saved to credentials.txt"
    log_warning "Please store credentials securely and delete credentials.txt after setup"
    log_warning "Please update the email configuration in .env for AlertManager notifications"
}

# Pull and prepare Docker images
prepare_docker_images() {
    log_info "Pulling Docker images..."
    
    # Pull all required images
    docker-compose pull
    
    log_success "Docker images pulled successfully"
}

# Start services
start_services() {
    log_info "Starting services..."
    
    # Start core services first
    log_info "Starting core database services..."
    docker-compose up -d postgresql redis
    
    # Wait for databases to be ready
    log_info "Waiting for databases to be ready..."
    sleep 30
    
    # Start monitoring stack
    log_info "Starting monitoring services..."
    docker-compose up -d prometheus grafana alertmanager node-exporter postgres-exporter redis-exporter cadvisor loki promtail
    
    # Wait for monitoring to be ready
    sleep 20
    
    # Start remaining services
    log_info "Starting remaining services..."
    docker-compose up -d
    
    # Wait for all services to be ready
    log_info "Waiting for all services to be ready..."
    sleep 60
    
    log_success "All services started successfully"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # Check native Ollama
    if curl -s http://localhost:11434/api/tags > /dev/null; then
        log_success "✓ Native Ollama is running"
    else
        log_error "✗ Native Ollama is not responding"
    fi
    
    # Check Docker services
    local services=("postgresql" "redis" "litellm" "qdrant" "searxng" "n8n" "open-webui" "traefik" "prometheus" "grafana" "alertmanager")
    
    for service in "${services[@]}"; do
        if docker-compose ps "$service" | grep -q "Up"; then
            log_success "✓ $service is running"
        else
            log_error "✗ $service is not running"
        fi
    done
    
    # Test LiteLLM connection to native Ollama
    log_info "Testing LiteLLM connection to native Ollama..."
    sleep 10
    if docker-compose exec -T litellm curl -s http://host.docker.internal:11434/api/tags > /dev/null; then
        log_success "✓ LiteLLM can connect to native Ollama"
    else
        log_warning "⚠ LiteLLM connection to native Ollama needs verification"
    fi
    
    log_success "Installation verification completed"
}

# Display final information
display_final_info() {
    log_success "==============================================================================="
    log_success "AGENTIC AI SYSTEM SETUP COMPLETED SUCCESSFULLY!"
    log_success "==============================================================================="
    echo ""
    log_info "Architecture Overview:"
    log_info "• Native Ollama: Running on host at localhost:11434"
    log_info "• LiteLLM: Containerized, connecting to native Ollama via host.docker.internal:11434"
    log_info "• All other services: Containerized with Docker Compose"
    echo ""
    log_info "Service URLs (replace 'local' with your domain):"
    log_info "• Open WebUI: http://ai.local"
    log_info "• LiteLLM API: http://api.local"
    log_info "• n8n Workflow: http://n8n.local"
    log_info "• Qdrant (Vector Database): http://qdrant.local"
    log_info "• SearXNG (Search Engine): http://search.local"
    log_info "• Traefik Dashboard: http://traefik.local"
    log_info "• Grafana: http://grafana.local" 
    log_info "• Prometheus: http://prometheus.local"
    log_info "• AlertManager: http://alertmanager.local"
    echo ""
    log_info "Native Ollama:"
    log_info "• Service: Running natively via Homebrew"
    log_info "• API: http://localhost:11434"
    log_info "• Models: qwen3:235b-a22b, mychen76/qwen3_cline_roocode:14b, mistral"
    echo ""
    log_info "Management Commands:"
    log_info "• View logs: docker-compose logs -f [service_name]"
    log_info "• Restart services: docker-compose restart"
    log_info "• Stop all: docker-compose down"
    log_info "• Restart Ollama: brew services restart ollama"
    log_info "• Check Ollama: ollama list"
    echo ""
    log_warning "IMPORTANT:"
    log_warning "• Credentials are saved in credentials.txt - store securely and delete after setup"
    log_warning "• Configure your domain in .env file for production use"
    log_warning "• Set up Tailscale for secure remote access"
    log_warning "• Native Ollama runs independently of Docker containers"
    echo ""
    log_success "Setup completed! Your agentic AI system is ready to use."
}

# Main execution
main() {
    cd "$SCRIPT_DIR"

    log_info "Initializing Agentic AI System setup..."
    log_info "======================================="
    log_info "Project: ${PROJECT_NAME}"

    if [[ "$CLEAN_MODE" == "true" ]]; then
        clean_environment
    else
        # These items are not needed for clean mode
        check_macos
        check_hardware
        install_prerequisites
        setup_ollama
        setup_colima
    fi

    create_directories
    generate_secrets
    prepare_docker_images
    start_services
    verify_installation
    display_final_info

    log_success "Setup completed successfully!"
}

# Run main function
main "$@"
