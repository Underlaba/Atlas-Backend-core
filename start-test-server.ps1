# Script para iniciar el servidor de prueba de Atlas
Write-Host "Starting Atlas Test Server..." -ForegroundColor Cyan

$serverPath = "d:\Users\alexj\Proyectos\Atlas\backend-core"

# Cambiar al directorio del servidor
Push-Location $serverPath

# Iniciar el servidor
Write-Host "Server path: $serverPath" -ForegroundColor Yellow
Write-Host "Starting Node.js server..." -ForegroundColor Yellow

node test-server.js

Pop-Location