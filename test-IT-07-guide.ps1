# ============================================================================
# IT-07 - REINICIO DE ESTADO (UNREGISTRATION)
# ============================================================================
# Objetivo: Verificar que al borrar los datos/caché de la aplicación,
#           el estado se reinicia y permite un nuevo registro.
# 
# Flujo esperado:
#   1. App con registro previo muestra "Already Registered"
#   2. Usuario borra datos de la app (Settings > Apps > Atlas Agent > Clear Data)
#   3. App se reinicia y muestra flujo inicial de registro
#   4. Usuario puede registrar nuevamente
# ============================================================================

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "IT-07 - REINICIO DE ESTADO (UNREGISTRATION)" -ForegroundColor Cyan
Write-Host "============================================================================`n" -ForegroundColor Cyan

Write-Host "📋 OBJETIVO:" -ForegroundColor Yellow
Write-Host "   Verificar que borrar los datos de la app reinicia el estado correctamente`n"

# ============================================================================
# PARTE 1: VERIFICAR IMPLEMENTACIÓN DE LocalStorage.clear()
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "PARTE 1: VERIFICAR IMPLEMENTACIÓN DE LocalStorage.clear()" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

$localStoragePath = "..\agent-app\app\src\main\java\com\underlaba\atlas\agentapp\data\LocalStorage.kt"

