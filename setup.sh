#!/bin/bash

# =============================================================================
# Agentic AI System Setup Script
# =============================================================================
# This script sets up the complete agentic AI system for both macOS (Apple Silicon)
# and Ubuntu (NVIDIA GPU) platforms. It automates the installation of prerequisites,
# configuration of services, and deployment of the entire stack.
#
# The script is designed to be idempotent, meaning it can be run multiple times
# without causing issues. It includes checks for existing installations and
# provides options for cleaning the environment.
#
# For detailed instructions, refer to the setup documentation in the 'docs' directory.
#
# Usage: ./setup.sh [--skip-prereqs] [--dev-mode] [--clean] [--remote-ollama HOST:PORT] [--help]
#
# Options:
#   --skip-prereqs  Skip prerequisite installation (useful for re-runs)
#   --dev-mode      Enable development mode with debug logging
#   --clean         Remove all data and containers before setup
#   --remote-ollama Use remote Ollama instance (e.g., --remote-ollama 1.2.3.4:11434)
#   --help          Show this help message
# =============================================================================

set -euo pipefail

# =============================================================================
# GLOBAL VARIABLES AND CONFIGURATION
# =============================================================================

# Shell colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="agentic-ai-system"

# Platform-specific variables (will be set by check_os)
PLATFORM=""
MODEL_CONFIG=""
REQUIRED_MEMORY_GB=0
REQUIRED_DISK_GB=0
DOCKER_COMPOSE="docker-compose"

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

# log_info: Print an informational message.
# Arguments:
#   $1: Message to print.
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# log_success: Print a success message.
# Arguments:
#   $1: Message to print.
log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# log_warning: Print a warning message.
# Arguments:
#   $1: Message to print.
log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# log_error: Print an error message.
# Arguments:
#   $1: Message to print.
log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Load model configuration from the platform-specific file.
# This function sources the appropriate .conf file based on the detected OS.
load_model_config() {
    if [[ -f "$MODEL_CONFIG" ]]; then
        source "$MODEL_CONFIG"
        log_success "Loaded model configuration from $MODEL_CONFIG"
    else
        log_error "Model configuration file not found: $MODEL_CONFIG"
        exit 1
    fi
}

# Parse command line arguments
SKIP_PREREQS=false
DEV_MODE=false
CLEAN_MODE=false
REMOTE_OLLAMA=""

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
        --remote-ollama)
            if [[ -n "${2:-}" ]]; then
                REMOTE_OLLAMA="$2"
                shift 2
            else
                echo "Error: --remote-ollama requires a HOST:PORT argument"
                show_help
                exit 1
            fi
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Error handling
error_exit() {
    log_error "$1"
    exit 1
}

# Clean environment
clean_environment() {
    log_info "Cleaning up the environment..."

    # Stop and remove all Docker containers
    if command -v ${DOCKER_COMPOSE} &> /dev/null; then
        log_info "Stopping and removing Docker containers..."
        ${DOCKER_COMPOSE} down -v --remove-orphans
    fi

    # Delete data directories
    log_info "Deleting data directories..."
    sudo rm -rf "${SCRIPT_DIR}/data"

    log_success "Environment cleaned successfully"
}

