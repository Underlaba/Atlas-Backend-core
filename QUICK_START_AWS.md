# AWS Deployment Quick Start

## Pre-Requisites Checklist

Before starting deployment, ensure you have:

- [ ] AWS Account with billing enabled
- [ ] AWS CLI installed (optional, but recommended)
- [ ] SSH client (PuTTY for Windows, or built-in SSH for Mac/Linux)
- [ ] Domain name registered (e.g., underlaba.com)
- [ ] Access to domain DNS settings
- [ ] GitHub account with repository access

---

## Quick Deployment Steps

### 1. Launch EC2 Instance (5 minutes)

1. Log in to AWS Console → EC2
2. Click "Launch Instance"
3. Configure:
   - **Name:** `atlas-backend-production`
   - **AMI:** Ubuntu Server 22.04 LTS
   - **Instance Type:** `t3.small` (recommended) or `t3.micro` (budget)
   - **Key Pair:** Create new → Download `.pem` file
   - **Security Group:** Allow SSH (22), HTTP (80), HTTPS (443)
   - **Storage:** 20 GB gp3
4. Launch instance
5. Wait for "Running" status
6. Note Public IPv4 address

### 2. Configure DNS (5-30 minutes)

1. Go to your domain registrar
2. Add A Record:
   - **Host:** `api`
   - **Value:** EC2 Public IP
   - **TTL:** 3600
3. Wait for DNS propagation
4. Test: `ping api.yourdomain.com`

### 3. Connect to EC2 (2 minutes)

**Mac/Linux:**
```bash
chmod 400 ~/Downloads/atlas-backend-key.pem
ssh -i ~/Downloads/atlas-backend-key.pem ubuntu@YOUR_EC2_IP
```

**Windows PowerShell:**
```powershell
ssh -i C:\Users\YourName\Downloads\atlas-backend-key.pem ubuntu@YOUR_EC2_IP
```

### 4. Run Initial Setup Script (10 minutes)

```bash
# Download setup script
wget https://raw.githubusercontent.com/Underlaba/Atlas-Admin-Panel/main/backend-core/aws-setup.sh

# Make executable
chmod +x aws-setup.sh

# Run setup
./aws-setup.sh
```

This installs: Node.js, PostgreSQL, PM2, Nginx, Certbot

### 5. Configure Database (5 minutes)

```bash
sudo -u postgres psql
```

Execute:
```sql
CREATE DATABASE atlas_db;
CREATE USER atlas_user WITH ENCRYPTED PASSWORD 'YOUR_SECURE_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE atlas_db TO atlas_user;
\c atlas_db
GRANT ALL ON SCHEMA public TO atlas_user;
\q
```

### 6. Deploy Application (10 minutes)

```bash
# Clone repository
cd /var/www
git clone https://github.com/Underlaba/Atlas-Admin-Panel.git atlas-backend
cd atlas-backend/backend-core

# Install dependencies
npm ci --production

# Create .env file
nano .env
```

Paste and configure:
```env
NODE_ENV=production
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=atlas_db
DB_USER=atlas_user
DB_PASSWORD=YOUR_SECURE_PASSWORD
JWT_SECRET=GENERATE_WITH_COMMAND_BELOW
JWT_REFRESH_SECRET=GENERATE_WITH_COMMAND_BELOW
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d
LOG_LEVEL=info
```

Generate secrets:
```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"  # Copy to JWT_SECRET
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"  # Copy to JWT_REFRESH_SECRET
```

Save file (Ctrl+X, Y, Enter)

```bash
# Secure .env
chmod 600 .env

# Run migrations
node src/database/migrations/run.js

# Create logs directory
mkdir -p logs
```

### 7. Start Application with PM2 (5 minutes)

```bash
# Start app
pm2 start ecosystem.config.js

# Configure auto-start
pm2 startup
# Copy and execute the command output

pm2 save

# Check status
pm2 status
pm2 logs atlas-backend --lines 20

# Test locally
curl http://localhost:3000/api/v1/health
```

### 8. Configure Nginx (5 minutes)

```bash
# Copy config
sudo cp nginx.conf /etc/nginx/sites-available/atlas

# Edit with your domain
sudo nano /etc/nginx/sites-available/atlas
# Replace all 'api.yourdomain.com' with 'api.your-actual-domain.com'

# Enable site
sudo ln -s /etc/nginx/sites-available/atlas /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default

# Add rate limiting
sudo nano /etc/nginx/nginx.conf
# Add inside http block: limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;

# Test and reload
sudo nginx -t
sudo systemctl reload nginx

# Test HTTP
curl http://api.your-actual-domain.com/api/v1/health
```

### 9. Configure SSL (5 minutes)

