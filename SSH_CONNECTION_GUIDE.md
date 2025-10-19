# AWS EC2 Connection Guide - Atlas Backend
# Instance IP: 54.176.126.78

## Windows PowerShell Connection

### Step 1: Locate Your Key File
Find the .pem file you downloaded when creating the EC2 instance.
Example: atlas-backend-key.pem

### Step 2: Set Key Permissions (Important!)

Open PowerShell as Administrator and run:

```powershell
# Navigate to the directory containing your .pem file
cd C:\Users\YourUsername\Downloads

# Set proper permissions (replace with your actual filename)
icacls "atlas-backend-key.pem" /inheritance:r
icacls "atlas-backend-key.pem" /grant:r "$($env:USERNAME):(R)"
```

### Step 3: Connect via SSH

```powershell
# Connect to EC2 instance
ssh -i atlas-backend-key.pem ubuntu@54.176.126.78
```

When prompted "Are you sure you want to continue connecting?", type **yes**

### Alternative: Using Full Path

If the key is in a different location:

```powershell
ssh -i "C:\Users\YourUsername\Downloads\atlas-backend-key.pem" ubuntu@54.176.126.78
```

### Troubleshooting

**Error: "Permission denied"**
- Verify you're using the correct key file
- Check key permissions with: `icacls atlas-backend-key.pem`

**Error: "Connection timed out"**
- Verify Security Group allows SSH (port 22) from your IP
- Check EC2 instance is running

**Error: "Host key verification failed"**
- Delete old entry: `ssh-keygen -R 54.176.126.78`
- Try connecting again

---

## Once Connected

You should see a prompt like:
```
ubuntu@ip-172-31-x-x:~$
```

Now you're ready to run the deployment commands!

### Quick Start Commands (After SSH Connection)

```bash
# 1. Download and run setup script
wget https://raw.githubusercontent.com/Underlaba/Atlas-Admin-Panel/main/backend-core/aws-setup.sh
chmod +x aws-setup.sh
./aws-setup.sh

# This will install:
# - Node.js 18.x
# - PostgreSQL 14
# - PM2
# - Nginx
# - Certbot

# 2. After setup completes, follow the remaining steps from QUICK_START_AWS.md
```

---

## Next Steps After Connection

1. Run setup script (installs all dependencies)
2. Configure PostgreSQL database
3. Clone and deploy backend application
4. Configure Nginx and SSL
5. Test everything

Refer to: `QUICK_START_AWS.md` for detailed step-by-step commands.