# Check OS and set platform-specific configurations
check_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS detected
        PLATFORM="macos"
        MODEL_CONFIG="${SCRIPT_DIR}/config/models-mac.conf"
        REQUIRED_MEMORY_GB=256
        REQUIRED_DISK_GB=500
        log_success "Running on macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux detected - check if it's Ubuntu 24.04
        if command -v lsb_release &> /dev/null; then
            DISTRO=$(lsb_release -si)
            VERSION=$(lsb_release -sr)
            if [[ "$DISTRO" == "Ubuntu" && "$VERSION" == "24.04" ]]; then
                PLATFORM="ubuntu"
                MODEL_CONFIG="${SCRIPT_DIR}/config/models-linux.conf"
                REQUIRED_MEMORY_GB=64
                REQUIRED_DISK_GB=1000
                DOCKER_COMPOSE="sudo docker compose"
                log_success "Running on Ubuntu 24.04"
            else
                log_error "This script supports Ubuntu 24.04. Detected: $DISTRO $VERSION"
                echo ""
                log_info "For other platforms, please check the documentation."
                exit 1
            fi
        else
            # Fallback check for Ubuntu without lsb_release
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                if [[ "$ID" == "ubuntu" && "$VERSION_ID" == "24.04" ]]; then
                    PLATFORM="ubuntu"
                    MODEL_CONFIG="${SCRIPT_DIR}/config/models-linux.conf"
                    REQUIRED_MEMORY_GB=64
                    REQUIRED_DISK_GB=1000
                    log_success "Running on Ubuntu 24.04"
                else
                    log_error "This script supports Ubuntu 24.04. Detected: $ID $VERSION_ID"
                    echo ""
                    log_info "For other platforms, please check the documentation."
                    exit 1
                fi
            else
                log_error "Unable to determine Linux distribution. This script supports Ubuntu 24.04."
                exit 1
            fi
        fi
    else
        log_error "Unsupported operating system: $OSTYPE"
        echo ""
        log_info "This script supports:"
        echo -e "${BLUE}  - macOS (Apple Silicon)${NC}"
        echo -e "${BLUE}  - Ubuntu 24.04 (NVIDIA GPU)${NC}"
        echo ""
        exit 1
    fi

    # Export platform variable for use throughout the script
    export PLATFORM
    export DOCKER_COMPOSE
    export MODEL_CONFIG
    export REQUIRED_MEMORY_GB
    export REQUIRED_DISK_GB
}

