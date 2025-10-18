# ===================================================================
# TEST IT-04: PERSISTENCIA DE ESTADO - GUIA DE VERIFICACION
# ===================================================================
# Objetivo: Verificar que la app mantiene el estado tras cerrar y reabrir
# Expected: App muestra "Already registered" con datos guardados
# ===================================================================

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  TEST IT-04: PERSISTENCIA DE ESTADO" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "OBJETIVO:" -ForegroundColor Yellow
Write-Host "  Verificar que la app Android mantiene el estado de registro" -ForegroundColor White
Write-Host "  despues de cerrar y reabrir la aplicacion." -ForegroundColor White
Write-Host ""

# ===================================================================
# VERIFICACION AUTOMATICA: IMPLEMENTACION
# ===================================================================
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  PARTE 1: VERIFICACION DE CODIGO" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$testsPassed = 0

# Verificar LocalStorage.kt
Write-Host "[1/3] Verificando LocalStorage.kt..." -ForegroundColor Yellow

$localStoragePath = "D:\Users\alexj\Proyectos\Atlas\agent-app\app\src\main\java\com\underlaba\atlas\agentapp\data\LocalStorage.kt"

if (Test-Path $localStoragePath) {
    $localStorageContent = Get-Content $localStoragePath -Raw
    
    $hasIsRegistered = $localStorageContent -match "fun isRegistered"
    $hasSharedPreferences = $localStorageContent -match "SharedPreferences"
    $hasSaveDeviceId = $localStorageContent -match "fun saveDeviceId"
    $hasSaveWallet = $localStorageContent -match "fun saveWalletAddress"
    $hasGetDeviceId = $localStorageContent -match "fun getDeviceId"
    $hasGetWallet = $localStorageContent -match "fun getWalletAddress"
    $hasSetRegistered = $localStorageContent -match "fun setRegistered"
    
    Write-Host "  Metodos de Persistencia:" -ForegroundColor White
    Write-Host "    [$(if($hasIsRegistered){'OK'}else{'  '})] isRegistered() - Verifica si esta registrado" -ForegroundColor $(if($hasIsRegistered){'Green'}else{'Red'})
    Write-Host "    [$(if($hasSaveDeviceId){'OK'}else{'  '})] saveDeviceId() - Guarda Device ID" -ForegroundColor $(if($hasSaveDeviceId){'Green'}else{'Red'})
    Write-Host "    [$(if($hasGetDeviceId){'OK'}else{'  '})] getDeviceId() - Recupera Device ID" -ForegroundColor $(if($hasGetDeviceId){'Green'}else{'Red'})
    Write-Host "    [$(if($hasSaveWallet){'OK'}else{'  '})] saveWalletAddress() - Guarda Wallet" -ForegroundColor $(if($hasSaveWallet){'Green'}else{'Red'})
    Write-Host "    [$(if($hasGetWallet){'OK'}else{'  '})] getWalletAddress() - Recupera Wallet" -ForegroundColor $(if($hasGetWallet){'Green'}else{'Red'})
    Write-Host "    [$(if($hasSetRegistered){'OK'}else{'  '})] setRegistered() - Marca como registrado" -ForegroundColor $(if($hasSetRegistered){'Green'}else{'Red'})
    
    if ($hasIsRegistered -and $hasSharedPreferences -and $hasSaveDeviceId -and $hasSaveWallet) {
        Write-Host ""
        Write-Host "  PASS LocalStorage implementado correctamente" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host ""
        Write-Host "  FAIL LocalStorage incompleto" -ForegroundColor Red
    }
} else {
    Write-Host "  FAIL No se encuentra LocalStorage.kt" -ForegroundColor Red
}

Write-Host ""

# Verificar MainActivity.kt
Write-Host "[2/3] Verificando MainActivity.kt..." -ForegroundColor Yellow

$mainActivityPath = "D:\Users\alexj\Proyectos\Atlas\agent-app\app\src\main\java\com\underlaba\atlas\agentapp\MainActivity.kt"

