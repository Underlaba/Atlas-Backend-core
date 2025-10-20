#!/bin/bash
# ========================================
# Atlas Backend - Quick Deployment Script
# Execute these commands ONE BY ONE in your SSH terminal
# ========================================

echo "Starting Atlas Backend deployment..."

# ========================================
# PHASE 1: Update System
# ========================================
echo "Phase 1: Updating system..."
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl wget git build-essential

# ========================================
# PHASE 2: Install Node.js 18.x
# ========================================
echo "Phase 2: Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
echo "Node.js version:"
node --version
npm --version

# ========================================
# PHASE 3: Install PostgreSQL
# ========================================
echo "Phase 3: Installing PostgreSQL..."
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
echo "PostgreSQL version:"
sudo -u postgres psql --version

# ========================================
# PHASE 4: Install PM2
# ========================================
echo "Phase 4: Installing PM2..."
sudo npm install -g pm2
pm2 --version

# ========================================
# PHASE 5: Install Nginx
# ========================================
echo "Phase 5: Installing Nginx..."
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
nginx -v

# ========================================
# PHASE 6: Install Certbot
# ========================================
echo "Phase 6: Installing Certbot..."
sudo apt install -y certbot python3-certbot-nginx
certbot --version

echo ""
echo "=========================================="
echo "Phase 1-6 Complete! Dependencies installed."
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Configure PostgreSQL database"
echo "2. Clone repository"
echo "3. Deploy application"
echo ""
