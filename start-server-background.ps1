# Script para iniciar el servidor en segundo plano
Write-Host "Starting Atlas Backend Server in background..." -ForegroundColor Cyan

$serverPath = "d:\Users\alexj\Proyectos\Atlas\backend-core"
$serverScript = "test-server.js"

# Iniciar el servidor como un proceso en segundo plano
$job = Start-Process -FilePath "node" -ArgumentList $serverScript -WorkingDirectory $serverPath -PassThru -WindowStyle Hidden

Write-Host "Server started with PID: $($job.Id)" -ForegroundColor Green
Write-Host ""
Write-Host "Server endpoints:" -ForegroundColor Yellow
Write-Host "  Health: http://localhost:3000/api/v1/health" -ForegroundColor White
Write-Host "  Register: http://localhost:3000/api/v1/agents/register" -ForegroundColor White
Write-Host ""
Write-Host "To stop the server, run: Stop-Process -Id $($job.Id)" -ForegroundColor Yellow

# Esperar un momento para que el servidor inicie
Start-Sleep -Seconds 2

# Probar el servidor
Write-Host "`nTesting server..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/health" -Method GET -ErrorAction Stop
    Write-Host "Server is responding!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json) -ForegroundColor White
} catch {
    Write-Host "Warning: Server may still be starting up..." -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nServer is running. Press Ctrl+C in the server window to stop it." -ForegroundColor Cyan