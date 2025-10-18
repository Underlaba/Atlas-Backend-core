# ===================================================================
# TEST IT-04: PERSISTENCIA DE ESTADO
# ===================================================================
# Objetivo: Verificar que la app mantiene el estado tras cerrar y reabrir
# Expected: App muestra "Already registered" con datos guardados
# ===================================================================

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  TEST IT-04: PERSISTENCIA DE ESTADO" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Contador de tests
$testsPassed = 0

# ===================================================================
# PREPARACION
# ===================================================================
Write-Host "[PREPARACION]" -ForegroundColor Yellow
Write-Host ""
Write-Host "Este test requiere interaccion MANUAL con el emulador Android:" -ForegroundColor White
Write-Host ""
Write-Host "PASOS A SEGUIR:" -ForegroundColor Yellow
Write-Host "  1. Abrir Android Studio" -ForegroundColor White
Write-Host "  2. Ejecutar la app en el emulador" -ForegroundColor White
Write-Host "  3. Realizar un registro exitoso (si no esta registrado)" -ForegroundColor White
Write-Host "  4. CERRAR completamente la app (swipe up o back button)" -ForegroundColor White
Write-Host "  5. REABRIR la app desde el launcher" -ForegroundColor White
Write-Host "  6. Verificar que muestra 'Already registered'" -ForegroundColor White
Write-Host ""

# ===================================================================
# TEST 1: VERIFICAR BACKEND ACTIVO
# ===================================================================
Write-Host "[TEST 1/5] Verificando Backend..." -ForegroundColor Yellow

try {
    $healthCheck = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/health" -Method GET -ErrorAction Stop
    if ($healthCheck.success) {
        Write-Host "  PASS Backend esta activo" -ForegroundColor Green
        $testsPassed++
    }
} catch {
    Write-Host "  FAIL Backend no responde" -ForegroundColor Red
    Write-Host "  ERROR: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Abortando test. Inicia el servidor con:" -ForegroundColor Yellow
    Write-Host "  & 'D:\Users\alexj\Proyectos\Atlas\backend-core\switch-to-main-server.ps1'" -ForegroundColor White
    exit 1
}
Write-Host ""

# ===================================================================
# TEST 2: VERIFICAR REGISTRO EXISTENTE EN BD
# ===================================================================
Write-Host "[TEST 2/5] Verificando Registro en Base de Datos..." -ForegroundColor Yellow

Push-Location "D:\Users\alexj\Proyectos\Atlas\backend-core"

