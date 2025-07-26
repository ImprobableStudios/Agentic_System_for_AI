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

log_success() {
    echo "[SUCCESS] $(date +"%Y-%m-%d %H:%M:%S") - $1"
}

# --- Main Logic ---
main() {
    log_info "Starting cleanup process..."

    # Stop and remove Docker containers, networks, and volumes
    if [ -f "${PROJECT_DIR}/docker-compose.yml" ]; then
        log_info "Stopping and removing Docker services..."
        docker-compose down -v --remove-orphans
        log_success "Docker services stopped and removed."
    else
        log_warning "docker-compose.yml not found. Skipping Docker cleanup."
    fi

    # Delete data and log directories
    if [ -d "$DATA_DIR" ]; then
        log_info "Deleting data directory: $DATA_DIR"
        rm -rf "$DATA_DIR"
        log_success "Data directory deleted."
    else
        log_warning "Data directory not found. Skipping."
    fi

    if [ -d "$LOGS_DIR" ]; then
        log_info "Deleting logs directory: $LOGS_DIR"
        rm -rf "$LOGS_DIR"
        log_success "Logs directory deleted."
    else
        log_warning "Logs directory not found. Skipping."
    fi

    log_success "Cleanup process completed."
}

# --- Execution ---
main
