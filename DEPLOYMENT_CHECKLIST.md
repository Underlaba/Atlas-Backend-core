# Production Deployment Checklist

This checklist guides you through the complete production deployment process for Atlas Backend.

## Pre-Deployment Checklist

### Server Requirements
- [ ] VPS/Cloud server provisioned (AWS EC2, DigitalOcean, Azure, or GCP)
- [ ] Minimum 2 CPU cores, 2GB RAM, 20GB storage
- [ ] Ubuntu 20.04 LTS or higher installed
- [ ] Root or sudo access available
- [ ] Static IP address assigned
- [ ] Domain name configured (DNS A record pointing to server IP)

### Local Preparation
- [ ] All code changes committed to Git
- [ ] All tests passing locally
- [ ] Database migrations tested locally
- [ ] Environment variables documented
- [ ] JWT secrets generated
- [ ] Database password generated (strong, 32+ characters)

## Phase 1: Server Setup

### System Updates
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git build-essential
```
**Status:** [ ] Complete

### Node.js Installation
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
node --version  # Should be v18.x or higher
npm --version
```
**Status:** [ ] Complete

### PostgreSQL Installation
```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
sudo -u postgres psql --version  # Should be 14.x or higher
```
**Status:** [ ] Complete

### PM2 Installation
```bash
sudo npm install -g pm2
pm2 --version
```
**Status:** [ ] Complete

### Nginx Installation
```bash
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
nginx -v
```
**Status:** [ ] Complete

## Phase 2: Database Configuration

### Create Database and User
```bash
sudo -u postgres psql
```

Execute in PostgreSQL:
```sql
CREATE DATABASE atlas_db;
CREATE USER atlas_user WITH ENCRYPTED PASSWORD 'your_secure_password_here';
GRANT ALL PRIVILEGES ON DATABASE atlas_db TO atlas_user;
\q
```
**Status:** [ ] Complete

### Test Database Connection
```bash
psql -h localhost -U atlas_user -d atlas_db -c "SELECT version();"
```
**Status:** [ ] Complete

## Phase 3: Application Deployment

### Clone Repository
```bash
sudo mkdir -p /var/www
sudo chown $USER:$USER /var/www
cd /var/www
git clone https://github.com/Underlaba/Atlas-Admin-Panel.git atlas-backend
cd atlas-backend/backend-core
```
**Status:** [ ] Complete

### Install Dependencies
```bash
npm ci --production
```
**Status:** [ ] Complete

### Configure Environment Variables
```bash
cp .env.example .env
nano .env
```

Required variables in `.env`:
```env
NODE_ENV=production
PORT=3000

DB_HOST=localhost
DB_PORT=5432
DB_NAME=atlas_db
DB_USER=atlas_user
DB_PASSWORD=your_secure_database_password

JWT_SECRET=your_jwt_secret_64_chars
JWT_REFRESH_SECRET=your_refresh_secret_64_chars
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

LOG_LEVEL=info
```
**Status:** [ ] Complete

### Generate JWT Secrets
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"  # For JWT_SECRET
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"  # For JWT_REFRESH_SECRET
```
**Status:** [ ] Complete

### Run Database Migrations
```bash
node src/database/migrations/run.js
```
**Status:** [ ] Complete

### Create Log Directory
```bash
mkdir -p logs
```
**Status:** [ ] Complete

## Phase 4: PM2 Configuration

### Start Application with PM2
```bash
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

Copy and execute the command output by `pm2 startup`.

**Status:** [ ] Complete

### Verify Application is Running
```bash
pm2 status
pm2 logs atlas-backend --lines 50
curl http://localhost:3000/api/v1/health
```
**Status:** [ ] Complete

## Phase 5: Nginx Configuration

### Configure Nginx
```bash
sudo cp nginx.conf /etc/nginx/sites-available/atlas
```