try {
    $dbResult = node query-agents.js 2>&1 | Out-String
    
    if ($dbResult -match "Total de agentes encontrados: (\d+)") {
        $agentCount = [int]$matches[1]
        
        if ($agentCount -gt 0) {
            Write-Host "  PASS Hay $agentCount agente(s) registrado(s) en BD" -ForegroundColor Green
            
            # Extraer informacion del primer agente
            if ($dbResult -match "Device ID: ([^\r\n]+)") {
                $registeredDeviceId = $matches[1].Trim()
                Write-Host "  Device ID registrado: $registeredDeviceId" -ForegroundColor Gray
            }
            
            if ($dbResult -match "Wallet Address: ([^\r\n]+)") {
                $registeredWallet = $matches[1].Trim()
                Write-Host "  Wallet registrada: $registeredWallet" -ForegroundColor Gray
            }
            
            $testsPassed++
        } else {
            Write-Host "  ADVERTENCIA No hay agentes registrados en BD" -ForegroundColor Yellow
            Write-Host "  Necesitas ejecutar IT-02 primero para registrar un agente" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "  FAIL Error al consultar base de datos" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
} finally {
    Pop-Location
}

Write-Host ""

# ===================================================================
# TEST 3: INSTRUCCIONES PARA VERIFICACION MANUAL
# ===================================================================
Write-Host "[TEST 3/5] Verificacion Manual - Persistencia en App" -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANTE: Este test requiere que VERIFIQUES manualmente en el emulador" -ForegroundColor Yellow
Write-Host ""
Write-Host "CHECKLIST DE VERIFICACION:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  [ ] 1. App muestra 'ALREADY REGISTERED'" -ForegroundColor White
Write-Host "  [ ] 2. Device ID esta visible y coincide con BD" -ForegroundColor White
Write-Host "  [ ] 3. Wallet Address esta visible y coincide con BD" -ForegroundColor White
Write-Host "  [ ] 4. Boton 'REGISTER AGENT' esta DESHABILITADO" -ForegroundColor White
Write-Host "  [ ] 5. TextField de wallet esta DESHABILITADO" -ForegroundColor White
Write-Host ""
Write-Host "DATOS ESPERADOS EN LA APP:" -ForegroundColor Cyan
if ($registeredDeviceId) {
    Write-Host "  Device ID: $registeredDeviceId" -ForegroundColor White
}
if ($registeredWallet) {
    Write-Host "  Wallet: $registeredWallet" -ForegroundColor White
}
Write-Host ""

$verification = Read-Host "La app muestra 'ALREADY REGISTERED' con los datos correctos? (S/N)"

if ($verification -eq "S" -or $verification -eq "s") {
    Write-Host "  PASS Persistencia verificada manualmente" -ForegroundColor Green
    $testsPassed++
} else {
    Write-Host "  FAIL La app no mantiene el estado de registro" -ForegroundColor Red
}

Write-Host ""

# ===================================================================
# TEST 4: VERIFICAR ARCHIVO DE CODIGO - LocalStorage
# ===================================================================
Write-Host "[TEST 4/5] Verificando Implementacion de LocalStorage..." -ForegroundColor Yellow

$localStoragePath = "D:\Users\alexj\Proyectos\Atlas\agent-app\app\src\main\java\com\underlaba\atlas\agentapp\data\LocalStorage.kt"

if (Test-Path $localStoragePath) {
    $localStorageContent = Get-Content $localStoragePath -Raw
    
    $hasIsRegistered = $localStorageContent -match "fun isRegistered"
    $hasSharedPreferences = $localStorageContent -match "SharedPreferences"
    $hasSaveDeviceId = $localStorageContent -match "fun saveDeviceId"
    $hasSaveWallet = $localStorageContent -match "fun saveWalletAddress"
    
    Write-Host "  Metodos implementados:" -ForegroundColor White
    Write-Host "    isRegistered(): $(if($hasIsRegistered){'OK'}else{'FALTA'})" -ForegroundColor $(if($hasIsRegistered){'Green'}else{'Red'})
    Write-Host "    SharedPreferences: $(if($hasSharedPreferences){'OK'}else{'FALTA'})" -ForegroundColor $(if($hasSharedPreferences){'Green'}else{'Red'})
    Write-Host "    saveDeviceId(): $(if($hasSaveDeviceId){'OK'}else{'FALTA'})" -ForegroundColor $(if($hasSaveDeviceId){'Green'}else{'Red'})
    Write-Host "    saveWalletAddress(): $(if($hasSaveWallet){'OK'}else{'FALTA'})" -ForegroundColor $(if($hasSaveWallet){'Green'}else{'Red'})
    
    if ($hasIsRegistered -and $hasSharedPreferences -and $hasSaveDeviceId -and $hasSaveWallet) {
        Write-Host "  PASS LocalStorage correctamente implementado" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  FAIL LocalStorage incompleto" -ForegroundColor Red
    }
} else {
    Write-Host "  FAIL No se encuentra LocalStorage.kt" -ForegroundColor Red
}

Write-Host ""

# ===================================================================
# TEST 5: VERIFICAR LOGICA EN MAINACTIVITY
# ===================================================================
Write-Host "[TEST 5/5] Verificando Logica de Persistencia en MainActivity..." -ForegroundColor Yellow

$mainActivityPath = "D:\Users\alexj\Proyectos\Atlas\agent-app\app\src\main\java\com\underlaba\atlas\agentapp\MainActivity.kt"

if (Test-Path $mainActivityPath) {
    $mainActivityContent = Get-Content $mainActivityPath -Raw
    
    $checksIsRegistered = $mainActivityContent -match "localStorage\.isRegistered"
    $loadsDeviceId = $mainActivityContent -match "localStorage\.getDeviceId"
    $loadsWallet = $mainActivityContent -match "localStorage\.getWalletAddress"
    $showsRegisteredState = $mainActivityContent -match "statusText\.text.*registered" -or $mainActivityContent -match "ALREADY REGISTERED"
    
    Write-Host "  Funcionalidades verificadas:" -ForegroundColor White
    Write-Host "    Verifica isRegistered(): $(if($checksIsRegistered){'OK'}else{'FALTA'})" -ForegroundColor $(if($checksIsRegistered){'Green'}else{'Red'})
    Write-Host "    Carga Device ID: $(if($loadsDeviceId){'OK'}else{'FALTA'})" -ForegroundColor $(if($loadsDeviceId){'Green'}else{'Red'})
    Write-Host "    Carga Wallet: $(if($loadsWallet){'OK'}else{'FALTA'})" -ForegroundColor $(if($loadsWallet){'Green'}else{'Red'})
    Write-Host "    Muestra estado 'registered': $(if($showsRegisteredState){'OK'}else{'FALTA'})" -ForegroundColor $(if($showsRegisteredState){'Green'}else{'Red'})
    
    if ($checksIsRegistered -and $loadsDeviceId -and $loadsWallet -and $showsRegisteredState) {
        Write-Host "  PASS MainActivity maneja persistencia correctamente" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  FAIL MainActivity no implementa persistencia completamente" -ForegroundColor Red
    }
} else {
    Write-Host "  FAIL No se encuentra MainActivity.kt" -ForegroundColor Red
}

Write-Host ""

# ===================================================================
# RESUMEN FINAL
# ===================================================================
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  RESUMEN FINAL IT-04" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$totalTests = 5

if ($testsPassed -eq $totalTests) {
    Write-Host "  RESULTADO: TEST IT-04 COMPLETO" -ForegroundColor Green
    Write-Host "  Tests Pasados: $testsPassed/$totalTests" -ForegroundColor Green
    Write-Host ""
    Write-Host "  VERIFICACIONES COMPLETADAS:" -ForegroundColor Green
    Write-Host "    [OK] Backend Activo" -ForegroundColor Green
    Write-Host "    [OK] Registro en Base de Datos" -ForegroundColor Green
    Write-Host "    [OK] Persistencia Visual en App" -ForegroundColor Green
    Write-Host "    [OK] LocalStorage Implementado" -ForegroundColor Green
    Write-Host "    [OK] MainActivity con Logica de Persistencia" -ForegroundColor Green
} else {
    Write-Host "  RESULTADO: TESTS INCOMPLETOS" -ForegroundColor Yellow
    Write-Host "  Tests Pasados: $testsPassed/$totalTests" -ForegroundColor Yellow
    Write-Host "  Tests Fallidos: $($totalTests - $testsPassed)" -ForegroundColor Red
}

Write-Host ""
Write-Host "MECANISMO DE PERSISTENCIA:" -ForegroundColor Yellow
Write-Host "  Tecnologia: SharedPreferences (Android)" -ForegroundColor White
Write-Host "  Ubicacion: LocalStorage.kt" -ForegroundColor White
Write-Host "  Datos Guardados:" -ForegroundColor White
Write-Host "    - Device ID" -ForegroundColor Gray
Write-Host "    - Wallet Address" -ForegroundColor Gray
Write-Host "    - Estado 'isRegistered'" -ForegroundColor Gray
Write-Host ""
Write-Host "COMPORTAMIENTO VERIFICADO:" -ForegroundColor Yellow
Write-Host "  Cuando la app se abre:" -ForegroundColor White
Write-Host "    1. Verifica localStorage.isRegistered()" -ForegroundColor Gray
Write-Host "    2. Si true, carga datos guardados" -ForegroundColor Gray
Write-Host "    3. Muestra 'ALREADY REGISTERED'" -ForegroundColor Gray
Write-Host "    4. Deshabilita campos de entrada" -ForegroundColor Gray
Write-Host "    5. Muestra Device ID y Wallet guardados" -ForegroundColor Gray
Write-Host ""

if ($testsPassed -eq $totalTests) {
    Write-Host "CONCLUSION:" -ForegroundColor Yellow
    Write-Host "  La persistencia de estado funciona CORRECTAMENTE" -ForegroundColor Green
    Write-Host "  La app mantiene el registro tras cerrar y reabrir" -ForegroundColor Green
} else {
    Write-Host "ADVERTENCIA:" -ForegroundColor Yellow
    Write-Host "  Algunos aspectos de la persistencia requieren revision" -ForegroundColor Red
}

Write-Host ""