if (Test-Path $mainActivityPath) {
    $mainActivityContent = Get-Content $mainActivityPath -Raw
    
    $checksIsRegistered = $mainActivityContent -match "localStorage\.isRegistered"
    $loadsDeviceId = $mainActivityContent -match "localStorage\.getDeviceId"
    $loadsWallet = $mainActivityContent -match "localStorage\.getWalletAddress"
    $savesOnSuccess = $mainActivityContent -match "localStorage\.setRegistered" -or $mainActivityContent -match "setRegistered\(true\)"
    $showsRegisteredUI = $mainActivityContent -match "ALREADY REGISTERED" -or $mainActivityContent -match "already registered"
    
    Write-Host "  Logica de Persistencia:" -ForegroundColor White
    Write-Host "    [$(if($checksIsRegistered){'OK'}else{'  '})] Verifica estado al iniciar" -ForegroundColor $(if($checksIsRegistered){'Green'}else{'Red'})
    Write-Host "    [$(if($loadsDeviceId){'OK'}else{'  '})] Carga Device ID guardado" -ForegroundColor $(if($loadsDeviceId){'Green'}else{'Red'})
    Write-Host "    [$(if($loadsWallet){'OK'}else{'  '})] Carga Wallet guardada" -ForegroundColor $(if($loadsWallet){'Green'}else{'Red'})
    Write-Host "    [$(if($savesOnSuccess){'OK'}else{'  '})] Guarda estado tras registro exitoso" -ForegroundColor $(if($savesOnSuccess){'Green'}else{'Red'})
    Write-Host "    [$(if($showsRegisteredUI){'OK'}else{'  '})] Muestra UI de 'registrado'" -ForegroundColor $(if($showsRegisteredUI){'Green'}else{'Red'})
    
    if ($checksIsRegistered -and $loadsDeviceId -and $loadsWallet -and $savesOnSuccess) {
        Write-Host ""
        Write-Host "  PASS MainActivity implementa persistencia" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host ""
        Write-Host "  FAIL MainActivity no implementa persistencia completamente" -ForegroundColor Red
    }
} else {
    Write-Host "  FAIL No se encuentra MainActivity.kt" -ForegroundColor Red
}

Write-Host ""

# Verificar Backend y BD
Write-Host "[3/3] Verificando Datos en Base de Datos..." -ForegroundColor Yellow

