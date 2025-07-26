#!/bin/bash
# scripts/update.sh

# This script updates the AI system by pulling the latest
# Docker images and restarting the services.

# Stop on error
set -e

# --- Logging ---
log_info() {
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - $1"
}

log_success() {
    echo "[SUCCESS] $(date +"%Y-%m-%d %H:%M:%S") - $1"
}

log_error() {
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - $1" >&2
}

# --- Main Logic ---
main() {
    log_info "Starting update process..."

    # Pull the latest Docker images
    log_info "Pulling latest Docker images..."
    docker-compose pull
    if [ $? -ne 0 ]; then
        log_error "Failed to pull Docker images. Please check your network connection and Docker setup."
        exit 1
    fi
    log_success "Docker images updated successfully."

    # Restart services with the new images
    log_info "Restarting services to apply updates..."
    docker-compose up -d --force-recreate
    if [ $? -ne 0 ]; then
        log_error "Failed to restart services. Please check the container logs for more details."
        exit 1
    fi

    log_success "System updated and services restarted successfully."
}

# --- Execution ---
main
