# AWS EC2 Deployment Guide - Atlas Backend

## Overview

This guide provides step-by-step instructions for deploying the Atlas Backend on AWS EC2 with PostgreSQL, PM2, Nginx, and Let's Encrypt SSL.

**Estimated Time:** 60-90 minutes  
**Cost:** ~$10-15/month (t3.small + EBS storage)

---

## Phase 1: AWS EC2 Setup

### Step 1.1: Launch EC2 Instance

1. **Log in to AWS Console**
   - Go to https://console.aws.amazon.com
   - Navigate to EC2 Dashboard

2. **Launch Instance**
   - Click "Launch Instance"
   - **Name:** `atlas-backend-production`

3. **Choose AMI (Amazon Machine Image)**
   - Select: **Ubuntu Server 22.04 LTS (HVM), SSD Volume Type**
   - Architecture: 64-bit (x86)

4. **Choose Instance Type**
   - **Recommended:** `t3.small` (2 vCPU, 2 GiB RAM) - ~$15/month
   - **Budget Option:** `t3.micro` (2 vCPU, 1 GiB RAM) - ~$7.50/month
   - Note: t3.micro may be tight for PM2 cluster mode

5. **Key Pair**
   - Create new key pair or use existing
   - **Name:** `atlas-backend-key`
   - **Type:** RSA
   - **Format:** `.pem` (for SSH)
   - Download and save securely: `~/.ssh/atlas-backend-key.pem`

6. **Network Settings**
   - **VPC:** Default VPC (or create custom)
   - **Auto-assign Public IP:** Enable
   - **Firewall (Security Group):** Create new
   - **Security Group Name:** `atlas-backend-sg`

7. **Configure Security Group Rules**
   
   | Type          | Protocol | Port Range | Source        | Description          |
   |---------------|----------|------------|---------------|----------------------|
   | SSH           | TCP      | 22         | My IP         | SSH access           |
   | HTTP          | TCP      | 80         | 0.0.0.0/0     | HTTP (for redirect)  |
   | HTTPS         | TCP      | 443        | 0.0.0.0/0     | HTTPS access         |
   | Custom TCP    | TCP      | 3000       | 0.0.0.0/0     | Node.js (temp only)  |

   **Important:** Remove port 3000 rule after Nginx is configured!

8. **Configure Storage**
   - **Size:** 20 GB (minimum)
   - **Type:** gp3 (General Purpose SSD)
   - **IOPS:** 3000 (default)
   - **Throughput:** 125 MB/s (default)

9. **Advanced Details** (optional)
   - **IAM Role:** None (or attach if needed for S3 backups)
   - **Monitoring:** Enable detailed monitoring (optional, extra cost)

10. **Launch Instance**
    - Review settings
    - Click "Launch Instance"
    - Wait for instance to be "Running" (2-3 minutes)

### Step 1.2: Configure SSH Access

1. **Set Key Permissions** (Linux/Mac)
   ```bash
   chmod 400 ~/.ssh/atlas-backend-key.pem
   ```

   **Windows PowerShell:**
   ```powershell
   icacls "C:\Users\YourUsername\.ssh\atlas-backend-key.pem" /inheritance:r
   icacls "C:\Users\YourUsername\.ssh\atlas-backend-key.pem" /grant:r "$($env:USERNAME):(R)"
   ```

2. **Get Instance Public IP**
   - In EC2 Console, select your instance
   - Copy "Public IPv4 address" (e.g., 54.123.45.67)

3. **Connect via SSH**
   ```bash
   ssh -i ~/.ssh/atlas-backend-key.pem ubuntu@54.123.45.67
   ```

   **First connection:** Type "yes" to accept fingerprint

### Step 1.3: Initial Server Setup

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git build-essential

# Set timezone (optional)
sudo timedatectl set-timezone America/New_York  # Change to your timezone