try {
    Push-Location "D:\Users\alexj\Proyectos\Atlas\backend-core"
    $dbResult = node query-agents.js 2>&1 | Out-String
    
    if ($dbResult -match "Total de agentes encontrados: (\d+)") {
        $agentCount = [int]$matches[1]
        
        Write-Host "  Agentes registrados en PostgreSQL: $agentCount" -ForegroundColor White
        
        if ($agentCount -gt 0) {
            Write-Host "  PASS Hay registros en BD para persistir" -ForegroundColor Green
            $testsPassed++
            
            # Mostrar datos del ultimo agente
            if ($dbResult -match "Device ID: ([^\r\n]+)") {
                Write-Host "  Ultimo Device ID: $($matches[1].Trim())" -ForegroundColor Gray
            }
            if ($dbResult -match "Wallet Address: ([^\r\n]+)") {
                Write-Host "  Ultima Wallet: $($matches[1].Trim())" -ForegroundColor Gray
            }
        } else {
            Write-Host "  ADVERTENCIA No hay agentes registrados" -ForegroundColor Yellow
            Write-Host "  Ejecuta IT-02 primero para crear un registro" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "  FAIL Error al consultar BD: $_" -ForegroundColor Red
} finally {
    Pop-Location
}

Write-Host ""

# ===================================================================
# PARTE 2: INSTRUCCIONES PARA VERIFICACION MANUAL
# ===================================================================
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  PARTE 2: VERIFICACION MANUAL" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "INSTRUCCIONES PARA PROBAR EN EMULADOR:" -ForegroundColor Yellow
Write-Host ""
Write-Host "PASO 1: Abrir la App" -ForegroundColor Cyan
Write-Host "  - Abre Android Studio" -ForegroundColor White
Write-Host "  - Ejecuta la app en el emulador" -ForegroundColor White
Write-Host "  - Espera a que cargue completamente" -ForegroundColor White
Write-Host ""

Write-Host "PASO 2: Registrar (si no esta registrado)" -ForegroundColor Cyan
Write-Host "  - Si NO muestra 'ALREADY REGISTERED':" -ForegroundColor White
Write-Host "    a) Ingresa una wallet valida" -ForegroundColor Gray
Write-Host "    b) Presiona REGISTER AGENT" -ForegroundColor Gray
Write-Host "    c) Espera confirmacion exitosa" -ForegroundColor Gray
Write-Host "  - Si YA muestra 'ALREADY REGISTERED', continua al Paso 3" -ForegroundColor White
Write-Host ""

Write-Host "PASO 3: Cerrar Completamente la App" -ForegroundColor Cyan
Write-Host "  - Opcion 1: Swipe up desde el boton de recientes" -ForegroundColor White
Write-Host "  - Opcion 2: Boton back hasta salir completamente" -ForegroundColor White
Write-Host "  - Opcion 3: En el gestor de tareas, forzar cierre" -ForegroundColor White
Write-Host "  IMPORTANTE: No solo minimizar, debe cerrarse" -ForegroundColor Yellow
Write-Host ""

Write-Host "PASO 4: Reabrir la App" -ForegroundColor Cyan
Write-Host "  - Toca el icono de la app en el launcher" -ForegroundColor White
Write-Host "  - La app debe iniciar desde cero" -ForegroundColor White
Write-Host ""

Write-Host "PASO 5: Verificar Estado Persistido" -ForegroundColor Cyan
Write-Host ""
Write-Host "  CHECKLIST DE VERIFICACION:" -ForegroundColor Yellow
Write-Host "    [ ] Muestra texto 'ALREADY REGISTERED' en verde" -ForegroundColor White
Write-Host "    [ ] Device ID esta visible" -ForegroundColor White
Write-Host "    [ ] Wallet Address esta visible" -ForegroundColor White
Write-Host "    [ ] Campo de Wallet esta DESHABILITADO (gris)" -ForegroundColor White
Write-Host "    [ ] Boton 'REGISTER AGENT' esta DESHABILITADO" -ForegroundColor White
Write-Host "    [ ] Los datos coinciden con los del registro original" -ForegroundColor White
Write-Host ""

# ===================================================================
# RESUMEN
# ===================================================================
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  RESUMEN IT-04" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "VERIFICACION DE CODIGO: $testsPassed/3 componentes OK" -ForegroundColor $(if($testsPassed -eq 3){'Green'}else{'Yellow'})
Write-Host ""

if ($testsPassed -eq 3) {
    Write-Host "  [OK] LocalStorage implementado" -ForegroundColor Green
    Write-Host "  [OK] MainActivity con logica de persistencia" -ForegroundColor Green
    Write-Host "  [OK] Datos disponibles en BD" -ForegroundColor Green
    Write-Host ""
    Write-Host "RESULTADO:" -ForegroundColor Green
    Write-Host "  El codigo esta correctamente implementado para persistencia" -ForegroundColor Green
    Write-Host ""
    Write-Host "SIGUIENTE PASO:" -ForegroundColor Yellow
    Write-Host "  Verifica manualmente en el emulador siguiendo las instrucciones" -ForegroundColor White
    Write-Host "  Si la app muestra 'ALREADY REGISTERED', IT-04 PASA" -ForegroundColor White
} else {
    Write-Host "ADVERTENCIA:" -ForegroundColor Yellow
    Write-Host "  Algunos componentes de persistencia faltan o estan incompletos" -ForegroundColor Yellow
    Write-Host "  Revisa LocalStorage.kt y MainActivity.kt" -ForegroundColor White
}

Write-Host ""
Write-Host "MECANISMO DE PERSISTENCIA:" -ForegroundColor Yellow
Write-Host "  Tecnologia: SharedPreferences (Android)" -ForegroundColor White
Write-Host "  Archivo: LocalStorage.kt" -ForegroundColor White
Write-Host "  Ambito: Private (solo esta app)" -ForegroundColor White
Write-Host "  Permanencia: Hasta que se desinstale la app" -ForegroundColor White
Write-Host ""
Write-Host "DATOS GUARDADOS:" -ForegroundColor Yellow
Write-Host "  - isRegistered (Boolean)" -ForegroundColor White
Write-Host "  - deviceId (String)" -ForegroundColor White
Write-Host "  - walletAddress (String)" -ForegroundColor White
Write-Host ""
