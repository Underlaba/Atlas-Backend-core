# Script para probar la conexión y registro de agentes
# Ejecutar desde PowerShell en el directorio backend-core

Write-Host "Testing Atlas Agent Registration API..." -ForegroundColor Cyan

# 1. Verificar que el servidor esté corriendo
Write-Host "`n1. Testing server health..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/health" -Method GET
    Write-Host "Server is healthy: $($healthResponse | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Server health check failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Make sure the backend server is running with: npm start" -ForegroundColor Yellow
    exit 1
}

# 2. Probar registro de agente
Write-Host "`n2. Testing agent registration..." -ForegroundColor Yellow

$testAgent = @{
    deviceId = "test-device-$(Get-Random)"
    walletAddress = "0x1234567890123456789012345678901234567890"
} | ConvertTo-Json

try {
    $registerResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/agents/register" -Method POST -Body $testAgent -ContentType "application/json"
    Write-Host "Agent registration successful:" -ForegroundColor Green
    Write-Host $($registerResponse | ConvertTo-Json -Depth 3) -ForegroundColor Green
} catch {
    Write-Host "Agent registration failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "Status Code: $statusCode" -ForegroundColor Red
    }
}

# 3. Probar registro duplicado
Write-Host "`n3. Testing duplicate registration..." -ForegroundColor Yellow
try {
    $duplicateResponse = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/agents/register" -Method POST -Body $testAgent -ContentType "application/json"
    Write-Host "Duplicate registration response:" -ForegroundColor Yellow
    Write-Host $($duplicateResponse | ConvertTo-Json -Depth 3) -ForegroundColor Yellow
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "Duplicate registration correctly rejected (409 Conflict)" -ForegroundColor Green
    } else {
        Write-Host "Unexpected error on duplicate: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nAPI testing completed!" -ForegroundColor Cyan
Write-Host "You can now test the Android app with the emulator." -ForegroundColor Green