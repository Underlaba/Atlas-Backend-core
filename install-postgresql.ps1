# Script de Instalacion de PostgreSQL para Atlas

Write-Host "============================================"
Write-Host "Instalacion de PostgreSQL para Atlas Backend"
Write-Host "============================================"
Write-Host ""

$postgresVersion = "16.1-1"
$installerUrl = "https://get.enterprisedb.com/postgresql/postgresql-16.1-1-windows-x64.exe"
$installerPath = "$env:TEMP\postgresql-installer.exe"

Write-Host "Descargando PostgreSQL..." -ForegroundColor Yellow
Write-Host "Esto puede tomar varios minutos..."
Write-Host ""

try {
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath
    Write-Host "Descarga completada!" -ForegroundColor Green
} catch {
    Write-Host "Error al descargar PostgreSQL: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Por favor descarga manualmente desde:" -ForegroundColor Yellow
    Write-Host "https://www.postgresql.org/download/windows/" -ForegroundColor Cyan
    exit 1
}

Write-Host ""
Write-Host "Iniciando instalador de PostgreSQL..." -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANTE: Durante la instalacion:" -ForegroundColor Cyan
Write-Host "1. Contraseña para usuario postgres: anota la que elijas" -ForegroundColor White
Write-Host "2. Puerto: deja 5432 (por defecto)" -ForegroundColor White
Write-Host "3. Instala Stack Builder: NO es necesario" -ForegroundColor White
Write-Host ""

Start-Process -FilePath $installerPath -Wait

Write-Host ""
Write-Host "Instalacion completada!" -ForegroundColor Green
Write-Host ""
Write-Host "Proximos pasos:" -ForegroundColor Yellow
Write-Host "1. Reinicia PowerShell para que psql este disponible" -ForegroundColor White
Write-Host "2. Crea la base de datos: psql -U postgres -c 'CREATE DATABASE atlas_db;'" -ForegroundColor White
Write-Host "3. Actualiza el archivo .env con tu contraseña de PostgreSQL" -ForegroundColor White
Write-Host "4. Ejecuta: npm run migrate" -ForegroundColor White
Write-Host "5. Ejecuta: npm run dev" -ForegroundColor White
Write-Host ""
