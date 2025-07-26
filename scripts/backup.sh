#!/bin/bash
# scripts/backup.sh

# This script creates a compressed backup of the entire project directory.
# It's designed to be run from the project root.

# Stop on error
set -e

# --- Configuration ---
# Project directory is the parent of the script directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Backup directory from environment variable or default
BACKUP_DIR="${BACKUP_DIR:-$PROJECT_DIR/backups}"
# Backup filename with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILENAME="ai_system_backup_${TIMESTAMP}.tar.gz"
BACKUP_FILE_PATH="${BACKUP_DIR}/${BACKUP_FILENAME}"

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
    log_info "Starting backup process..."

    # Create backup directory if it doesn't exist
    if [ ! -d "$BACKUP_DIR" ]; then
        log_info "Backup directory not found. Creating '$BACKUP_DIR'..."
        mkdir -p "$BACKUP_DIR"
    fi

    log_info "Backing up project directory: ${PROJECT_DIR}"
    log_info "Backup destination: ${BACKUP_FILE_PATH}"

    # Create the compressed archive
    # Exclude the backup directory itself to prevent recursive backups
    # Exclude .git directory and other unnecessary files if any
    tar \
      --exclude="$BACKUP_DIR" \
      --exclude=".git" \
      --exclude="*.DS_Store" \
      -czf "${BACKUP_FILE_PATH}" \
      -C "${PROJECT_DIR}" .

    if [ $? -eq 0 ]; then
        log_success "Backup created successfully: ${BACKUP_FILE_PATH}"
        log_info "Backup size: $(du -sh "${BACKUP_FILE_PATH}" | awk '{print $1}')"
    else
        log_error "Backup failed. Please check the output for errors."
        exit 1
    fi
}

# --- Execution ---
main
