#!/bin/bash

# Atlas Backend Deployment Script
# This script automates the deployment process for the Atlas backend

set -e  # Exit on error

echo "=========================================="
echo "Atlas Backend Deployment"
echo "=========================================="

# Configuration
REPO_URL="https://github.com/Underlaba/Atlas-Admin-Panel.git"
APP_DIR="/var/www/atlas-backend"
BACKUP_DIR="/var/backups/atlas"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as correct user
if [ "$EUID" -eq 0 ]; then 
    log_error "Do not run this script as root. Use a dedicated deployment user."
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Step 1: Create backup of current deployment
log_info "Creating backup of current deployment..."
if [ -d "$APP_DIR" ]; then
    tar -czf "$BACKUP_DIR/backend_backup_$TIMESTAMP.tar.gz" -C "$APP_DIR" .
    log_info "Backup created: backend_backup_$TIMESTAMP.tar.gz"
else
    log_warn "No existing deployment found. Skipping backup."
fi

# Step 2: Navigate to application directory
log_info "Navigating to application directory..."
cd "$APP_DIR" || exit 1

# Step 3: Pull latest changes from Git
log_info "Pulling latest changes from Git..."
git fetch origin
git reset --hard origin/master
log_info "Git pull completed"

# Step 4: Navigate to backend-core
cd backend-core || exit 1

# Step 5: Install/update dependencies
log_info "Installing dependencies..."
npm ci --production
log_info "Dependencies installed"

# Step 6: Run database migrations
log_info "Running database migrations..."
if [ -f "src/database/migrations/run.js" ]; then
    node src/database/migrations/run.js
    log_info "Migrations completed"
else
    log_warn "No migration script found. Skipping migrations."
fi

# Step 7: Reload PM2 process
log_info "Reloading PM2 process..."
pm2 reload ecosystem.config.js --update-env
log_info "PM2 process reloaded"

# Step 8: Save PM2 configuration
pm2 save

# Step 9: Check application health
log_info "Checking application health..."
sleep 5  # Wait for app to start

# Check if app is running
if pm2 list | grep -q "atlas-backend"; then
    log_info "Application is running"
    
    # Check health endpoint
    HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/v1/health || echo "000")
    
    if [ "$HEALTH_CHECK" = "200" ]; then
        log_info "Health check passed (HTTP 200)"
    else
        log_error "Health check failed (HTTP $HEALTH_CHECK)"
        log_warn "Rolling back to previous version..."
        tar -xzf "$BACKUP_DIR/backend_backup_$TIMESTAMP.tar.gz" -C "$APP_DIR"
        pm2 reload ecosystem.config.js
        exit 1
    fi
else
    log_error "Application failed to start"
    exit 1
fi

# Step 10: Clean up old backups (keep last 5)
log_info "Cleaning up old backups..."
cd "$BACKUP_DIR"
ls -t backend_backup_*.tar.gz | tail -n +6 | xargs -r rm
log_info "Old backups cleaned"

# Deployment complete
echo "=========================================="
log_info "Deployment completed successfully!"
echo "=========================================="
log_info "Timestamp: $TIMESTAMP"
log_info "View logs: pm2 logs atlas-backend"
log_info "Monitor status: pm2 monit"
echo "=========================================="
