#!/bin/bash
# scripts/cleanup.sh

# This script stops and removes all Docker containers, networks,
# and volumes associated with the project. It also deletes
# the data and log directories to ensure a clean state.

# Stop on error
set -e

# --- Configuration ---
# Project directory is the parent of the script directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="${PROJECT_DIR}/data"
LOGS_DIR="${PROJECT_DIR}/logs"

# --- Logging ---
log_info() {
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - $1"
}

log_warning() {
    echo "[WARNING] $(date +"%Y-%m-%d %H:%M:%S") - $1"
}

log_error() {
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - $1"
}

log_success() {
    echo "[SUCCESS] $(date +"%Y-%m-%d %H:%M:%S") - $1"
}

# Check OS and set platform-specific configurations
check_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS detected
        DOCKER_COMPOSE="docker-compose"
        log_success "Running on macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux detected - check if it's Debian-based (Debian/Ubuntu)
        if command -v lsb_release &> /dev/null; then
            DISTRO=$(lsb_release -si)
            if [[ "$DISTRO" == "Ubuntu" || "$DISTRO" == "Debian" ]]; then
                DOCKER_COMPOSE="sudo docker compose"
                log_success "Running on Linux ($DISTRO)"
            else
                log_error "This script supports Debian-based systems (Ubuntu/Debian). Detected: $DISTRO"
                echo ""
                log_info "For other platforms, please check the documentation."
                exit 1
            fi
        else
            # Fallback check for Ubuntu without lsb_release
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
                    DOCKER_COMPOSE="sudo docker compose"
                    log_success "Running on Linux"
                else
                    log_error "This script supports Debian-based systems (Ubuntu/Debian). Detected: $ID"
                    echo ""
                    log_info "For other platforms, please check the documentation."
                    exit 1
                fi
            else
                log_error "Unable to determine Linux distribution. This script supports Debian-based systems (Ubuntu/Debian)."
                exit 1
            fi
        fi
    else
        log_error "Unsupported operating system: $OSTYPE"
        echo ""
        log_info "This script supports:"
        echo -e "${BLUE}  - macOS (Apple Silicon)${NC}"
        echo -e "${BLUE}  - Debian-based Linux (Ubuntu/Debian)${NC}"
        echo ""
        exit 1
    fi
}

# --- Main Logic ---
main() {
    log_info "Starting cleanup process..."

    # Verify OS and set Docker Compose command
    check_os 

    # Stop and remove Docker containers, networks, and volumes
    if [ -f "${PROJECT_DIR}/docker-compose.yml" ]; then
        log_info "Stopping and removing Docker services..."
        ${DOCKER_COMPOSE} down -v --remove-orphans
        log_success "Docker services stopped and removed."
    else
        log_warning "docker-compose.yml not found. Skipping Docker cleanup."
    fi

    # Delete data and log directories
    if [ -d "$DATA_DIR" ]; then
        log_info "Deleting data directory: $DATA_DIR"
        sudo rm -rf "$DATA_DIR"
        log_success "Data directory deleted."
    else
        log_warning "Data directory not found. Skipping."
    fi

    if [ -d "$LOGS_DIR" ]; then
        log_info "Deleting logs directory: $LOGS_DIR"
        sudo rm -rf "$LOGS_DIR"
        log_success "Logs directory deleted."
    else
        log_warning "Logs directory not found. Skipping."
    fi

    # Delete LiteLLM config file
    LITELLM_CONFIG="${PROJECT_DIR}/config/litellm/config.yaml"
    if [ -f "$LITELLM_CONFIG" ]; then
        log_info "Deleting LiteLLM config file: $LITELLM_CONFIG"
        rm -f "$LITELLM_CONFIG"
        log_success "LiteLLM config file deleted."
    else
        log_warning "LiteLLM config file not found. Skipping."
    fi

    if [ -f "${PROJECT_DIR}/.env" ]; then
        log_info "Deleting .env file"
        rm -f "${PROJECT_DIR}/.env"
        log_success ".env file deleted."
    else
        log_warning ".env file not found. Skipping."
    fi

    if [ -f "${PROJECT_DIR}/credentials.txt" ]; then
        log_info "Deleting credentials file"
        rm -f "${PROJECT_DIR}/credentials.txt"
        log_success "Credentials file deleted."
    else
        log_warning "Credentials file not found. Skipping."
    fi

    log_success "Cleanup process completed."
}

# --- Execution ---
main
