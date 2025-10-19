# Production Deployment Guide

This guide covers deploying the Atlas backend to a production environment accessible externally.

## Prerequisites

- VPS or cloud instance (AWS EC2, DigitalOcean, Azure, GCP)
- Domain name (optional but recommended)
- SSH access to server
- Basic Linux/Unix knowledge

## Server Requirements

### Minimum Specifications
- **CPU:** 2 cores
- **RAM:** 2GB
- **Storage:** 20GB SSD
- **OS:** Ubuntu 20.04 LTS or later

### Software Requirements
- Node.js 18.x or later
- PostgreSQL 14 or later
- Nginx (reverse proxy)
- PM2 (process manager)
- Certbot (SSL certificates)

## Step 1: Server Setup

### 1.1 Update System

```bash
sudo apt update
sudo apt upgrade -y
```

### 1.2 Install Node.js

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
node --version  # Should show v18.x or later
```

### 1.3 Install PostgreSQL

```bash
sudo apt install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 1.4 Install PM2

```bash
sudo npm install -g pm2
pm2 startup  # Follow the instructions output
```

### 1.5 Install Nginx

```bash
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

## Step 2: Database Configuration

### 2.1 Create Database and User

```bash
sudo -u postgres psql
```

```sql
CREATE DATABASE atlas_db;
CREATE USER atlas_user WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE atlas_db TO atlas_user;
\q
```

### 2.2 Configure PostgreSQL for Remote Access (if needed)

Edit `/etc/postgresql/14/main/postgresql.conf`:
```
listen_addresses = 'localhost'  # Keep as localhost if same server
```

Edit `/etc/postgresql/14/main/pg_hba.conf`:
```
local   atlas_db        atlas_user                              md5
```

Restart PostgreSQL:
```bash
sudo systemctl restart postgresql
```

## Step 3: Deploy Backend Code

### 3.1 Clone Repository

```bash
cd /var/www
sudo mkdir atlas
sudo chown $USER:$USER atlas
cd atlas
git clone https://github.com/Underlaba/Atlas-Backend-core.git backend
cd backend
```

### 3.2 Install Dependencies

```bash
npm install --production
```

### 3.3 Configure Environment Variables

```bash
cp .env.example .env
nano .env
```

Update with production values:
```env
# Server
NODE_ENV=production
PORT=3000

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=atlas_db
DB_USER=atlas_user
DB_PASSWORD=your_secure_password

# JWT (Generate secure secrets)
JWT_SECRET=generate_a_secure_random_string_here_minimum_64_characters
JWT_EXPIRES_IN=24h
JWT_REFRESH_SECRET=generate_another_secure_random_string_here_minimum_64_characters
JWT_REFRESH_EXPIRES_IN=7d

# CORS (Update with your domain)
CORS_ORIGIN=https://yourdomain.com

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

### 3.4 Generate Secure JWT Secrets

```bash
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
# Copy output to JWT_SECRET

node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
# Copy output to JWT_REFRESH_SECRET
```

### 3.5 Run Database Migrations

```bash
node src/database/migrations/run.js
```

## Step 4: Configure PM2

### 4.1 Create PM2 Ecosystem File

Create `ecosystem.config.js`:
```javascript
module.exports = {
  apps: [{
    name: 'atlas-backend',
    script: './src/server.js',
    instances: 2,
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
```

### 4.2 Start Application

```bash
mkdir logs
pm2 start ecosystem.config.js
pm2 save
pm2 startup  # Follow instructions if not done earlier
```

### 4.3 Verify Application is Running

```bash
pm2 status
pm2 logs atlas-backend
curl http://localhost:3000/api/v1/health
```

## Step 5: Configure Nginx Reverse Proxy

### 5.1 Create Nginx Configuration

```bash
sudo nano /etc/nginx/sites-available/atlas
```

Add configuration:
```nginx
upstream atlas_backend {
    server localhost:3000;
    keepalive 64;
}

server {
    listen 80;
    server_name api.yourdomain.com;  # Replace with your domain

    # Redirect to HTTPS (will be configured later)
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;  # Replace with your domain

    # SSL certificates (will be configured with Certbot)
    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Logging
    access_log /var/log/nginx/atlas-access.log;
    error_log /var/log/nginx/atlas-error.log;

    # Proxy settings
    location / {
        proxy_pass http://atlas_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /api/v1/health {
        proxy_pass http://atlas_backend/api/v1/health;
        access_log off;
    }
}
```

### 5.2 Enable Configuration

```bash
sudo ln -s /etc/nginx/sites-available/atlas /etc/nginx/sites-enabled/
sudo nginx -t  # Test configuration
sudo systemctl restart nginx
```

## Step 6: Configure SSL with Let's Encrypt

### 6.1 Install Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### 6.2 Obtain SSL Certificate

First, temporarily modify Nginx config to remove SSL directives:
```bash
sudo nano /etc/nginx/sites-available/atlas
```

Comment out SSL lines temporarily, then:
```bash
sudo nginx -t
sudo systemctl restart nginx
```

Obtain certificate:
```bash
sudo certbot --nginx -d api.yourdomain.com
```

Follow the prompts and choose to redirect HTTP to HTTPS.

### 6.3 Test Auto-Renewal

```bash
sudo certbot renew --dry-run
```

## Step 7: Configure Firewall

### 7.1 Enable UFW

