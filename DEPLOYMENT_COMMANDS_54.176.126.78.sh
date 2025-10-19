# ========================================
# AWS EC2 Deployment Script
# Instance IP: 54.176.126.78
# Date: October 19, 2025
# ========================================

# IMPORTANT: Copy these commands one by one (or in groups) to your EC2 instance after SSH connection

# ========================================
# PHASE 1: SYSTEM SETUP
# ========================================

# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git build-essential

# ========================================
# PHASE 2: INSTALL NODE.JS 18.x
# ========================================

# Add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify installation
node --version  # Should show v18.x
npm --version   # Should show v9.x or higher

# ========================================
# PHASE 3: INSTALL POSTGRESQL 14
# ========================================

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Start and enable PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Verify installation
sudo -u postgres psql --version

# ========================================
# PHASE 4: CONFIGURE DATABASE
# ========================================

# Connect to PostgreSQL
sudo -u postgres psql

# IMPORTANT: Execute these SQL commands inside PostgreSQL prompt:
# ------------------------------------------------------------------
# CREATE DATABASE atlas_db;
# CREATE USER atlas_user WITH ENCRYPTED PASSWORD 'Atlas2025SecurePass!';
# GRANT ALL PRIVILEGES ON DATABASE atlas_db TO atlas_user;
# \c atlas_db
# GRANT ALL ON SCHEMA public TO atlas_user;
# \q
# ------------------------------------------------------------------

# Test database connection (run after exiting psql)
psql -h localhost -U atlas_user -d atlas_db -c "SELECT version();"
# Password: Atlas2025SecurePass!

# ========================================
# PHASE 5: INSTALL PM2 AND NGINX
# ========================================

# Install PM2 globally
sudo npm install -g pm2

# Verify PM2
pm2 --version

# Install Nginx
sudo apt install -y nginx

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Verify Nginx
nginx -v

# Test Nginx is working
curl http://localhost

# ========================================
# PHASE 6: INSTALL CERTBOT (FOR SSL)
# ========================================

# Install Certbot with Nginx plugin
sudo apt install -y certbot python3-certbot-nginx

# Verify Certbot
certbot --version

# ========================================
# PHASE 7: CREATE APPLICATION DIRECTORY
# ========================================

# Create directory
sudo mkdir -p /var/www
sudo chown $USER:$USER /var/www

# Navigate to directory
cd /var/www

# ========================================
# PHASE 8: CLONE REPOSITORY
# ========================================

# Clone from GitHub
git clone https://github.com/Underlaba/Atlas-Admin-Panel.git atlas-backend

# Navigate to backend
cd atlas-backend/backend-core

# List files to verify
ls -la

# ========================================
# PHASE 9: INSTALL DEPENDENCIES
# ========================================

# Install production dependencies
npm ci --production

# Verify installation
npm list --depth=0

# ========================================
# PHASE 10: CONFIGURE ENVIRONMENT
# ========================================

# Create .env file
cat > .env << 'EOF'
# Application
NODE_ENV=production
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=atlas_db
DB_USER=atlas_user
DB_PASSWORD=Atlas2025SecurePass!

# JWT Authentication (CHANGE THESE!)
JWT_SECRET=CHANGE_THIS_TO_RANDOM_64_CHAR_HEX
JWT_REFRESH_SECRET=CHANGE_THIS_TO_RANDOM_64_CHAR_HEX
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

# Logging
LOG_LEVEL=info
EOF

# Generate JWT secrets and display them
echo ""
echo "=== GENERATE JWT SECRETS ==="
echo "Copy these values and update .env file:"
echo ""
echo "JWT_SECRET:"
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
echo ""
echo "JWT_REFRESH_SECRET:"
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
echo ""

# Edit .env file to add the generated secrets
nano .env
# Replace JWT_SECRET and JWT_REFRESH_SECRET with the generated values

# Secure .env file
chmod 600 .env

# ========================================
# PHASE 11: RUN DATABASE MIGRATIONS
# ========================================

# Run migrations
node src/database/migrations/run.js

# Verify tables created
psql -h localhost -U atlas_user -d atlas_db -c "\dt"
# Password: Atlas2025SecurePass!

# ========================================
# PHASE 12: CREATE LOG DIRECTORY
# ========================================

# Create logs directory
mkdir -p logs

# Test server startup (press Ctrl+C to stop after verification)
node src/server.js

# ========================================
# PHASE 13: START WITH PM2
# ========================================

# Start application with PM2
pm2 start ecosystem.config.js

# Check status
pm2 status

# View logs
pm2 logs atlas-backend --lines 20

# Configure auto-start on boot
pm2 startup
# IMPORTANT: Copy and execute the command that PM2 outputs!

# Save PM2 process list
pm2 save

# Test health endpoint
curl http://localhost:3000/api/v1/health

# ========================================
# PHASE 14: CONFIGURE NGINX
# ========================================

