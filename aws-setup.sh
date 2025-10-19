#!/bin/bash

# AWS EC2 Initial Setup Script for Atlas Backend
# Run this script on a fresh Ubuntu EC2 instance after SSH connection

set -e  # Exit on error

echo "=========================================="
echo "Atlas Backend - AWS EC2 Initial Setup"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Ubuntu
if [ ! -f /etc/lsb-release ]; then
    log_error "This script is designed for Ubuntu. Exiting."
    exit 1
fi

log_info "Starting AWS EC2 setup..."

# Update system
log_info "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential tools
log_info "Installing essential tools..."
sudo apt install -y curl wget git build-essential

# Install Node.js 18.x
log_info "Installing Node.js 18.x..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
    log_info "Node.js installed: $(node --version)"
else
    log_info "Node.js already installed: $(node --version)"
fi

# Install PostgreSQL
log_info "Installing PostgreSQL..."
if ! command -v psql &> /dev/null; then
    sudo apt install -y postgresql postgresql-contrib
    sudo systemctl start postgresql
    sudo systemctl enable postgresql
    log_info "PostgreSQL installed: $(sudo -u postgres psql --version)"
else
    log_info "PostgreSQL already installed"
fi

# Install PM2
log_info "Installing PM2..."
if ! command -v pm2 &> /dev/null; then
    sudo npm install -g pm2
    log_info "PM2 installed: $(pm2 --version)"
else
    log_info "PM2 already installed: $(pm2 --version)"
fi

# Install Nginx
log_info "Installing Nginx..."
if ! command -v nginx &> /dev/null; then
    sudo apt install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    log_info "Nginx installed: $(nginx -v 2>&1)"
else
    log_info "Nginx already installed"
fi

# Install Certbot
log_info "Installing Certbot..."
if ! command -v certbot &> /dev/null; then
    sudo apt install -y certbot python3-certbot-nginx
    log_info "Certbot installed: $(certbot --version 2>&1 | head -1)"
else
    log_info "Certbot already installed"
fi

# Create application directory
log_info "Creating application directory..."
sudo mkdir -p /var/www
sudo chown $USER:$USER /var/www

echo "=========================================="
log_info "Initial setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Clone repository: cd /var/www && git clone https://github.com/Underlaba/Atlas-Admin-Panel.git atlas-backend"
echo "2. Configure database: sudo -u postgres psql"
echo "3. Follow AWS_DEPLOYMENT_GUIDE.md for detailed instructions"
echo ""
log_info "System information:"
echo "   Node.js: $(node --version)"
echo "   npm: $(npm --version)"
echo "   PostgreSQL: $(sudo -u postgres psql --version | cut -d' ' -f3)"
echo "   PM2: $(pm2 --version)"
echo "   Nginx: $(nginx -v 2>&1 | cut -d'/' -f2)"
echo "   Certbot: $(certbot --version 2>&1 | head -1 | cut -d' ' -f2)"
echo "=========================================="
