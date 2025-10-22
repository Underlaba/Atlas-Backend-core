# 🧪 Script de Pruebas - Sistema de Logs

Write-Host "`n" -NoNewline
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  PRUEBAS DEL SISTEMA DE LOGS Y AUDITORÍA" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan

Write-Host "`n📋 INSTRUCCIONES DE PRUEBA:" -ForegroundColor Yellow
Write-Host "`n1️⃣ GENERAR LOGS AUTOMÁTICOS:" -ForegroundColor White
Write-Host "   - Abre http://localhost:3000/login" -ForegroundColor Cyan
Write-Host "   - Inicia sesión con admin@atlas.com" -ForegroundColor Cyan
Write-Host "   - Esto generará un log de 'login'" -ForegroundColor Gray
Write-Host "`n   - Ve al dashboard" -ForegroundColor Cyan
Write-Host "   - Abre un agente (esto genera 'agent_viewed')" -ForegroundColor Gray
Write-Host "   - Cambia el estado de un agente (genera 'agent_status_changed')" -ForegroundColor Gray
Write-Host "`n   - Haz logout (genera 'logout')" -ForegroundColor Gray

Write-Host "`n2️⃣ VER LOGS:" -ForegroundColor White
Write-Host "   - Inicia sesión nuevamente" -ForegroundColor Cyan
Write-Host "   - Click en '📋 Activity Logs' en el dashboard" -ForegroundColor Cyan
Write-Host "   - Deberías ver la tabla con todos los logs" -ForegroundColor Gray

Write-Host "`n3️⃣ PROBAR FILTROS:" -ForegroundColor White
Write-Host "   - Filtrar por fecha (Start Date / End Date)" -ForegroundColor Cyan
Write-Host "   - Filtrar por acción (login, logout, agent_status_changed)" -ForegroundColor Cyan
Write-Host "   - Buscar en detalles" -ForegroundColor Cyan
Write-Host "   - Click en 'Apply Filters'" -ForegroundColor Cyan

Write-Host "`n4️⃣ PROBAR EXPORTACIÓN:" -ForegroundColor White
Write-Host "   - Click en 'Export CSV'" -ForegroundColor Cyan
Write-Host "   - Verificar que se descarga el archivo CSV" -ForegroundColor Gray
Write-Host "   - Click en 'Export JSON'" -ForegroundColor Cyan
Write-Host "   - Verificar que se descarga el archivo JSON" -ForegroundColor Gray

Write-Host "`n5️⃣ PROBAR PAGINACIÓN:" -ForegroundColor White
Write-Host "   - Si hay más de 20 logs, verás botones de paginación" -ForegroundColor Cyan
Write-Host "   - Navega entre páginas" -ForegroundColor Gray

Write-Host "`n📡 URLS:" -ForegroundColor Yellow
Write-Host "   Frontend:  http://localhost:3000" -ForegroundColor White
Write-Host "   Backend:   http://54.176.126.78/api/v1" -ForegroundColor White
Write-Host "   Logs Page: http://localhost:3000/logs" -ForegroundColor White

Write-Host "`n🔍 VERIFICAR EN CONSOLA DEL NAVEGADOR:" -ForegroundColor Yellow
Write-Host "   F12 → Network → Verificar llamadas a /api/v1/logs" -ForegroundColor Cyan

Write-Host "`n✅ CHECKLIST:" -ForegroundColor Yellow
Write-Host "   [ ] Login genera log automático" -ForegroundColor White
Write-Host "   [ ] Cambio de estado genera log" -ForegroundColor White
Write-Host "   [ ] Página /logs muestra logs" -ForegroundColor White
Write-Host "   [ ] Filtros funcionan correctamente" -ForegroundColor White
Write-Host "   [ ] Export CSV funciona" -ForegroundColor White
Write-Host "   [ ] Export JSON funciona" -ForegroundColor White
Write-Host "   [ ] Paginación funciona" -ForegroundColor White
Write-Host "   [ ] Refresh actualiza la lista" -ForegroundColor White

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "  LISTO PARA PROBAR" -ForegroundColor Green
Write-Host "================================================================`n" -ForegroundColor Cyan
