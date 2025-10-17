# Script de Prueba de la API Atlas

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Prueba de API - Atlas Backend" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$baseUrl = "http://localhost:3000/api/v1"

# Prueba 1: Health Check
Write-Host "1. Probando Health Check..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get
    Write-Host "   Estado: OK" -ForegroundColor Green
    Write-Host "   Respuesta:" $health.message -ForegroundColor White
} catch {
    Write-Host "   Error en health check: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Prueba 2: Registro de Usuario
Write-Host "2. Registrando nuevo usuario..." -ForegroundColor Yellow
$registerBody = @{
    email = "admin@atlas.com"
    password = "Admin123!"
    firstName = "Admin"
    lastName = "User"
} | ConvertTo-Json

try {
    $register = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -Body $registerBody -ContentType "application/json"
    Write-Host "   Usuario registrado exitosamente!" -ForegroundColor Green
    Write-Host "   Email:" $register.data.user.email -ForegroundColor White
    Write-Host "   ID:" $register.data.user.id -ForegroundColor White
    Write-Host "   Access Token generado" -ForegroundColor White
    $accessToken = $register.data.accessToken
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 400) {
        Write-Host "   Usuario ya existe, intentando login..." -ForegroundColor Yellow
    } else {
        Write-Host "   Error: $_" -ForegroundColor Red
    }
}

Write-Host ""

# Prueba 3: Login
Write-Host "3. Iniciando sesion..." -ForegroundColor Yellow
$loginBody = @{
    email = "admin@atlas.com"
    password = "Admin123!"
} | ConvertTo-Json

try {
    $login = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    Write-Host "   Login exitoso!" -ForegroundColor Green
    Write-Host "   Usuario:" $login.data.user.email -ForegroundColor White
    Write-Host "   Rol:" $login.data.user.role -ForegroundColor White
    $accessToken = $login.data.accessToken
} catch {
    Write-Host "   Error en login: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Prueba 4: Obtener Perfil (Ruta Protegida)
Write-Host "4. Obteniendo perfil de usuario (ruta protegida)..." -ForegroundColor Yellow
$headers = @{
    Authorization = "Bearer $accessToken"
}

try {
    $profile = Invoke-RestMethod -Uri "$baseUrl/auth/profile" -Method Get -Headers $headers
    Write-Host "   Perfil obtenido exitosamente!" -ForegroundColor Green
    Write-Host "   Nombre:" $profile.data.user.firstName $profile.data.user.lastName -ForegroundColor White
    Write-Host "   Email:" $profile.data.user.email -ForegroundColor White
    Write-Host "   Rol:" $profile.data.user.role -ForegroundColor White
} catch {
    Write-Host "   Error obteniendo perfil: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Todas las pruebas completadas exitosamente!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "El servidor esta corriendo en: http://localhost:3000" -ForegroundColor Cyan
Write-Host "API endpoints disponibles:" -ForegroundColor White
Write-Host "  - POST   /api/v1/auth/register" -ForegroundColor Gray
Write-Host "  - POST   /api/v1/auth/login" -ForegroundColor Gray
Write-Host "  - GET    /api/v1/auth/profile" -ForegroundColor Gray
Write-Host "  - POST   /api/v1/auth/refresh-token" -ForegroundColor Gray
Write-Host "  - GET    /api/v1/health`n" -ForegroundColor Gray