# Check system info
uname -a
free -h
df -h
```

---

## Phase 2: Install Dependencies

### Step 2.1: Install Node.js 18.x

```bash
# Add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify installation
node --version  # Should be v18.x
npm --version   # Should be v9.x or higher
```

### Step 2.2: Install PostgreSQL 14

```bash
# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Start and enable PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Verify installation
sudo -u postgres psql --version  # Should be 14.x
```

### Step 2.3: Install PM2

```bash
# Install PM2 globally
sudo npm install -g pm2

# Verify installation
pm2 --version
```

### Step 2.4: Install Nginx

```bash
# Install Nginx
sudo apt install -y nginx

# Start and enable Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Verify installation
nginx -v
curl http://localhost  # Should show Nginx welcome page
```

### Step 2.5: Install Certbot (Let's Encrypt)

```bash
# Install Certbot with Nginx plugin
sudo apt install -y certbot python3-certbot-nginx

# Verify installation
certbot --version
```

---

## Phase 3: Database Configuration

### Step 3.1: Create Database and User

```bash
# Connect to PostgreSQL
sudo -u postgres psql
```

Execute in PostgreSQL:
```sql
-- Create database
CREATE DATABASE atlas_db;

-- Create user with strong password
CREATE USER atlas_user WITH ENCRYPTED PASSWORD 'CHANGE_THIS_SECURE_PASSWORD_32_CHARS_MIN';

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE atlas_db TO atlas_user;

-- Grant schema privileges (PostgreSQL 15+)
\c atlas_db
GRANT ALL ON SCHEMA public TO atlas_user;

-- Exit
\q
```

### Step 3.2: Configure PostgreSQL for Security

```bash
# Edit PostgreSQL configuration
sudo nano /etc/postgresql/14/main/postgresql.conf
```

Find and modify:
```conf
# Listen only on localhost (default is fine)
listen_addresses = 'localhost'

# Connection limits
max_connections = 100
```

```bash
# Edit authentication configuration
sudo nano /etc/postgresql/14/main/pg_hba.conf
```

Ensure this line exists:
```conf
# IPv4 local connections:
host    atlas_db        atlas_user      127.0.0.1/32            md5
```

```bash
# Restart PostgreSQL
sudo systemctl restart postgresql
```

### Step 3.3: Test Database Connection

```bash
# Test connection with password
psql -h localhost -U atlas_user -d atlas_db -c "SELECT version();"
```

Enter password when prompted. Should display PostgreSQL version.

---

## Phase 4: Deploy Backend Application

### Step 4.1: Create Application Directory

```bash
# Create directory
sudo mkdir -p /var/www
sudo chown $USER:$USER /var/www

# Navigate to directory
cd /var/www
```

### Step 4.2: Clone Repository

```bash
# Clone from GitHub
git clone https://github.com/Underlaba/Atlas-Admin-Panel.git atlas-backend

# Navigate to backend
cd atlas-backend/backend-core

# Verify files
ls -la
```

### Step 4.3: Install Dependencies

```bash
# Install production dependencies
npm ci --production

# Verify installation
npm list --depth=0
```

### Step 4.4: Configure Environment Variables

```bash
# Create .env file
nano .env
```

Add the following (replace with your values):
```env
# Application
NODE_ENV=production
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=atlas_db
DB_USER=atlas_user
DB_PASSWORD=YOUR_SECURE_DATABASE_PASSWORD

# JWT Authentication (generate new secrets!)
JWT_SECRET=YOUR_64_CHAR_HEX_SECRET
JWT_REFRESH_SECRET=YOUR_64_CHAR_HEX_REFRESH_SECRET
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

# Logging
LOG_LEVEL=info
```

**Generate JWT secrets:**
```bash
# Generate JWT_SECRET
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# Generate JWT_REFRESH_SECRET
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

Copy outputs to .env file.

```bash
# Secure .env file
chmod 600 .env
```

### Step 4.5: Run Database Migrations

```bash
# Run migrations
node src/database/migrations/run.js

# Verify tables created
psql -h localhost -U atlas_user -d atlas_db -c "\dt"
```

Should show `agents` and `users` tables.

### Step 4.6: Create Log Directory