```bash
# Obtain certificate
sudo certbot --nginx -d api.your-actual-domain.com

# Follow prompts:
# - Enter email
# - Agree to Terms (Y)
# - Share email (Y or N)
# - Redirect HTTP to HTTPS? → 2 (Yes)

# Test HTTPS
curl https://api.your-actual-domain.com/api/v1/health

# Test auto-renewal
sudo certbot renew --dry-run
```

### 10. Configure Firewall (2 minutes)

```bash
# Configure UFW
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
sudo ufw status

# Update AWS Security Group (in AWS Console):
# - Remove port 3000 rule
# - Keep only: 22, 80, 443
```

### 11. Configure Backups (5 minutes)

```bash
# Make scripts executable
chmod +x deploy.sh backup-db.sh health-check.sh

# Create password file
echo 'YOUR_DATABASE_PASSWORD' > .db_password
chmod 600 .db_password

# Test backup
DB_PASSWORD=$(cat .db_password) ./backup-db.sh

# Configure cron
crontab -e
```

Add:
```cron
0 2 * * * DB_PASSWORD=$(cat /var/www/atlas-backend/backend-core/.db_password) /var/www/atlas-backend/backend-core/backup-db.sh >> /var/log/atlas-backup.log 2>&1
0 3 * * 0 /var/www/atlas-backend/backend-core/health-check.sh >> /var/log/atlas-health.log 2>&1
```

### 12. Update Android App (Local Machine)

Edit `agent-app/app/src/main/java/com/underlaba/atlas/agentapp/api/ApiClient.kt`:

```kotlin
private const val BASE_URL = "https://api.your-actual-domain.com/api/v1/"
```

Build APK:
```bash
cd agent-app
./gradlew clean
./gradlew assembleRelease
```

Sign and distribute APK to testers.

---

## Testing Deployment

### Backend Tests

```bash
# Health check
curl https://api.your-actual-domain.com/api/v1/health

# Register agent
curl -X POST https://api.your-actual-domain.com/api/v1/agents/register \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"test-001","walletAddress":"0x1234567890123456789012345678901234567890"}'

# Test protected endpoint (use token from response)
curl -X POST https://api.your-actual-domain.com/api/v1/agents/assign-task \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"taskId":"task-001"}'
```

### Android App Tests

1. Install APK on device
2. Test registration
3. Verify JWT token storage
4. Test protected API calls
5. Check error handling

---

## Post-Deployment Checklist

- [ ] Backend accessible via HTTPS
- [ ] SSL certificate valid (green padlock)
- [ ] Health endpoint returns 200 OK
- [ ] Agent registration works
- [ ] JWT authentication works
- [ ] PM2 showing 2 instances running
- [ ] Database migrations applied
- [ ] Backups scheduled (cron)
- [ ] Firewall active (UFW)
- [ ] Android app connects to production API
- [ ] Logs are being written
- [ ] Auto-restart configured (PM2 startup)

---

## Monitoring Commands

```bash
# Check application status
pm2 status
pm2 monit

# View logs
pm2 logs atlas-backend --lines 100
sudo tail -f /var/log/nginx/atlas-access.log

# Run health check
cd /var/www/atlas-backend/backend-core
./health-check.sh

# Check disk space
df -h

# Check memory
free -h
```

---

## Common Issues

### Issue: "Connection refused" when testing backend

**Solution:**
```bash
pm2 status  # Check if app is running
pm2 logs atlas-backend  # Check for errors
pm2 restart atlas-backend
```

### Issue: "502 Bad Gateway" from Nginx

**Solution:**
```bash
curl http://localhost:3000/api/v1/health  # Test backend directly
sudo tail -f /var/log/nginx/atlas-error.log  # Check Nginx errors
sudo systemctl restart nginx
```

### Issue: SSL certificate not working

**Solution:**
```bash
sudo certbot certificates  # Check certificate status
sudo certbot renew --force-renewal  # Force renewal
sudo systemctl reload nginx
```

### Issue: Android app can't connect

**Solution:**
1. Verify BASE_URL is correct (HTTPS, correct domain)
2. Test backend URL in browser
3. Check Android internet permissions
4. Verify SSL certificate is valid

---

## Useful Resources

- **Detailed Guide:** `AWS_DEPLOYMENT_GUIDE.md`
- **Deployment Checklist:** `DEPLOYMENT_CHECKLIST.md`
- **General Deployment:** `DEPLOYMENT.md`
- **API Documentation:** `API_README.md`

---

## Estimated Total Time: 60-90 minutes

**Cost:** ~$15-18/month (t3.small + storage + data transfer)

---

## Support

If you encounter issues:
1. Check logs: `pm2 logs atlas-backend`
2. Run health check: `./health-check.sh`
3. Review AWS_DEPLOYMENT_GUIDE.md troubleshooting section
4. Check AWS EC2 status in console

---

**Ready to deploy? Start with Step 1!** 🚀