# Copy Nginx configuration
sudo cp nginx.conf /etc/nginx/sites-available/atlas

# Edit configuration
sudo nano /etc/nginx/sites-available/atlas
# IMPORTANT: Replace ALL instances of 'api.yourdomain.com' with your actual domain
# If you don't have a domain yet, use: 54.176.126.78

# Enable site
sudo ln -s /etc/nginx/sites-available/atlas /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Add rate limiting to main Nginx config
sudo nano /etc/nginx/nginx.conf
# Add this line inside the 'http' block (before 'include /etc/nginx/sites-enabled/*;'):
# limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

# Test Nginx configuration
sudo nginx -t

# If test passes, reload Nginx
sudo systemctl reload nginx

# Test HTTP access (replace with your domain or IP)
curl http://54.176.126.78/api/v1/health

# ========================================
# PHASE 15: CONFIGURE FIREWALL
# ========================================

# Allow SSH (IMPORTANT: Do this FIRST!)
sudo ufw allow OpenSSH

# Allow Nginx (HTTP and HTTPS)
sudo ufw allow 'Nginx Full'

# Enable firewall
sudo ufw enable
# Type 'y' when prompted

# Check status
sudo ufw status verbose

# ========================================
# PHASE 16: CONFIGURE SSL (If you have a domain)
# ========================================

# Only run this if you have configured a domain name in DNS!
# Replace 'api.yourdomain.com' with your actual domain

# Obtain SSL certificate
# sudo certbot --nginx -d api.yourdomain.com

# Follow prompts:
# 1. Enter email address
# 2. Agree to Terms (Y)
# 3. Share email (Y or N)
# 4. Redirect HTTP to HTTPS? → Select 2 (Yes)

# Test HTTPS (replace with your domain)
# curl https://api.yourdomain.com/api/v1/health

# Test auto-renewal
# sudo certbot renew --dry-run

# ========================================
# PHASE 17: CONFIGURE AUTOMATED BACKUPS
# ========================================

# Make scripts executable
chmod +x deploy.sh backup-db.sh health-check.sh

# Create password file for backup script
echo 'Atlas2025SecurePass!' > .db_password
chmod 600 .db_password

# Test backup script
DB_PASSWORD=$(cat .db_password) ./backup-db.sh

# Check backup was created
ls -lh /var/backups/atlas/database/

# Configure cron for automated backups
crontab -e
# Select nano (option 1 usually)

# Add these lines at the end:
# Daily backup at 2 AM
# 0 2 * * * DB_PASSWORD=$(cat /var/www/atlas-backend/backend-core/.db_password) /var/www/atlas-backend/backend-core/backup-db.sh >> /var/log/atlas-backup.log 2>&1
#
# Weekly health check on Sunday at 3 AM
# 0 3 * * 0 /var/www/atlas-backend/backend-core/health-check.sh >> /var/log/atlas-health.log 2>&1

# ========================================
# PHASE 18: FINAL VERIFICATION
# ========================================

# Run health check
./health-check.sh

# Check PM2 status
pm2 status

# Monitor application
pm2 monit
# Press Ctrl+C to exit

# View logs
pm2 logs atlas-backend --lines 50

# Check Nginx logs
sudo tail -20 /var/log/nginx/atlas-access.log
sudo tail -20 /var/log/nginx/atlas-error.log

# ========================================
# DEPLOYMENT COMPLETE!
# ========================================

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Your backend is now running at:"
echo "  HTTP:  http://54.176.126.78/api/v1/health"
echo "  HTTPS: https://your-domain.com/api/v1/health (if SSL configured)"
echo ""
echo "Useful commands:"
echo "  pm2 status          - Check application status"
echo "  pm2 logs            - View logs"
echo "  pm2 monit           - Monitor resources"
echo "  ./health-check.sh   - Run health check"
echo "  ./deploy.sh         - Deploy updates"
echo ""
echo "Next steps:"
echo "1. Test API endpoints from your local machine"
echo "2. Update Android app BASE_URL"
echo "3. Build and distribute APK"
echo "=========================================="

# ========================================
# TESTING FROM YOUR LOCAL MACHINE
# ========================================

# After deployment, test from your Windows PowerShell:

# Test health endpoint
# curl http://54.176.126.78/api/v1/health

# Test agent registration
# curl -X POST http://54.176.126.78/api/v1/agents/register `
#   -H "Content-Type: application/json" `
#   -d '{\"deviceId\":\"test-device-001\",\"walletAddress\":\"0x1234567890123456789012345678901234567890\"}'

# Save the token from response and test protected endpoint
# curl -X POST http://54.176.126.78/api/v1/agents/assign-task `
#   -H "Authorization: Bearer YOUR_TOKEN_HERE" `
#   -H "Content-Type: application/json" `
#   -d '{\"taskId\":\"task-001\"}'