```bash
# Create logs directory
mkdir -p logs

# Test server startup
node src/server.js
```

Press Ctrl+C to stop. Should see:
```
[Server] Starting Atlas Backend API...
[Database] Connecting to PostgreSQL...
[Database] PostgreSQL connection established successfully
[Server] Server is running on port 3000
```

---

## Phase 5: Configure PM2

### Step 5.1: Start Application with PM2

```bash
# Verify ecosystem.config.js exists
cat ecosystem.config.js

# Start application
pm2 start ecosystem.config.js

# Check status
pm2 status
pm2 logs atlas-backend --lines 20
```

Should show 2 instances running (cluster mode).

### Step 5.2: Configure PM2 Startup

```bash
# Generate startup script
pm2 startup

# Copy and execute the command output (will use sudo)
# Example: sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu

# Save PM2 process list
pm2 save
```

### Step 5.3: Test PM2 Auto-Restart

```bash
# Test application is accessible
curl http://localhost:3000/api/v1/health

# Simulate crash
pm2 kill

# Check if it auto-starts after reboot
sudo reboot

# After reboot, SSH back in and check
pm2 status  # Should show atlas-backend running
```

---

## Phase 6: Configure Nginx Reverse Proxy

### Step 6.1: Configure Domain DNS

**Before configuring Nginx, set up your domain:**

1. Go to your domain registrar (GoDaddy, Namecheap, Cloudflare, etc.)
2. Add an **A Record**:
   - **Name/Host:** `api` (or `@` for root domain)
   - **Type:** A
   - **Value:** Your EC2 Public IP (e.g., 54.123.45.67)
   - **TTL:** 3600 (1 hour)

3. Wait for DNS propagation (5-30 minutes)
4. Test: `ping api.yourdomain.com` (should resolve to EC2 IP)

### Step 6.2: Configure Nginx

```bash
# Copy Nginx configuration
sudo cp /var/www/atlas-backend/backend-core/nginx.conf /etc/nginx/sites-available/atlas

# Edit configuration with your domain
sudo nano /etc/nginx/sites-available/atlas
```

**Replace ALL instances of:**
- `api.yourdomain.com` → `api.your-actual-domain.com`

**Example:** If your domain is `underlaba.com`, use `api.underlaba.com`

### Step 6.3: Enable Nginx Site

```bash
# Create symbolic link
sudo ln -s /etc/nginx/sites-available/atlas /etc/nginx/sites-enabled/

# Remove default site (optional)
sudo rm /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# If OK, reload Nginx
sudo systemctl reload nginx
```

### Step 6.4: Test HTTP Access

```bash
# Test from server
curl http://api.your-actual-domain.com/api/v1/health

# Test from your local machine
# Open browser: http://api.your-actual-domain.com/api/v1/health
```