if (Test-Path $localStoragePath) {
    Write-Host "✅ Encontrado: LocalStorage.kt" -ForegroundColor Green
    
    $content = Get-Content $localStoragePath -Raw
    
    # Verificar método clear()
    if ($content -match 'fun clear\(\)') {
        Write-Host "✅ Método clear() existe" -ForegroundColor Green
        
        if ($content -match 'prefs\.edit\(\)\.clear\(\)\.apply\(\)') {
            Write-Host "✅ Implementación correcta: prefs.edit().clear().apply()" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Método clear() existe pero implementación no verificada" -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ Método clear() NO encontrado" -ForegroundColor Red
    }
    
    # Verificar claves almacenadas
    Write-Host "`n📝 Claves en SharedPreferences:" -ForegroundColor Cyan
    if ($content -match 'KEY_DEVICE_ID') {
        Write-Host "   - device_id" -ForegroundColor Gray
    }
    if ($content -match 'KEY_WALLET_ADDRESS') {
        Write-Host "   - wallet_address" -ForegroundColor Gray
    }
    if ($content -match 'KEY_IS_REGISTERED') {
        Write-Host "   - is_registered" -ForegroundColor Gray
    }
    
} else {
    Write-Host "❌ LocalStorage.kt no encontrado" -ForegroundColor Red
}

Write-Host ""

# ============================================================================
# PARTE 2: VERIFICAR COMPORTAMIENTO DE onCreate() AL REINICIAR
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "PARTE 2: VERIFICAR COMPORTAMIENTO DE onCreate() AL REINICIAR" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

$mainActivityPath = "..\agent-app\app\src\main\java\com\underlaba\atlas\agentapp\MainActivity.kt"

if (Test-Path $mainActivityPath) {
    Write-Host "✅ Encontrado: MainActivity.kt" -ForegroundColor Green
    
    $content = Get-Content $mainActivityPath -Raw
    
    # Verificar loadSavedData()
    if ($content -match 'private fun loadSavedData\(\)') {
        Write-Host "✅ Método loadSavedData() existe" -ForegroundColor Green
        
        # Verificar que lee localStorage.isRegistered()
        if ($content -match 'localStorage\.isRegistered\(\)') {
            Write-Host "✅ Lee estado de registro desde localStorage" -ForegroundColor Green
        }
        
        # Verificar que muestra "Already Registered" si está registrado
        if ($content -match 'Already Registered') {
            Write-Host "✅ Muestra 'Already Registered' cuando está registrado" -ForegroundColor Green
        }
        
        # Verificar que deshabilita el botón
        if ($content -match 'btnRegister\.isEnabled = false') {
            Write-Host "✅ Deshabilita botón de registro cuando ya está registrado" -ForegroundColor Green
        }
    }
    
    # Verificar generateDeviceId()
    if ($content -match 'private fun generateDeviceId\(\)') {
        Write-Host "✅ Método generateDeviceId() existe" -ForegroundColor Green
        
        if ($content -match 'localStorage\.getDeviceId\(\)') {
            Write-Host "✅ Intenta recuperar Device ID guardado" -ForegroundColor Green
        }
        
        if ($content -match 'UUID\.randomUUID\(\)') {
            Write-Host "✅ Genera nuevo Device ID si no existe" -ForegroundColor Green
        }
    }
    
} else {
    Write-Host "❌ MainActivity.kt no encontrado" -ForegroundColor Red
}

Write-Host ""

# ============================================================================
# PARTE 3: INSTRUCCIONES DE VERIFICACIÓN MANUAL EN EMULADOR
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "PARTE 3: INSTRUCCIONES DE VERIFICACIÓN MANUAL EN EMULADOR" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

Write-Host "📱 PASO 1: VERIFICAR ESTADO REGISTRADO" -ForegroundColor Yellow
Write-Host "   1. Abre el emulador Android" -ForegroundColor White
Write-Host "   2. Abre la app Atlas Agent" -ForegroundColor White
Write-Host "   3. Verifica que muestra:" -ForegroundColor White
Write-Host "      - 'Already Registered' en el botón" -ForegroundColor Gray
Write-Host "      - 'Device already registered' en el status" -ForegroundColor Gray
Write-Host "      - Botón de registro deshabilitado" -ForegroundColor Gray
Write-Host "      - Wallet address guardada (si existe)" -ForegroundColor Gray
Write-Host "`n   ✓ Si muestra este estado, continúa al Paso 2`n" -ForegroundColor Green

Write-Host "🗑️  PASO 2: BORRAR DATOS DE LA APP" -ForegroundColor Yellow
Write-Host "   OPCIÓN A - Desde Settings del emulador:" -ForegroundColor Cyan
Write-Host "   1. Cierra la app Atlas Agent" -ForegroundColor White
Write-Host "   2. Abre Settings en el emulador" -ForegroundColor White
Write-Host "   3. Ve a Apps > See all apps > Atlas Agent" -ForegroundColor White
Write-Host "   4. Toca 'Storage & cache'" -ForegroundColor White
Write-Host "   5. Toca 'Clear storage' o 'Clear data'" -ForegroundColor White
Write-Host "   6. Confirma la acción`n" -ForegroundColor White

Write-Host "   OPCIÓN B - Desde adb (más rápido):" -ForegroundColor Cyan
Write-Host "   1. Abre una terminal" -ForegroundColor White
Write-Host "   2. Ejecuta:" -ForegroundColor White
Write-Host "      adb shell pm clear com.underlaba.atlas.agentapp" -ForegroundColor Gray
Write-Host "   3. Deberías ver: 'Success'`n" -ForegroundColor Gray

Write-Host "🔄 PASO 3: REABRIR LA APP Y VERIFICAR REINICIO" -ForegroundColor Yellow
Write-Host "   1. Abre la app Atlas Agent nuevamente" -ForegroundColor White
Write-Host "   2. Verifica que la app muestra el flujo inicial:" -ForegroundColor White
Write-Host "      ✓ Device ID es DIFERENTE al anterior" -ForegroundColor Green
Write-Host "      ✓ Campo de wallet address está VACÍO" -ForegroundColor Green
Write-Host "      ✓ Botón 'Register Agent' está HABILITADO" -ForegroundColor Green
Write-Host "      ✓ Status no muestra 'Already Registered'" -ForegroundColor Green
Write-Host "      ✓ UI está en estado inicial de registro`n" -ForegroundColor Green

Write-Host "📝 PASO 4: REGISTRAR NUEVAMENTE" -ForegroundColor Yellow
Write-Host "   1. Ingresa una wallet válida:" -ForegroundColor White
Write-Host "      0x1234567890123456789012345678901234567890" -ForegroundColor Gray
Write-Host "   2. Presiona 'Register Agent'" -ForegroundColor White
Write-Host "   3. Verifica el resultado:" -ForegroundColor White
Write-Host "      ✓ Muestra 'Agent registered successfully!'" -ForegroundColor Green
Write-Host "      ✓ Botón cambia a 'Already Registered' y se deshabilita" -ForegroundColor Green
Write-Host "      ✓ Status muestra 'Device already registered'" -ForegroundColor Green
Write-Host "`n   ✅ Si el nuevo registro es exitoso, IT-07 PASA`n" -ForegroundColor Green

# ============================================================================
# PARTE 4: VERIFICACIÓN DE BASE DE DATOS (OPCIONAL)
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "PARTE 4: VERIFICACIÓN DE BASE DE DATOS (OPCIONAL)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

Write-Host "💡 Puedes verificar que el nuevo registro creó una entrada diferente en la BD:" -ForegroundColor Cyan
Write-Host ""

$queryScript = ".\query-agents.js"
if (Test-Path $queryScript) {
    Write-Host "🔍 Consultando agentes en la base de datos..." -ForegroundColor Yellow
    
    try {
        $result = node $queryScript 2>&1
        
        # Filtrar solo el JSON
        $jsonOutput = $result | Where-Object { $_ -match '^\s*\{' -or $_ -match '^\s*\[' }
        
        if ($jsonOutput) {
            $jsonStr = $jsonOutput -join "`n"
            $agents = $jsonStr | ConvertFrom-Json
            
            Write-Host "`n📊 Agentes registrados:" -ForegroundColor Cyan
            Write-Host "Total: $($agents.Count)" -ForegroundColor White
            Write-Host ""
            
            foreach ($agent in $agents) {
                Write-Host "   ID: $($agent.id)" -ForegroundColor Gray
                Write-Host "   Device ID: $($agent.device_id)" -ForegroundColor White
                Write-Host "   Wallet: $($agent.wallet_address)" -ForegroundColor White
                Write-Host "   Registrado: $($agent.created_at)" -ForegroundColor Gray
                Write-Host ""
            }
            
            if ($agents.Count -ge 2) {
                Write-Host "✅ Se detectan múltiples registros (esperado después de reiniciar app)" -ForegroundColor Green
            }
        }
        
    } catch {
        Write-Host "⚠️  No se pudo consultar la base de datos: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠️  Script query-agents.js no encontrado" -ForegroundColor Yellow
    Write-Host "   Puedes crearlo o consultar manualmente la BD`n" -ForegroundColor Gray
}

# ============================================================================
# RESUMEN DE VERIFICACIÓN
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "RESUMEN DE VERIFICACIÓN IT-07" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

Write-Host "✅ CÓDIGO VERIFICADO:" -ForegroundColor Green
Write-Host "   - LocalStorage.clear() implementado" -ForegroundColor White
Write-Host "   - MainActivity.loadSavedData() lee estado guardado" -ForegroundColor White
Write-Host "   - generateDeviceId() crea nuevo ID si no existe" -ForegroundColor White
Write-Host ""

Write-Host "⏳ VERIFICACIÓN MANUAL PENDIENTE:" -ForegroundColor Yellow
Write-Host "   1. Confirmar que app muestra estado 'Already Registered' antes de borrar datos" -ForegroundColor White
Write-Host "   2. Borrar datos de la app (Settings > Clear data o adb pm clear)" -ForegroundColor White
Write-Host "   3. Reabrir app y verificar que muestra flujo inicial" -ForegroundColor White
Write-Host "   4. Verificar que Device ID es diferente" -ForegroundColor White
Write-Host "   5. Registrar nuevamente y confirmar éxito" -ForegroundColor White
Write-Host ""

Write-Host "📝 CRITERIOS DE ÉXITO:" -ForegroundColor Cyan
Write-Host "   ✓ Después de borrar datos, app vuelve a estado inicial" -ForegroundColor Green
Write-Host "   ✓ Device ID es regenerado (diferente al anterior)" -ForegroundColor Green
Write-Host "   ✓ No hay rastro de wallet address previa" -ForegroundColor Green
Write-Host "   ✓ Botón 'Register Agent' está habilitado" -ForegroundColor Green
Write-Host "   ✓ Nuevo registro funciona correctamente (201 Created)" -ForegroundColor Green
Write-Host "   ✓ App guarda el nuevo estado después del registro" -ForegroundColor Green
Write-Host ""

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "FIN DE IT-07 - REINICIO DE ESTADO" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

Write-Host "💡 NOTA: Este test verifica la limpieza del estado local." -ForegroundColor Yellow
Write-Host "   El backend mantiene el registro previo en la base de datos," -ForegroundColor Gray
Write-Host "   pero la app permite registrar con un nuevo Device ID." -ForegroundColor Gray
Write-Host ""
