# Script para cambiar al servidor principal con PostgreSQL

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  CONFIGURACION SERVIDOR PRINCIPAL" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Detener servidor de prueba
Write-Host "[1/4] Deteniendo servidor de prueba..." -ForegroundColor Yellow
$nodeProcesses = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    Write-Host "  Deteniendo procesos Node.js..." -ForegroundColor White
    Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "  OK Procesos detenidos" -ForegroundColor Green
} else {
    Write-Host "  INFO No hay procesos Node.js corriendo" -ForegroundColor Cyan
}
Write-Host ""

# 2. Verificar PostgreSQL
Write-Host "[2/4] Verificando PostgreSQL..." -ForegroundColor Yellow
$pgService = Get-Service -Name "postgresql*" -ErrorAction SilentlyContinue
if ($pgService -and $pgService.Status -eq "Running") {
    Write-Host "  OK PostgreSQL esta corriendo" -ForegroundColor Green
} else {
    Write-Host "  ADVERTENCIA PostgreSQL no esta corriendo" -ForegroundColor Yellow
    Write-Host "  Intentando iniciar PostgreSQL..." -ForegroundColor White
    Start-Service -Name "postgresql*" -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
}
Write-Host ""

# 3. Verificar base de datos
Write-Host "[3/4] Verificando Base de Datos..." -ForegroundColor Yellow
Push-Location "D:\Users\alexj\Proyectos\Atlas\backend-core"
try {
    $testDbResult = node test-db.js 2>&1
    if ($testDbResult -match "Connected to PostgreSQL") {
        Write-Host "  OK Conexion a PostgreSQL exitosa" -ForegroundColor Green
    } else {
        Write-Host "  ADVERTENCIA No se pudo verificar conexion" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ERROR al verificar base de datos" -ForegroundColor Red
}
Pop-Location
Write-Host ""

# 4. Iniciar servidor principal
Write-Host "[4/4] Iniciando servidor principal..." -ForegroundColor Yellow
Push-Location "D:\Users\alexj\Proyectos\Atlas\backend-core"

Write-Host "  Iniciando servidor en segundo plano..." -ForegroundColor White
$serverProcess = Start-Process -FilePath "node" `
    -ArgumentList "src/server.js" `
    -WorkingDirectory "D:\Users\alexj\Proyectos\Atlas\backend-core" `
    -PassThru `
    -WindowStyle Hidden

if ($serverProcess) {
    Write-Host "  OK Servidor iniciado (PID: $($serverProcess.Id))" -ForegroundColor Green
    Write-Host "  Esperando inicializacion..." -ForegroundColor White
    Start-Sleep -Seconds 3
    
    # Verificar que esta respondiendo
    try {
        $health = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/health" -Method GET -ErrorAction Stop
        if ($health.success) {
            Write-Host "  OK Servidor respondiendo correctamente" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ADVERTENCIA Servidor puede estar iniciando aun..." -ForegroundColor Yellow
    }
} else {
    Write-Host "  ERROR No se pudo iniciar el servidor" -ForegroundColor Red
}

Pop-Location
Write-Host ""

# Resumen
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  CONFIGURACION COMPLETA" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "SERVIDOR PRINCIPAL:" -ForegroundColor White
Write-Host "  Archivo: src/server.js" -ForegroundColor White
Write-Host "  Puerto: 3000" -ForegroundColor White
Write-Host "  Base de Datos: PostgreSQL (atlas_db)" -ForegroundColor White
Write-Host "  PID: $($serverProcess.Id)" -ForegroundColor White
Write-Host ""
Write-Host "ENDPOINTS DISPONIBLES:" -ForegroundColor White
Write-Host "  Health: http://localhost:3000/api/v1/health" -ForegroundColor Cyan
Write-Host "  Register: http://localhost:3000/api/v1/agents/register" -ForegroundColor Cyan
Write-Host "  List: http://localhost:3000/api/v1/agents" -ForegroundColor Cyan
Write-Host ""
Write-Host "SIGUIENTE PASO:" -ForegroundColor Yellow
Write-Host "  Ejecutar test IT-02 nuevamente para verificar registro en PostgreSQL" -ForegroundColor White
Write-Host "  Comando: & 'D:\Users\alexj\Proyectos\Atlas\backend-core\test-IT-02.ps1'" -ForegroundColor White
Write-Host ""