```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
sudo ufw status
```

Should show:
```
Status: active

To                         Action      From
--                         ------      ----
OpenSSH                    ALLOW       Anywhere
Nginx Full                 ALLOW       Anywhere
```

## Step 8: Update Android App

### 8.1 Update API Base URL

Edit `agent-app/app/src/main/java/com/underlaba/atlas/agentapp/api/ApiClient.kt`:

```kotlin
object ApiClient {
    // Change from local to production URL
    private const val BASE_URL = "https://api.yourdomain.com/"  // Updated
    
    private val okHttpClient = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    private val retrofit = Retrofit.Builder()
        .baseUrl(BASE_URL)
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create())
        .build()

    val apiService: ApiService = retrofit.create(ApiService::class.java)
}
```

### 8.2 Build Production APK

```bash
cd agent-app
./gradlew assembleRelease
```

APK will be at: `app/build/outputs/apk/release/app-release-unsigned.apk`

### 8.3 Sign APK (Optional but Recommended)

Generate keystore:
```bash
keytool -genkey -v -keystore atlas-release-key.keystore -alias atlas -keyalg RSA -keysize 2048 -validity 10000
```

Sign APK:
```bash
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -keystore atlas-release-key.keystore app/build/outputs/apk/release/app-release-unsigned.apk atlas
```

## Step 9: Testing External Access

### 9.1 Test API from External Network

```bash
curl https://api.yourdomain.com/api/v1/health
```

Expected response:
```json
{
  "success": true,
  "message": "API is running",
  "timestamp": "2025-10-19T..."
}
```

### 9.2 Test Agent Registration

```bash
curl -X POST https://api.yourdomain.com/api/v1/agents/register \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "test-external-001",
    "walletAddress": "0x1234567890123456789012345678901234567890"
  }'
```

### 9.3 Distribute APK to External Testers

Options:
1. **Email:** Send APK directly
2. **Cloud Storage:** Google Drive, Dropbox
3. **Firebase App Distribution:** Professional solution
4. **Internal Portal:** Host on your server

## Step 10: Monitoring and Maintenance

### 10.1 View Logs

```bash
# PM2 logs
pm2 logs atlas-backend
pm2 logs atlas-backend --lines 100

# Nginx logs
sudo tail -f /var/log/nginx/atlas-access.log
sudo tail -f /var/log/nginx/atlas-error.log
```

### 10.2 Monitor Application

```bash
pm2 monit
pm2 status
```

### 10.3 Database Backups

Create backup script `/var/www/atlas/backup-db.sh`:
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/atlas"
mkdir -p $BACKUP_DIR

pg_dump -U atlas_user -d atlas_db | gzip > $BACKUP_DIR/atlas_db_$DATE.sql.gz

# Keep only last 7 days of backups
find $BACKUP_DIR -name "atlas_db_*.sql.gz" -mtime +7 -delete
```

Make executable and add to cron:
```bash
chmod +x /var/www/atlas/backup-db.sh
crontab -e
# Add: 0 2 * * * /var/www/atlas/backup-db.sh
```

### 10.4 Update Application

```bash
cd /var/www/atlas/backend
git pull origin main
npm install --production
pm2 restart atlas-backend
```

## Security Checklist

- [ ] Strong database password set
- [ ] JWT secrets are random and secure (64+ characters)
- [ ] SSL/HTTPS enabled with valid certificate
- [ ] Firewall configured (only 80, 443, 22 open)
- [ ] SSH key authentication enabled (password auth disabled)
- [ ] Database not exposed externally
- [ ] Rate limiting configured
- [ ] CORS properly configured
- [ ] Environment variables secured
- [ ] Regular backups scheduled
- [ ] Monitoring and alerting set up
- [ ] Nginx security headers configured
- [ ] Application running as non-root user

## Troubleshooting

### Application won't start
```bash
pm2 logs atlas-backend --err
# Check for missing dependencies or configuration errors
```

### Database connection errors
```bash
# Test database connection
psql -U atlas_user -d atlas_db -h localhost
# Check DATABASE_URL in .env
```

### SSL certificate issues
```bash
sudo certbot certificates
sudo certbot renew
# Check Nginx error logs
```

### High memory usage
```bash
pm2 restart atlas-backend
# Consider increasing server resources
```

## Performance Optimization

### Enable Nginx Caching
```nginx
# Add to http block in /etc/nginx/nginx.conf
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=api_cache:10m max_size=1g inactive=60m;
```

### Database Optimization
```sql
-- Create indexes on frequently queried columns
CREATE INDEX idx_agents_device_id ON agents(device_id);
CREATE INDEX idx_agents_wallet_address ON agents(wallet_address);
```

### PM2 Cluster Mode
Already configured in ecosystem.config.js with 2 instances.

## Next Steps

1. Set up monitoring (Prometheus, Grafana)
2. Configure automated deployments (GitHub Actions)
3. Implement log aggregation (ELK stack)
4. Add application performance monitoring (APM)
5. Set up alerting (email, Slack, PagerDuty)
6. Configure CDN for static assets (if applicable)

## Support

For issues or questions:
- Check logs: `pm2 logs atlas-backend`
- Review Nginx logs: `sudo tail -f /var/log/nginx/atlas-error.log`
- Contact: [Your support channel]

---

**Last Updated:** October 19, 2025  
**Version:** 1.0.0