Should return JSON health status (might show SSL warning, we'll fix next).

---

## Phase 7: Configure SSL with Let's Encrypt

### Step 7.1: Obtain SSL Certificate

```bash
# Run Certbot with Nginx plugin
sudo certbot --nginx -d api.your-actual-domain.com

# Follow prompts:
# 1. Enter email address (for renewal notifications)
# 2. Agree to Terms of Service (Y)
# 3. Share email with EFF (optional, Y or N)
# 4. Redirect HTTP to HTTPS? Select option 2 (Redirect)
```

**Expected output:**
```
Congratulations! You have successfully enabled HTTPS on https://api.your-actual-domain.com
```

### Step 7.2: Test SSL Configuration

```bash
# Test HTTPS endpoint
curl https://api.your-actual-domain.com/api/v1/health

# Check certificate info
curl -vI https://api.your-actual-domain.com 2>&1 | grep -i 'expire'
```

**Test in browser:**
- Visit: `https://api.your-actual-domain.com/api/v1/health`
- Should show padlock icon (secure connection)

### Step 7.3: Test Auto-Renewal

```bash
# Dry run renewal
sudo certbot renew --dry-run

# Should see: "Congratulations, all simulated renewals succeeded"
```

Certbot automatically creates cron job for renewal.

### Step 7.4: Add Rate Limiting to Nginx

```bash
# Edit main Nginx config
sudo nano /etc/nginx/nginx.conf
```

Add inside `http` block (before `include /etc/nginx/sites-enabled/*;`):
```nginx
# Rate limiting zone
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
```

```bash
# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

---

## Phase 8: Configure Firewall

### Step 8.1: Configure UFW

```bash
# Allow SSH (IMPORTANT: Do this first!)
sudo ufw allow OpenSSH

# Allow Nginx (HTTP and HTTPS)
sudo ufw allow 'Nginx Full'

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

**Expected output:**
```
To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
```

### Step 8.2: Update EC2 Security Group

**Go back to AWS Console → EC2 → Security Groups:**

1. Select `atlas-backend-sg`
2. Edit Inbound Rules
3. **REMOVE** the rule for port 3000 (no longer needed)
4. Keep only: SSH (22), HTTP (80), HTTPS (443)

---

## Phase 9: Configure Automated Backups

### Step 9.1: Set Environment Variable for Backup Script

```bash
# Create secure password file
echo 'YOUR_DATABASE_PASSWORD' > /var/www/atlas-backend/backend-core/.db_password
chmod 600 /var/www/atlas-backend/backend-core/.db_password
```

### Step 9.2: Make Scripts Executable

```bash
cd /var/www/atlas-backend/backend-core

# Make scripts executable
chmod +x deploy.sh backup-db.sh health-check.sh
```

### Step 9.3: Test Backup Script

```bash
# Export password and run backup
export DB_PASSWORD=$(cat .db_password)
./backup-db.sh

# Check backup was created
ls -lh /var/backups/atlas/database/
```

### Step 9.4: Configure Cron for Daily Backups

```bash
# Edit crontab
crontab -e

# Select editor (nano is easiest)
```

Add this line:
```cron
# Daily backup at 2 AM
0 2 * * * DB_PASSWORD=$(cat /var/www/atlas-backend/backend-core/.db_password) /var/www/atlas-backend/backend-core/backup-db.sh >> /var/log/atlas-backup.log 2>&1

# Weekly health check on Sunday at 3 AM
0 3 * * 0 /var/www/atlas-backend/backend-core/health-check.sh >> /var/log/atlas-health.log 2>&1
```

Save and exit.

### Step 9.5: Test Cron Jobs (Optional)

```bash
# Run backup manually to test
DB_PASSWORD=$(cat /var/www/atlas-backend/backend-core/.db_password) ./backup-db.sh

# Run health check
./health-check.sh
```

---

## Phase 10: Update Android Agent App

### Step 10.1: Update API Base URL

**On your local development machine:**

Edit: `agent-app/app/src/main/java/com/underlaba/atlas/agentapp/api/ApiClient.kt`

**Change from:**
```kotlin
private const val BASE_URL = "http://10.0.2.2:3000/api/v1/"
```

**Change to:**
```kotlin
private const val BASE_URL = "https://api.your-actual-domain.com/api/v1/"
```

### Step 10.2: Build Release APK

```bash
cd agent-app

# Clean previous builds
./gradlew clean

# Build release APK
./gradlew assembleRelease
```

**Output location:**
`app/build/outputs/apk/release/app-release-unsigned.apk`

### Step 10.3: Sign APK (Production)

**Generate keystore (first time only):**
```bash
keytool -genkey -v -keystore atlas-release-key.keystore \
  -alias atlas -keyalg RSA -keysize 2048 -validity 10000

# Fill in details when prompted
# IMPORTANT: Save keystore password securely!
```

**Sign APK:**
```bash
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore atlas-release-key.keystore \
  app/build/outputs/apk/release/app-release-unsigned.apk atlas

# Enter keystore password
```

**Optimize APK:**
```bash
zipalign -v 4 app/build/outputs/apk/release/app-release-unsigned.apk \
  atlas-agent-app-v1.0.apk
```

**Final APK:** `atlas-agent-app-v1.0.apk` (ready for distribution)

---

## Phase 11: Testing

### Step 11.1: Test Backend Endpoints

```bash
# From your local machine (PowerShell):

# Test health endpoint
curl https://api.your-actual-domain.com/api/v1/health

# Test agent registration
curl -X POST https://api.your-actual-domain.com/api/v1/agents/register `
  -H "Content-Type: application/json" `
  -d '{\"deviceId\":\"test-device-001\",\"walletAddress\":\"0x1234567890123456789012345678901234567890\"}'

# Save the token from response
$token = "PASTE_TOKEN_HERE"

# Test protected endpoint
curl -X POST https://api.your-actual-domain.com/api/v1/agents/assign-task `
  -H "Authorization: Bearer $token" `
  -H "Content-Type: application/json" `
  -d '{\"taskId\":\"task-001\"}'
```

### Step 11.2: Test Android App

1. **Transfer APK to device:**
   - Email to yourself
   - Use Google Drive
   - USB transfer
   - ADB: `adb install atlas-agent-app-v1.0.apk`

2. **Install and test:**
   - Enable "Unknown Sources" if needed
   - Install APK
   - Open app
   - Test registration
   - Verify JWT token saved
   - Test protected API calls

### Step 11.3: Monitor Server

```bash
# SSH into EC2
ssh -i ~/.ssh/atlas-backend-key.pem ubuntu@54.123.45.67

# Check PM2 status
pm2 status
pm2 monit  # Real-time monitoring

# Check logs
pm2 logs atlas-backend --lines 50

# Check Nginx logs
sudo tail -f /var/log/nginx/atlas-access.log
sudo tail -f /var/log/nginx/atlas-error.log

# Run health check
cd /var/www/atlas-backend/backend-core
./health-check.sh
```

---

## Phase 12: Monitoring and Maintenance

### Daily Monitoring

```bash
# Check application status
pm2 status

# Check recent logs
pm2 logs --lines 100

# Run health check
./health-check.sh

# Check disk space
df -h

# Check memory usage
free -h
```

### Weekly Maintenance

```bash
# Verify backups
ls -lh /var/backups/atlas/database/

# Check SSL certificate expiry
sudo certbot certificates

# Review Nginx logs for errors
sudo grep "error" /var/log/nginx/atlas-error.log | tail -20

# Update system packages
sudo apt update
sudo apt list --upgradable
```

### Monthly Maintenance

```bash
# Apply security updates
sudo apt update && sudo apt upgrade -y

# Restart services if kernel updated
sudo reboot

# Review database size
psql -h localhost -U atlas_user -d atlas_db -c "SELECT pg_size_pretty(pg_database_size('atlas_db'));"

# Optimize database
psql -h localhost -U atlas_user -d atlas_db -c "VACUUM ANALYZE;"
```

---

## Troubleshooting

### Application Issues

**Problem: PM2 shows app crashed**
```bash
pm2 logs atlas-backend --err --lines 50
pm2 restart atlas-backend
```

**Problem: High memory usage**
```bash
pm2 monit  # Check memory per instance
# Consider reducing instances in ecosystem.config.js to 1
```

### Database Issues

**Problem: Can't connect to database**
```bash
sudo systemctl status postgresql
psql -h localhost -U atlas_user -d atlas_db -c "SELECT 1;"
```

**Problem: Database full**
```bash
# Check database size
psql -h localhost -U atlas_user -d atlas_db -c "SELECT pg_size_pretty(pg_database_size('atlas_db'));"

# Clean old data if needed
```

### Nginx Issues

**Problem: 502 Bad Gateway**
```bash
# Check backend is running
curl http://localhost:3000/api/v1/health

# Check Nginx logs
sudo tail -f /var/log/nginx/atlas-error.log

# Restart Nginx
sudo systemctl restart nginx
```

### SSL Issues

**Problem: Certificate expired**
```bash
sudo certbot renew --force-renewal
sudo systemctl reload nginx
```

---

## Cost Optimization

### Current Estimated Costs (Monthly)

| Resource          | Type          | Cost      |
|-------------------|---------------|-----------|
| EC2 Instance      | t3.small      | ~$15      |
| EBS Storage       | 20 GB gp3     | ~$2       |
| Data Transfer     | ~10 GB out    | ~$1       |
| **Total**         |               | **~$18**  |

### Ways to Reduce Costs

1. **Use t3.micro** (~$7.50/month)
   - Reduce PM2 instances to 1 in ecosystem.config.js
   - Suitable for low-medium traffic

2. **Reserved Instances**
   - 1-year commitment: ~30% savings
   - 3-year commitment: ~50% savings

3. **AWS Free Tier** (first 12 months)
   - 750 hours/month of t2.micro (1 GB RAM)
   - 30 GB EBS storage
   - 15 GB data transfer

4. **Use RDS Free Tier** instead of self-hosted PostgreSQL
   - 20 GB storage
   - 750 hours/month
   - Automated backups

---

## Security Best Practices

- ✅ SSH key-based authentication (no passwords)
- ✅ Firewall enabled (UFW)
- ✅ Security group configured (AWS)
- ✅ HTTPS with strong ciphers
- ✅ Database password-protected
- ✅ JWT secrets randomly generated
- ✅ .env file secured (chmod 600)
- ✅ Regular security updates
- ✅ PM2 auto-restart on crashes
- ✅ Automated database backups
- ✅ Rate limiting enabled
- ✅ Security headers configured

---

## Useful Commands Reference

```bash
# PM2
pm2 status                    # Check application status
pm2 logs atlas-backend        # View logs
pm2 monit                     # Real-time monitoring
pm2 restart atlas-backend     # Restart application
pm2 reload atlas-backend      # Zero-downtime reload

# Nginx
sudo nginx -t                 # Test configuration
sudo systemctl reload nginx   # Reload configuration
sudo tail -f /var/log/nginx/atlas-access.log  # View access logs

# PostgreSQL
psql -h localhost -U atlas_user -d atlas_db   # Connect to database
sudo systemctl restart postgresql              # Restart PostgreSQL

# System
df -h                         # Disk usage
free -h                       # Memory usage
htop                          # Process monitor (install: sudo apt install htop)
sudo reboot                   # Reboot server

# Deployment
./deploy.sh                   # Deploy updates
./backup-db.sh               # Manual backup
./health-check.sh            # Health check

# Certbot
sudo certbot certificates     # Check certificate status
sudo certbot renew           # Renew certificates
```

---

## Next Steps After Deployment

1. **Set Up Monitoring**
   - Configure AWS CloudWatch alarms
   - Set up UptimeRobot for external monitoring
   - Configure PM2 Plus (pm2.io) for app monitoring

2. **Configure CI/CD**
   - Set up GitHub Actions for automated testing
   - Configure automated deployment on push

3. **Implement Analytics**
   - Add logging for API usage
   - Track agent registrations
   - Monitor JWT token usage

4. **Scale as Needed**
   - Monitor resource usage
   - Upgrade instance type if needed
   - Consider load balancer for multiple instances

---

## Support

**Documentation:**
- Main Deployment Guide: `DEPLOYMENT.md`
- Deployment Checklist: `DEPLOYMENT_CHECKLIST.md`
- API Documentation: `API_README.md`

**AWS Resources:**
- EC2 Documentation: https://docs.aws.amazon.com/ec2/
- Let's Encrypt: https://letsencrypt.org/docs/

**Need Help?**
- Check logs: `pm2 logs atlas-backend`
- Run health check: `./health-check.sh`
- Review troubleshooting section above

---

**Deployment Complete!** 🎉

Your Atlas Backend is now running in production on AWS EC2 with:
- ✅ Public HTTPS access
- ✅ SSL certificate (Let's Encrypt)
- ✅ PM2 cluster mode (high availability)
- ✅ Nginx reverse proxy
- ✅ Automated backups
- ✅ Security hardening
- ✅ Android app ready for distribution
