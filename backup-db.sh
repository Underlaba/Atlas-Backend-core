#!/bin/bash

# Atlas Database Backup Script
# This script creates automated backups of the PostgreSQL database

set -e  # Exit on error

echo "=========================================="
echo "Atlas Database Backup"
echo "=========================================="

# Configuration
DB_NAME="atlas_db"
DB_USER="atlas_user"
BACKUP_DIR="/var/backups/atlas/database"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="atlas_db_backup_$TIMESTAMP.sql.gz"
RETENTION_DAYS=7  # Keep backups for 7 days

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Perform database backup
log_info "Starting database backup..."
log_info "Database: $DB_NAME"
log_info "Backup file: $BACKUP_FILE"

# Create backup using pg_dump
PGPASSWORD="$DB_PASSWORD" pg_dump \
    -h localhost \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    --format=plain \
    --clean \
    --if-exists \
    --no-owner \
    --no-acl | gzip > "$BACKUP_DIR/$BACKUP_FILE"

# Check if backup was successful
if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    log_info "Backup completed successfully"
    log_info "Backup size: $BACKUP_SIZE"
    log_info "Location: $BACKUP_DIR/$BACKUP_FILE"
else
    log_error "Backup failed"
    exit 1
fi

# Clean up old backups
log_info "Cleaning up old backups (keeping last $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "atlas_db_backup_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete

# Count remaining backups
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/atlas_db_backup_*.sql.gz 2>/dev/null | wc -l)
log_info "Total backups retained: $BACKUP_COUNT"

echo "=========================================="
log_info "Database backup completed"
echo "=========================================="

# Optional: Upload to cloud storage (uncomment and configure as needed)
# aws s3 cp "$BACKUP_DIR/$BACKUP_FILE" s3://your-bucket/atlas-backups/
# gsutil cp "$BACKUP_DIR/$BACKUP_FILE" gs://your-bucket/atlas-backups/