Edit the file and replace `api.yourdomain.com` with your actual domain:
```bash
sudo nano /etc/nginx/sites-available/atlas
```

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/atlas /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```
**Status:** [ ] Complete

### Add Rate Limiting to Nginx
Edit `/etc/nginx/nginx.conf` and add to the `http` block:
```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
```

Reload Nginx:
```bash
sudo systemctl reload nginx
```
**Status:** [ ] Complete

## Phase 6: SSL Configuration

### Install Certbot
```bash
sudo apt install -y certbot python3-certbot-nginx
```
**Status:** [ ] Complete

### Obtain SSL Certificate
```bash
sudo certbot --nginx -d api.yourdomain.com
```

Follow the prompts and select option 2 (redirect HTTP to HTTPS).

**Status:** [ ] Complete

### Test SSL Configuration
```bash
sudo certbot renew --dry-run
```
**Status:** [ ] Complete

## Phase 7: Firewall Configuration

### Configure UFW
```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
sudo ufw status
```
**Status:** [ ] Complete

## Phase 8: Deployment Scripts

### Make Scripts Executable
```bash
chmod +x deploy.sh backup-db.sh health-check.sh
```
**Status:** [ ] Complete

### Set Up Database Backup Cron Job
```bash
crontab -e
```

Add this line to run daily backup at 2 AM:
```
0 2 * * * DB_PASSWORD='your_db_password' /var/www/atlas-backend/backend-core/backup-db.sh >> /var/log/atlas-backup.log 2>&1
```
**Status:** [ ] Complete

### Test Deployment Script
```bash
./deploy.sh
```
**Status:** [ ] Complete

### Test Health Check Script
```bash
./health-check.sh
```
**Status:** [ ] Complete

## Phase 9: Android App Configuration

### Update API Base URL
Edit `agent-app/app/src/main/java/com/underlaba/atlas/agentapp/api/ApiClient.kt`:

Change:
```kotlin
private const val BASE_URL = "http://10.0.2.2:3000/api/v1/"
```

To:
```kotlin
private const val BASE_URL = "https://api.yourdomain.com/api/v1/"
```
**Status:** [ ] Complete

### Build Release APK
```bash
cd agent-app
./gradlew assembleRelease
```
**Status:** [ ] Complete

### Sign APK (if not already configured)
Follow Android keystore generation and signing process.

**Status:** [ ] Complete

## Phase 10: Testing

### Test Backend Endpoints
```bash
# Health check
curl https://api.yourdomain.com/api/v1/health

# Agent registration
curl -X POST https://api.yourdomain.com/api/v1/agents/register \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "test-device-001",
    "walletAddress": "0x1234567890123456789012345678901234567890"
  }'

# Protected endpoint (use token from registration)
curl -X POST https://api.yourdomain.com/api/v1/agents/assign-task \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"taskId": "task-001"}'
```
**Status:** [ ] Complete

### Test Android App
- [ ] Install APK on physical device or emulator
- [ ] Test agent registration
- [ ] Verify JWT token storage
- [ ] Test protected API calls
- [ ] Check error handling

**Status:** [ ] Complete

## Phase 11: Monitoring Setup

### Set Up Monitoring Alerts
Options:
- [ ] PM2 Plus (pm2.io) - Application monitoring
- [ ] UptimeRobot - External uptime monitoring
- [ ] CloudWatch/Datadog - Infrastructure monitoring

**Status:** [ ] Complete

### Configure Log Rotation
```bash
sudo nano /etc/logrotate.d/atlas
```

Add:
```
/var/www/atlas-backend/backend-core/logs/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    missingok
    sharedscripts
    postrotate
        pm2 reloadLogs
    endscript
}
```
**Status:** [ ] Complete

## Phase 12: Security Hardening

### Security Checklist
- [ ] JWT secrets are strong (64+ characters, randomly generated)
- [ ] Database password is strong (32+ characters)
- [ ] `.env` file has restricted permissions (chmod 600)
- [ ] SSH key-based authentication enabled
- [ ] Root login disabled in SSH
- [ ] Firewall is active and properly configured
- [ ] SSL certificate is valid and auto-renewing
- [ ] Rate limiting is configured in Nginx
- [ ] CORS is properly configured in backend
- [ ] API endpoints use HTTPS only
- [ ] Database accepts connections only from localhost
- [ ] PM2 is configured to restart on failures
- [ ] Regular backups are automated
- [ ] Monitoring and alerting are active

**Status:** [ ] Complete

## Deployment Complete!

### Post-Deployment Verification
- [ ] Application is accessible via HTTPS
- [ ] SSL certificate is valid
- [ ] Health endpoint returns 200 OK
- [ ] Agent registration works
- [ ] JWT authentication works
- [ ] Database migrations applied
- [ ] PM2 is running and monitoring the app
- [ ] Logs are being written correctly
- [ ] Backups are scheduled
- [ ] Firewall is active

### Useful Commands
```bash
# View application logs
pm2 logs atlas-backend

# Monitor application
pm2 monit

# Check application status
pm2 status

# Restart application
pm2 restart atlas-backend

# Deploy updates
./deploy.sh

# Run health check
./health-check.sh

# Manual database backup
DB_PASSWORD='your_db_password' ./backup-db.sh

# View Nginx logs
sudo tail -f /var/log/nginx/atlas-access.log
sudo tail -f /var/log/nginx/atlas-error.log

# Check SSL certificate expiry
sudo certbot certificates
```

### Support Resources
- **Backend API Documentation**: `backend-core/API_README.md`
- **Agents Endpoint Documentation**: `backend-core/AGENTS_ENDPOINT_DOCS.md`
- **Integration Tests**: `backend-core/test-IT-*.ps1`
- **Main Documentation**: `DEPLOYMENT.md`

### Emergency Rollback
If deployment fails, restore from backup:
```bash
cd /var/www/atlas-backend
tar -xzf /var/backups/atlas/backend_backup_TIMESTAMP.tar.gz
pm2 restart atlas-backend
```

---

**Deployment Date:** _______________  
**Deployed By:** _______________  
**Domain:** _______________  
**Server IP:** _______________  
**Notes:** _______________
