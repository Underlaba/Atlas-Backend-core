# Node.js Installation Script for Atlas Backend

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Node.js Installation for Atlas Backend" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Download Node.js installer
$nodeVersion = "20.10.0"
$installerUrl = "https://nodejs.org/dist/v$nodeVersion/node-v$nodeVersion-x64.msi"
$installerPath = "$env:TEMP\nodejs-installer.msi"

Write-Host "Step 1: Downloading Node.js v$nodeVersion..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
    Write-Host "Download complete!" -ForegroundColor Green
} catch {
    Write-Host "Error downloading Node.js: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Installing Node.js..." -ForegroundColor Yellow
Write-Host "This will open the installer. Please follow the installation wizard." -ForegroundColor Cyan
Write-Host ""

# Start the installer
Start-Process -FilePath $installerPath -Wait

Write-Host ""
Write-Host "Step 3: Verifying installation..." -ForegroundColor Yellow

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Wait a moment for PATH to update
Start-Sleep -Seconds 2

# Try to verify
try {
    $nodeVer = & "C:\Program Files\nodejs\node.exe" --version 2>$null
    $npmVer = & "C:\Program Files\nodejs\npm.cmd" --version 2>$null
    
    if ($nodeVer -and $npmVer) {
        Write-Host ""
        Write-Host "Installation successful!" -ForegroundColor Green
        Write-Host "Node.js version: $nodeVer" -ForegroundColor Green
        Write-Host "npm version: v$npmVer" -ForegroundColor Green
        Write-Host ""
        Write-Host "IMPORTANT: Please close this PowerShell window and open a new one" -ForegroundColor Yellow
        Write-Host "Then navigate to the backend-core folder and run:" -ForegroundColor Yellow
        Write-Host "  cd d:\Users\alexj\Proyectos\Atlas\backend-core" -ForegroundColor Cyan
        Write-Host "  npm install" -ForegroundColor Cyan
    } else {
        Write-Host ""
        Write-Host "Node.js installed but not in PATH yet." -ForegroundColor Yellow
        Write-Host "Please restart PowerShell and run: node --version" -ForegroundColor Cyan
    }
} catch {
    Write-Host ""
    Write-Host "Installation may be complete. Please:" -ForegroundColor Yellow
    Write-Host "1. Close this PowerShell window" -ForegroundColor Cyan
    Write-Host "2. Open a new PowerShell window" -ForegroundColor Cyan
    Write-Host "3. Run: node --version" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
