# ================================================================
# SCRIPT DE ACTUALIZACIÓN AWS EC2 - ATLAS BACKEND
# ================================================================
# Este script te guiará paso a paso para actualizar el backend en AWS

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "  ACTUALIZACIÓN BACKEND EN AWS EC2" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan

Write-Host "`n📋 CAMBIOS A DESPLEGAR:" -ForegroundColor Yellow
Write-Host "   ✅ Users API (10 endpoints)" -ForegroundColor Green
Write-Host "   ✅ Logs API (ya estaba, verificar)" -ForegroundColor Green
Write-Host "   ✅ Commit: 9daecab" -ForegroundColor White
Write-Host "   ✅ 1,039 líneas agregadas" -ForegroundColor White

Write-Host "`n🔑 CREDENCIALES AWS EC2:" -ForegroundColor Yellow
Write-Host "   IP: 54.176.126.78" -ForegroundColor White
Write-Host "   Usuario: ubuntu (probablemente)" -ForegroundColor White
Write-Host "   Key: Tu archivo .pem" -ForegroundColor White

Write-Host "`n📝 PASOS A SEGUIR:" -ForegroundColor Yellow
Write-Host "`n1️⃣  CONECTAR A EC2 VIA SSH:" -ForegroundColor Cyan
Write-Host "   Opción A - Si tienes .pem:" -ForegroundColor White
Write-Host "   ssh -i tu-llave.pem ubuntu@54.176.126.78" -ForegroundColor Gray
Write-Host "`n   Opción B - Si configuraste contraseña:" -ForegroundColor White
Write-Host "   ssh ubuntu@54.176.126.78" -ForegroundColor Gray

Write-Host "`n2️⃣  UNA VEZ CONECTADO, EJECUTA:" -ForegroundColor Cyan
Write-Host @"
   # Ir al directorio del proyecto
   cd ~/atlas-backend
   
   # Detener el servidor (PM2)
   pm2 stop atlas-backend
   
   # Hacer backup por seguridad
   git branch backup-$(date +%Y%m%d)
   
   # Actualizar código desde GitHub
   git pull origin main
   
   # Instalar dependencias (por si acaso)
   npm install
   
   # Verificar que todo esté bien
   npm run test || echo "Sin tests configurados"
   
   # Reiniciar el servidor
   pm2 restart atlas-backend
   
   # Ver los logs en tiempo real
   pm2 logs atlas-backend --lines 50
"@ -ForegroundColor Gray

Write-Host "`n3️⃣  VERIFICAR QUE FUNCIONE:" -ForegroundColor Cyan
Write-Host "   Desde tu navegador o Postman:" -ForegroundColor White
Write-Host "   GET http://54.176.126.78/api/v1/health" -ForegroundColor Gray
Write-Host "   GET http://54.176.126.78/api/v1/users (con token)" -ForegroundColor Gray
Write-Host "   GET http://54.176.126.78/api/v1/logs (con token)" -ForegroundColor Gray

Write-Host "`n4️⃣  PROBAR EN ADMIN PANEL:" -ForegroundColor Cyan
Write-Host "   1. Recarga http://localhost:3000" -ForegroundColor Gray
Write-Host "   2. Haz clic en 'Users' - debe funcionar ✅" -ForegroundColor Gray
Write-Host "   3. Haz clic en 'Activity Logs' - debe funcionar ✅" -ForegroundColor Gray

Write-Host "`n🔧 COMANDOS ÚTILES EN EC2:" -ForegroundColor Yellow
Write-Host "   pm2 status               # Ver estado de procesos" -ForegroundColor Gray
Write-Host "   pm2 logs atlas-backend   # Ver logs en tiempo real" -ForegroundColor Gray
Write-Host "   pm2 restart atlas-backend # Reiniciar servidor" -ForegroundColor Gray
Write-Host "   pm2 stop atlas-backend   # Detener servidor" -ForegroundColor Gray
Write-Host "   git status               # Ver estado de Git" -ForegroundColor Gray
Write-Host "   git log --oneline -5     # Ver últimos commits" -ForegroundColor Gray

Write-Host "`n⚠️  TROUBLESHOOTING:" -ForegroundColor Yellow
Write-Host "   Si PM2 no está instalado:" -ForegroundColor White
Write-Host "   npm install -g pm2" -ForegroundColor Gray
Write-Host "`n   Si el servidor no arranca:" -ForegroundColor White
Write-Host "   npm start                # Arrancar manualmente para ver errores" -ForegroundColor Gray
Write-Host "`n   Si hay conflictos de Git:" -ForegroundColor White
Write-Host "   git stash                # Guardar cambios locales" -ForegroundColor Gray
Write-Host "   git pull origin main     # Actualizar" -ForegroundColor Gray

Write-Host "`n📊 ENDPOINTS QUE DEBERÍAN FUNCIONAR DESPUÉS:" -ForegroundColor Yellow
Write-Host "   ✅ /api/v1/auth/*         - Autenticación" -ForegroundColor Green
Write-Host "   ✅ /api/v1/agents/*       - Gestión de agentes" -ForegroundColor Green
Write-Host "   ✅ /api/v1/users/*        - Gestión de usuarios (NUEVO)" -ForegroundColor Green
Write-Host "   ✅ /api/v1/logs/*         - Activity logs (NUEVO)" -ForegroundColor Green
Write-Host "   ⏳ /api/v1/settings/*     - Configuración (pendiente)" -ForegroundColor Yellow

Write-Host "`n🎯 COMANDO RÁPIDO (TODO EN UNO):" -ForegroundColor Yellow
Write-Host @"
cd ~/atlas-backend && pm2 stop atlas-backend && git pull origin main && npm install && pm2 restart atlas-backend && pm2 logs atlas-backend --lines 20
"@ -ForegroundColor Cyan

Write-Host "`n💡 CONSEJO:" -ForegroundColor Yellow
Write-Host "   Mantén dos terminales abiertas:" -ForegroundColor White
Write-Host "   1. Una para ejecutar comandos" -ForegroundColor Gray
Write-Host "   2. Otra con 'pm2 logs atlas-backend' para ver logs" -ForegroundColor Gray

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "  ¿LISTO PARA CONECTAR?" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "`n  Conecta a EC2 con SSH y ejecuta los comandos anteriores" -ForegroundColor White
Write-Host "  Avísame cuando termines o si encuentras algún error" -ForegroundColor Gray
Write-Host "`n================================================================`n" -ForegroundColor Cyan