# Check hardware requirements
check_hardware() {
    log_info "Checking hardware requirements..."

    if [[ "$PLATFORM" == "macos" ]]; then
        # macOS hardware checks

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

    elif [[ "$PLATFORM" == "ubuntu" ]]; then
        # Ubuntu hardware checks
        
        # Check memory
        local memory_gb=$(free -g | awk '/^Mem:/{print $2}')
        if [[ $memory_gb -lt $REQUIRED_MEMORY_GB ]]; then
            log_warning "System has ${memory_gb}GB RAM, recommended: ${REQUIRED_MEMORY_GB}GB"
        else
            log_success "Memory check passed: ${memory_gb}GB RAM"
        fi

        # Check disk space
        local disk_gb=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
        if [[ $disk_gb -lt $REQUIRED_DISK_GB ]]; then
            log_warning "Available disk space: ${disk_gb}GB, recommended: ${REQUIRED_DISK_GB}GB"
        else
            log_success "Disk space check passed: ${disk_gb}GB available"
        fi

        # Check for NVIDIA GPU
        if command -v nvidia-smi &> /dev/null; then
            log_success "NVIDIA GPU detected:"
            nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
        else
            log_warning "NVIDIA GPU not detected. Please ensure NVIDIA drivers are installed."
            log_info "You may need to install NVIDIA drivers first. The script will continue but GPU acceleration may not be available."
        fi

        # Check for x86_64 architecture
        if [[ $(uname -m) == "x86_64" ]]; then
            log_success "x86_64 architecture detected (NVIDIA GPU optimizations will be applied)"
        else
            log_warning "Non-x86_64 architecture detected: $(uname -m). Some optimizations may not apply."
        fi

    else
        log_error "Unknown platform: $PLATFORM"
        exit 1
    fi
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

# Install prerequisites for macOS
install_prerequisites_macos() {
    if [[ "$SKIP_PREREQS" == "true" ]]; then
        log_info "Skipping prerequisite installation"
        return
    fi

    log_info "Installing macOS prerequisites..."

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

    if [[ -n "$REMOTE_OLLAMA" ]]; then
        log_info "Skipping Colima setup as remote Ollama is configured"
    else
        setup_colima
    fi

    log_success "macOS prerequisites installed successfully"
}

# Install NVIDIA drivers and CUDA toolkit for Ubuntu
install_nvidia_drivers() {
    log_info "Setting up NVIDIA GPU support..."

    # Check if NVIDIA drivers are already installed
    if command -v nvidia-smi &> /dev/null; then
        log_success "NVIDIA drivers already installed"
        return
    fi

    # Add NVIDIA package repositories
    log_info "Adding NVIDIA package repositories..."
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
    sudo dpkg -i cuda-keyring_1.1-1_all.deb
    rm cuda-keyring_1.1-1_all.deb

    # Update package list
    sudo apt-get update

    # Install NVIDIA drivers
    log_info "Installing NVIDIA drivers..."
    
    # Install recommended drivers
    sudo ubuntu-drivers install --gpgpu

    # Use this if you have a specific driver version to install
    # sudo apt-get install -y nvidia-driver-575 nvidia-dkms-575

    # Install CUDA toolkit
    log_info "Installing CUDA toolkit..."
    sudo apt-get install -y cuda-toolkit-12-2

    # Install NVIDIA Container Toolkit for Docker
    log_info "Installing NVIDIA Container Toolkit..."
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit

    # Restart Docker to apply changes
    sudo systemctl restart docker

    log_success "NVIDIA drivers and CUDA toolkit installed"
    log_warning "Please reboot the system to ensure NVIDIA drivers are properly loaded"
}

# Install prerequisites for Ubuntu 24.04
install_prerequisites_ubuntu() {
    if [[ "$SKIP_PREREQS" == "true" ]]; then
        log_info "Skipping prerequisite installation"
        return
    fi

    log_info "Installing Ubuntu prerequisites..."

    # Update system
    log_info "Updating system packages..."
    sudo apt-get update
    sudo apt-get upgrade -y

    # Install essential packages
    log_info "Installing essential packages..."
    sudo apt-get install -y \
        curl \
        wget \
        git \
        apache2-utils \
        nvtop \
        btop \
        jq \
        htop \
        net-tools \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        build-essential \
        python3-pip \
        python3-venv

    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        log_info "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        rm get-docker.sh
        log_success "Docker installed"
    else
        log_success "Docker already installed"
    fi

    # Install Docker Compose v2
    if ! docker compose version &> /dev/null; then
        log_info "Installing Docker Compose v2..."
        sudo apt-get install -y docker-compose-plugin
        log_success "Docker Compose installed"
    else
        log_success "Docker Compose already installed"
    fi

    # Install Ollama for Ubuntu
    if ! command -v ollama &> /dev/null; then
        log_info "Installing Ollama..."
        curl -fsSL https://ollama.ai/install.sh | sh
        log_success "Ollama installed"
    else
        log_success "Ollama already installed"
    fi

    # Install NVIDIA drivers and CUDA
    install_nvidia_drivers

    log_success "Ubuntu prerequisites installed successfully"
}

# Platform-agnostic prerequisites installer
install_prerequisites() {
    if [[ "$PLATFORM" == "macos" ]]; then
        install_prerequisites_macos
    elif [[ "$PLATFORM" == "ubuntu" ]]; then
        install_prerequisites_ubuntu
    else
        log_error "Unknown platform: $PLATFORM"
        exit 1
    fi
}

pull_models() {
    # Pull required models
    log_info "Pulling required AI models..."
    log_info "Loading models from configuration: $MODEL_CONFIG"

    for model in "${MODELS_TO_PULL[@]}"; do
        log_info "Pulling model: $model"
        if [[ -n "$REMOTE_OLLAMA" ]]; then
            # Use curl to pull models on remote Ollama instance
            if curl -s -X POST "http://${REMOTE_OLLAMA}/api/pull" -d "{\"name\":\"$model\"}" -H "Content-Type: application/json" > /dev/null; then
                log_success "Successfully requested pull for $model on remote Ollama"
            else
                log_warning "Failed to pull $model on remote Ollama, continuing..."
            fi
        else
            # Use local ollama command
            if ollama pull "$model"; then
                log_success "Successfully pulled $model"
            else
                log_warning "Failed to pull $model, continuing..."
            fi
        fi
    done

    # Verify models are available
    log_info "Verifying installed models..."
    local all_models_found=true
    local installed_models
    
    if [[ -n "$REMOTE_OLLAMA" ]]; then
        # Check remote Ollama instance
        installed_models=$(curl -s "http://${REMOTE_OLLAMA}/api/tags" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 || echo "")
    else
        # Check local Ollama instance
        installed_models=$(ollama list)
    fi

    for model in "${MODELS_TO_PULL[@]}"; do
        # Check if the model name from config is present in the 'ollama list' output.
        if echo "$installed_models" | grep -q -w "$model"; then
            log_success "Verified: Model '$model' is available."
        else
            # If an exact match isn't found, check for the base model name.
            # This handles cases where 'ollama pull' adds a default tag like ':latest'.
            local base_model_name
            base_model_name=$(echo "$model" | cut -d: -f1)
            if echo "$installed_models" | grep -q "$base_model_name"; then
                log_success "Verified: A variant of model '$model' is available."
            else
                log_warning "Verification failed: Model '$model' not found in 'ollama list'."
                all_models_found=false
            fi
        fi
    done

    if [[ "$all_models_found" = true ]]; then
        log_success "All configured models are available locally."
    else
        log_warning "Some models could not be verified. Please check the logs above."
    fi
}

setup_ollama_macos() {
    log_info "Setting up native Ollama for macOS..."

    # Start Ollama service
    log_info "Starting Ollama service..."
    if ! brew services start ollama; then
        log_error "Failed to start Ollama service via Homebrew."
        log_info "Please ensure Ollama is installed correctly ('brew install ollama')."
        exit 1
    fi

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

    pull_models

    log_success "Native Ollama setup for macOS completed"
}

setup_ollama_ubuntu() {
    log_info "Setting up native Ollama for Ubuntu..."

    # Add environment variables to ollama.service
    log_info "Adding environment variables to ollama.service..."
    OLLAMA_SERVICE_DIR="/etc/systemd/system/ollama.service.d"
    sudo mkdir -p "$OLLAMA_SERVICE_DIR"
    sudo tee "$OLLAMA_SERVICE_DIR/override.conf" > /dev/null <<EOF
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_FLASH_ATTENTION=true"
EOF
    sudo systemctl daemon-reload
    log_success "Ollama service configuration updated."

    # Start or restart Ollama service to apply changes
    log_info "Starting/restarting Ollama service..."
    sudo systemctl restart ollama

    # Enable the service to start on boot
    sudo systemctl enable ollama

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

    pull_models

    log_success "Native Ollama setup for Ubuntu completed"
}

# Dispatcher function for Ollama setup
setup_ollama() {
    if [[ -n "$REMOTE_OLLAMA" ]]; then
        setup_ollama_remote
    elif [[ "$PLATFORM" == "macos" ]]; then
        setup_ollama_macos
    elif [[ "$PLATFORM" == "ubuntu" ]]; then
        setup_ollama_ubuntu
    else
        log_error "Ollama setup not supported on this platform: $PLATFORM"
        exit 1
    fi
}

# Setup for remote Ollama instance
setup_ollama_remote() {
    log_info "Configuring for remote Ollama instance at $REMOTE_OLLAMA..."
    
    # Verify remote Ollama is accessible
    log_info "Testing connection to remote Ollama..."
    local max_attempts=10
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        if curl -s "http://${REMOTE_OLLAMA}/api/tags" > /dev/null 2>&1; then
            log_success "Remote Ollama is accessible at $REMOTE_OLLAMA"
            break
        fi

        if [[ $attempt -eq $max_attempts ]]; then
            error_exit "Remote Ollama is not accessible at $REMOTE_OLLAMA after $max_attempts attempts"
        fi

        log_info "Attempt $attempt/$max_attempts: Testing connection to $REMOTE_OLLAMA..."
        sleep 2
        ((attempt++))
    done

    pull_models

    log_success "Remote Ollama setup completed"
}

# Generate LiteLLM configuration from template
generate_litellm_config() {
    log_info "Generating LiteLLM configuration from template..."

    local template="${SCRIPT_DIR}/config/litellm/config.yaml.template"
    local output="${SCRIPT_DIR}/config/litellm/config.yaml"

    if [[ ! -f "$template" ]]; then
        log_error "LiteLLM template not found: $template"
        return 1
    fi

    # Create backup if config already exists
    if [[ -f "$output" ]]; then
        cp "$output" "${output}.backup"
        log_info "Backed up existing config to ${output}.backup"
    fi

    # Determine Ollama host URL based on remote/local setup
    local ollama_host
    if [[ -n "$REMOTE_OLLAMA" ]]; then
        ollama_host="http://${REMOTE_OLLAMA}"
    else
        ollama_host="http://host.docker.internal:11434"
    fi

    # Replace template variables with model configuration
    sed -e "s|{{PRIMARY_MODEL}}|${PRIMARY_MODEL}|g" \
        -e "s|{{CODE_MODEL}}|${CODE_MODEL}|g" \
        -e "s|{{EMBEDDING_MODEL}}|${EMBEDDING_MODEL}|g" \
        -e "s|{{RERANKING_MODEL}}|${RERANKING_MODEL}|g" \
        -e "s|{{SMALL_MODEL}}|${SMALL_MODEL}|g" \
        -e "s|{{LITELLM_MASTER_KEY}}|${LITELLM_MASTER_KEY}|g" \
        -e "s|{{OLLAMA_API_BASE}}|${ollama_host}|g" \
        "$template" > "$output"

    log_success "LiteLLM configuration generated successfully"
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

    # Set appropriate permissions - containers will modify as needed
    sudo chmod -R 777 "data/"
    
    # Newer instances of PostgreSQL require stricter permissions
    sudo chmod -R 700 "data/postgresql"
    sudo chown -R 999:999 "data/postgresql"
    
    log_success "Data directories created"
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
    local admin_password=$(openssl rand -hex 8)
    local postgres_password=$(openssl rand -hex 16)
    local litellm_key=sk-$(openssl rand -hex 16)

    # Generate secrets
    local searxng_secret=$(openssl rand -base64 32)
    local webui_secret=$(openssl rand -base64 32)
    local n8n_encryption_key=$(openssl rand -base64 32)
    local grafana_secret=$(openssl rand -base64 32)

    # Generate htpasswd hash
    local admin_hash=\'$(htpasswd -nb admin "$admin_password")\'

    # Replace placeholders in .env file
    sed -i.bak "s|CHANGE_ME_POSTGRES_PASSWORD|$postgres_password|g" .env
    sed -i.bak "s|CHANGE_ME_LITELLM_UI_PASSWORD|$admin_password|g" .env
    sed -i.bak "s|CHANGE_ME_N8N_PASSWORD|$admin_password|g" .env
    sed -i.bak "s|CHANGE_ME_GRAFANA_PASSWORD|$admin_password|g" .env
    sed -i.bak "s|CHANGE_ME_LITELLM_MASTER_KEY|$litellm_key|g" .env

    sed -i.bak "s|CHANGE_ME_WEBUI_SECRET_KEY|$webui_secret|g" .env
    sed -i.bak "s|CHANGE_ME_N8N_ENCRYPTION_KEY|$n8n_encryption_key|g" .env
    sed -i.bak "s|CHANGE_ME_SEARXNG_SECRET|$searxng_secret|g" .env
    sed -i.bak "s|CHANGE_ME_GRAFANA_SECRET|$grafana_secret|g" .env

    sed -i.bak "s|CHANGE_ME_ADMIN_HASH|$admin_hash|g" .env
    sed -i.bak "s|CHANGE_ME_PROMETHEUS_HASH|$admin_hash|g" .env
    sed -i.bak "s|CHANGE_ME_ALERTMANAGER_HASH|$admin_hash|g" .env
    sed -i.bak "s|CHANGE_ME_QDRANT_HASH|$admin_hash|g" .env

    # Set OLLAMA_HOST based on remote/local setup
    if [[ -n "$REMOTE_OLLAMA" ]]; then
        sed -i.bak "s|OLLAMA_HOST=|OLLAMA_HOST=$REMOTE_OLLAMA|g" .env
    fi

    # Make available to other functions
    export LITELLM_MASTER_KEY=$litellm_key

    # Generate MODEL_FILTER_LIST from configuration
    local model_filter_list=""
    for model in "${MODELS_TO_PULL[@]}"; do
        if [[ -z "$model_filter_list" ]]; then
            model_filter_list="$model"
        else
            model_filter_list="${model_filter_list};${model}"
        fi
    done
    sed -i.bak "s|CHANGE_ME_MODEL_FILTER_LIST|$model_filter_list|g" .env

    # Remove backup file created by sed
    if [ -f ".env.bak" ]; then
        rm .env.bak
    fi

    # Source .env to get the configured domain name
    source .env
    local domain_name="${DOMAIN_NAME:-local}"

    # Create credentials file for reference
    cat > credentials.txt << EOF
=============================================================================
AGENTIC AI SYSTEM CREDENTIALS
=============================================================================
Generated on: $(date)

ADMIN CREDENTIALS:
- Traefik Dashboard: admin / $admin_password
- Qdrant Database: admin / $admin_password
- n8n Workflow: admin / $admin_password
- Grafana: admin / $admin_password
- Prometheus: admin / $admin_password
- AlertManager: admin / $admin_password
- LiteLLM UI: admin / $admin_password

API KEYS:
- LiteLLM Master Key: $litellm_key

SERVICE URLS:
- Open WebUI: http://ai.${domain_name}
- LiteLLM API: http://api.${domain_name}
- LiteLLM UI: http://api.${domain_name}/ui
- n8n Workflow: http://n8n.${domain_name}
- Qdrant (Vector Database): http://qdrant.${domain_name}
- SearXNG (Search Engine): http://search.${domain_name}
- Traefik Dashboard: http://traefik.${domain_name}
- Grafana: http://grafana.${domain_name}
- Prometheus: http://prometheus.${domain_name}
- AlertManager: http://alertmanager.${domain_name}
- cAdvisor (Container Metrics): http://cadvisor.${domain_name}

NATIVE OLLAMA:
- API: http://localhost:11434

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
    ${DOCKER_COMPOSE} pull
    
    log_success "Docker images pulled successfully"
}

# Start services
start_services() {
    log_info "Starting services..."
    
    # Start core services first
    log_info "Starting core database services..."
    ${DOCKER_COMPOSE} up -d postgresql redis
    
    # Wait for databases to be ready
    log_info "Waiting for databases to be ready..."
    sleep 30
    
    # Start monitoring stack
    log_info "Starting monitoring services..."
    ${DOCKER_COMPOSE} up -d prometheus grafana alertmanager node-exporter postgres-exporter redis-exporter cadvisor loki promtail
    
    # Wait for monitoring to be ready
    sleep 20
    
    # Start remaining services
    log_info "Starting remaining services..."
    ${DOCKER_COMPOSE} up -d
    
    # Wait for all services to be ready
    log_info "Waiting for all services to be ready..."
    sleep 60
    
    log_success "All services started successfully"
}

# Verify installation
verify_installation() {
    log_info "Verifying installation..."
    
    # Check Ollama (local or remote)
    if [[ -n "$REMOTE_OLLAMA" ]]; then
        if curl -s "http://${REMOTE_OLLAMA}/api/tags" > /dev/null; then
            log_success "✓ Remote Ollama is accessible at $REMOTE_OLLAMA"
        else
            log_error "✗ Remote Ollama is not responding at $REMOTE_OLLAMA"
        fi
    else
        if curl -s http://localhost:11434/api/tags > /dev/null; then
            log_success "✓ Native Ollama is running"
        else
            log_error "✗ Native Ollama is not responding"
        fi
    fi
    
    # Check Docker services
    local services=("postgresql" "redis" "litellm" "qdrant" "searxng" "n8n" "open-webui" "traefik" "prometheus" "grafana" "alertmanager")
    
    for service in "${services[@]}"; do
        if ${DOCKER_COMPOSE} ps "$service" | grep -q "Up"; then
            log_success "✓ $service is running"
        else
            log_error "✗ $service is not running"
        fi
    done
    
    # Test LiteLLM connection to Ollama
    log_info "Testing LiteLLM connection to Ollama..."
    sleep 10
    if [[ -n "$REMOTE_OLLAMA" ]]; then
        if ${DOCKER_COMPOSE} exec -T litellm curl -s "http://${REMOTE_OLLAMA}/api/tags" > /dev/null; then
            log_success "✓ LiteLLM can connect to remote Ollama"
        else
            log_error "✗ LiteLLM cannot connect to remote Ollama"
        fi
    else
        if ${DOCKER_COMPOSE} exec -T litellm curl -s http://host.docker.internal:11434/api/tags > /dev/null; then
            log_success "✓ LiteLLM can connect to native Ollama"
        else
            log_warning "⚠ LiteLLM connection to native Ollama needs verification"
        fi
    fi
    
    log_success "Installation verification completed"
}

# Display final information
display_final_info() {
    # Source .env to get the configured domain name
    source .env
    local domain_name="${DOMAIN_NAME:-local}"

    log_success "==============================================================================="
    log_success "AGENTIC AI SYSTEM SETUP COMPLETED SUCCESSFULLY!"
    log_success "==============================================================================="
    echo ""
    log_info "Architecture Overview:"
    if [[ -n "$REMOTE_OLLAMA" ]]; then
        log_info "• Remote Ollama: Running at $REMOTE_OLLAMA"
        log_info "• LiteLLM: Containerized, connecting to remote Ollama at $REMOTE_OLLAMA"
    else
        log_info "• Native Ollama: Running on host at localhost:11434"
        log_info "• LiteLLM: Containerized, connecting to native Ollama via host.docker.internal:11434"
    fi
    log_info "• All other services: Containerized with Docker Compose"
    echo ""
    log_info "Service URLs (using configured domain: ${domain_name}):"
    log_info "• Open WebUI: http://ai.${domain_name}"
    log_info "• LiteLLM API: http://api.${domain_name}"
    log_info "• LiteLLM UI: http://api.${domain_name}/ui"
    log_info "• n8n Workflow: http://n8n.${domain_name}"
    log_info "• Qdrant (Vector Database): http://qdrant.${domain_name}"
    log_info "• SearXNG (Search Engine): http://search.${domain_name}"
    log_info "• Traefik Dashboard: http://traefik.${domain_name}"
    log_info "• Grafana: http://grafana.${domain_name}"
    log_info "• Prometheus: http://prometheus.${domain_name}"
    log_info "• AlertManager: http://alertmanager.${domain_name}"
    log_info "• cAdvisor (Container Metrics): http://cadvisor.${domain_name}"
    echo ""
    if [[ -n "$REMOTE_OLLAMA" ]]; then
        log_info "Remote Ollama:"
        log_info "• Service: Running at $REMOTE_OLLAMA"
        log_info "• API: http://$REMOTE_OLLAMA"
    else
        log_info "Native Ollama:"
        log_info "• Service: Running natively via Homebrew"
        log_info "• API: http://localhost:11434"
    fi
    log_info "• Models loaded from: $MODEL_CONFIG"
    log_info "  - Primary: $PRIMARY_MODEL"
    log_info "  - Code: $CODE_MODEL"
    log_info "  - Embedding: $EMBEDDING_MODEL"
    log_info "  - Reranking: $RERANKING_MODEL"
    log_info "  - Fast: $SMALL_MODEL"
    echo ""
    log_info "Management Commands:"
    log_info "• View logs: ${DOCKER_COMPOSE} logs -f [service_name]"
    log_info "• Restart services: ${DOCKER_COMPOSE} restart"
    log_info "• Stop all: ${DOCKER_COMPOSE} down"
    if [[ -n "$REMOTE_OLLAMA" ]]; then
        log_info "• Check Remote Ollama: curl http://$REMOTE_OLLAMA/api/tags"
    else
        log_info "• Restart Ollama: brew services restart ollama"
        log_info "• Check Ollama: ollama list"
    fi
    echo ""
    log_warning "IMPORTANT:"
    log_warning "• Credentials are saved in credentials.txt - store securely and delete after setup"
    log_warning "• Configure your domain in .env file for production use"
    log_warning "• Set up Tailscale for secure remote access"
    if [[ -z "$REMOTE_OLLAMA" ]]; then
        log_warning "• Native Ollama runs independently of Docker containers"
    fi
    echo ""
    log_success "Setup completed! Your agentic AI system is ready to use."
}

# Show help
show_help() {
    cat <<EOF
Agentic AI System Setup Script for MacOS

Usage: $0 [OPTIONS]

Options:
    --skip-prereqs    Skip prerequisite installation (useful for re-runs)
    --dev-mode        Enable development mode with debug logging
    --clean           Remove all data and containers
    --remote-ollama   Use remote Ollama instance (e.g., --remote-ollama 1.2.3.4:11434)
    --help            Show this help message

This script will:
    1. Install system prerequisites
    2. Install and configure Ollama for GPU acceleration
    3. Set up Docker containers for all services
    4. Configure monitoring and security
    5. Initialize AI models

For more information, see docs/setup_documentation.md
EOF
}

# Main execution
main() {
    cd "$SCRIPT_DIR"

    log_info "Initializing Agentic AI System setup..."
    log_info "======================================="
    log_info "Project: ${PROJECT_NAME}"

    check_os
    load_model_config

    if [[ "$CLEAN_MODE" == "true" ]]; then
        clean_environment
    else
        # These items are not needed for clean mode
        check_hardware
        install_prerequisites
        setup_ollama
    fi

    create_directories
    generate_secrets
    generate_litellm_config
    prepare_docker_images
    start_services
    verify_installation
    display_final_info

    log_success "Setup completed successfully!"
}

# Run main function
main "$@"
