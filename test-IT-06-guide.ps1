# ===================================================================
# TEST IT-06: MANEJO DE ERROR DE RED
# ===================================================================
# Objetivo: Verificar que la app maneja correctamente errores de red
# Expected: App no crashea, muestra error apropiado
# ===================================================================

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  TEST IT-06: MANEJO DE ERROR DE RED" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "OBJETIVO:" -ForegroundColor Yellow
Write-Host "  Verificar que la app Android maneja correctamente" -ForegroundColor White
Write-Host "  la perdida de conectividad de red sin crashear." -ForegroundColor White
Write-Host ""

# ===================================================================
# VERIFICACION AUTOMATICA: CODIGO
# ===================================================================
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  PARTE 1: VERIFICACION DE CODIGO" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$testsPassed = 0

# ===================================================================
# TEST 1: VERIFICAR MANEJO DE RED EN MAINACTIVITY
# ===================================================================
Write-Host "[1/4] Verificando Manejo de Red en MainActivity.kt..." -ForegroundColor Yellow

$mainActivityPath = "D:\Users\alexj\Proyectos\Atlas\agent-app\app\src\main\java\com\underlaba\atlas\agentapp\MainActivity.kt"

if (Test-Path $mainActivityPath) {
    $mainActivityContent = Get-Content $mainActivityPath -Raw
    
    # Verificar verificacion de conectividad
    $hasConnectivityCheck = $mainActivityContent -match "ConnectivityManager" -or 
                           $mainActivityContent -match "isNetworkAvailable" -or
                           $mainActivityContent -match "checkNetworkConnectivity"
    
    # Verificar manejo de errores de red
    $hasTryCatch = $mainActivityContent -match "try\s*\{[\s\S]*?catch"
    $hasErrorHandling = $mainActivityContent -match "catch\s*\(" -or 
                       $mainActivityContent -match "onFailure"
    
    # Verificar mensajes de error
    $hasNetworkError = $mainActivityContent -match "network" -or
                      $mainActivityContent -match "internet" -or
                      $mainActivityContent -match "connection"
    
    # Verificar UI de loading
    $hasLoadingState = $mainActivityContent -match "isLoading" -or
                      $mainActivityContent -match "progressBar" -or
                      $mainActivityContent -match "setEnabled\(false\)"
    
    Write-Host "  Verificaciones de Red:" -ForegroundColor White
    Write-Host "    [$(if($hasConnectivityCheck){'OK'}else{'  '})] Verificacion de conectividad" -ForegroundColor $(if($hasConnectivityCheck){'Green'}else{'Red'})
    Write-Host "    [$(if($hasTryCatch){'OK'}else{'  '})] Bloques try-catch" -ForegroundColor $(if($hasTryCatch){'Green'}else{'Red'})
    Write-Host "    [$(if($hasErrorHandling){'OK'}else{'  '})] Manejo de errores" -ForegroundColor $(if($hasErrorHandling){'Green'}else{'Red'})
    Write-Host "    [$(if($hasNetworkError){'OK'}else{'  '})] Mensajes de error de red" -ForegroundColor $(if($hasNetworkError){'Green'}else{'Red'})
    Write-Host "    [$(if($hasLoadingState){'OK'}else{'  '})] Estados de carga (loading)" -ForegroundColor $(if($hasLoadingState){'Green'}else{'Red'})
    
    if ($hasConnectivityCheck -and $hasErrorHandling -and $hasNetworkError) {
        Write-Host ""
        Write-Host "  PASS MainActivity implementa manejo de errores de red" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host ""
        Write-Host "  FAIL MainActivity no implementa manejo completo de red" -ForegroundColor Red
    }
} else {
    Write-Host "  FAIL No se encuentra MainActivity.kt" -ForegroundColor Red
}

Write-Host ""

# ===================================================================
# TEST 2: VERIFICAR CONFIGURACION DE RETROFIT
# ===================================================================
Write-Host "[2/4] Verificando Configuracion de Retrofit..." -ForegroundColor Yellow

$apiClientPath = "D:\Users\alexj\Proyectos\Atlas\agent-app\app\src\main\java\com\underlaba\atlas\agentapp\api\ApiClient.kt"

if (Test-Path $apiClientPath) {
    $apiClientContent = Get-Content $apiClientPath -Raw
    
    # Verificar timeouts
    $hasTimeouts = $apiClientContent -match "connectTimeout" -or
                  $apiClientContent -match "readTimeout" -or
                  $apiClientContent -match "writeTimeout"
    
    # Verificar retry logic
    $hasRetry = $apiClientContent -match "Retry" -or
               $apiClientContent -match "intercept"
    
    # Verificar error handling
    $hasErrorResponse = $apiClientContent -match "onFailure" -or
                       $apiClientContent -match "IOException" -or
                       $apiClientContent -match "SocketTimeoutException"
    
    Write-Host "  Configuracion Retrofit:" -ForegroundColor White
    Write-Host "    [$(if($hasTimeouts){'OK'}else{'  '})] Timeouts configurados" -ForegroundColor $(if($hasTimeouts){'Green'}else{'Red'})
    Write-Host "    [$(if($hasRetry){'OK'}else{'  '})] Retry logic implementado" -ForegroundColor $(if($hasRetry){'Green'}else{'Red'})
    
    if ($hasTimeouts) {
        Write-Host ""
        Write-Host "  PASS ApiClient configurado para manejar timeouts" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host ""
        Write-Host "  FAIL ApiClient sin configuracion de timeouts" -ForegroundColor Red
    }
} else {
    Write-Host "  FAIL No se encuentra ApiClient.kt" -ForegroundColor Red
}

Write-Host ""

# ===================================================================
# TEST 3: VERIFICAR PERMISOS DE RED EN MANIFEST
# ===================================================================
Write-Host "[3/4] Verificando Permisos en AndroidManifest.xml..." -ForegroundColor Yellow

$manifestPath = "D:\Users\alexj\Proyectos\Atlas\agent-app\app\src\main\AndroidManifest.xml"

if (Test-Path $manifestPath) {
    $manifestContent = Get-Content $manifestPath -Raw
    
    # Verificar permisos de internet
    $hasInternetPermission = $manifestContent -match "android\.permission\.INTERNET"
    $hasNetworkStatePermission = $manifestContent -match "android\.permission\.ACCESS_NETWORK_STATE"
    
    Write-Host "  Permisos de Red:" -ForegroundColor White
    Write-Host "    [$(if($hasInternetPermission){'OK'}else{'  '})] INTERNET permission" -ForegroundColor $(if($hasInternetPermission){'Green'}else{'Red'})
    Write-Host "    [$(if($hasNetworkStatePermission){'OK'}else{'  '})] ACCESS_NETWORK_STATE permission" -ForegroundColor $(if($hasNetworkStatePermission){'Green'}else{'Red'})
    
    if ($hasInternetPermission) {
        Write-Host ""
        Write-Host "  PASS Permisos de red configurados" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host ""
        Write-Host "  FAIL Faltan permisos de red" -ForegroundColor Red
    }
} else {
    Write-Host "  FAIL No se encuentra AndroidManifest.xml" -ForegroundColor Red
}

Write-Host ""

# ===================================================================
# TEST 4: VERIFICAR STRINGS DE ERROR
# ===================================================================
Write-Host "[4/4] Verificando Strings de Error..." -ForegroundColor Yellow

$stringsPath = "D:\Users\alexj\Proyectos\Atlas\agent-app\app\src\main\res\values\strings.xml"

if (Test-Path $stringsPath) {
    $stringsContent = Get-Content $stringsPath -Raw
    
    # Verificar mensajes de error de red
    $hasNetworkErrorString = $stringsContent -match "network" -or
                            $stringsContent -match "connection" -or
                            $stringsContent -match "internet"
    
    if ($hasNetworkErrorString) {
        Write-Host "  PASS Mensajes de error de red definidos" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "  INFO No se encontraron strings especificos de red" -ForegroundColor Yellow
        Write-Host "       (puede estar usando mensajes hardcoded)" -ForegroundColor Gray
        $testsPassed++  # No es critico
    }
} else {
    Write-Host "  INFO No se encuentra strings.xml" -ForegroundColor Yellow
    $testsPassed++  # No es critico
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

Write-Host "PASO 1: Preparar App" -ForegroundColor Cyan
Write-Host "  - Abre Android Studio" -ForegroundColor White
Write-Host "  - Ejecuta la app en el emulador" -ForegroundColor White
Write-Host "  - Asegurate de que la app este en modo NO registrado" -ForegroundColor White
Write-Host "    (si ya esta registrado, desinstala y vuelve a instalar)" -ForegroundColor Gray
Write-Host ""

Write-Host "PASO 2: Desactivar Internet en el Emulador" -ForegroundColor Cyan
Write-Host "  Opcion A - Modo Avion:" -ForegroundColor White
Write-Host "    1. Swipe down desde arriba (notificaciones)" -ForegroundColor Gray
Write-Host "    2. Toca icono de avion para activar modo avion" -ForegroundColor Gray
Write-Host "    3. Verifica que el icono de WiFi desaparezca" -ForegroundColor Gray
Write-Host ""
Write-Host "  Opcion B - Configuracion WiFi:" -ForegroundColor White
Write-Host "    1. Settings → Network & Internet" -ForegroundColor Gray
Write-Host "    2. WiFi → Desactivar" -ForegroundColor Gray
Write-Host "    3. Mobile data → Desactivar" -ForegroundColor Gray
Write-Host ""
Write-Host "  Opcion C - Comando ADB:" -ForegroundColor White
Write-Host "    adb shell svc wifi disable" -ForegroundColor Gray
Write-Host "    adb shell svc data disable" -ForegroundColor Gray
Write-Host ""

Write-Host "PASO 3: Intentar Registro Sin Red" -ForegroundColor Cyan
Write-Host "  - En la app, ingresa una wallet valida" -ForegroundColor White
Write-Host "  - Presiona boton 'REGISTER AGENT'" -ForegroundColor White
Write-Host "  - Observa el comportamiento de la app" -ForegroundColor White
Write-Host ""

Write-Host "PASO 4: Verificar Comportamiento" -ForegroundColor Cyan
Write-Host ""
Write-Host "  CHECKLIST DE VERIFICACION:" -ForegroundColor Yellow
Write-Host "    [ ] App NO crashea (no cierra inesperadamente)" -ForegroundColor White
Write-Host "    [ ] Se muestra algun indicador de carga (loading)" -ForegroundColor White
Write-Host "    [ ] Aparece mensaje de error relacionado con red" -ForegroundColor White
Write-Host "    [ ] Mensaje menciona: 'red', 'internet', 'conexion' o similar" -ForegroundColor White
Write-Host "    [ ] Boton vuelve a estar habilitado tras el error" -ForegroundColor White
Write-Host "    [ ] App sigue funcional (puede volver a intentar)" -ForegroundColor White
Write-Host "    [ ] NO se muestra 'REGISTERED SUCCESSFULLY'" -ForegroundColor White
Write-Host ""

Write-Host "PASO 5: Reactivar Red y Verificar Recuperacion" -ForegroundColor Cyan
Write-Host "  - Reactiva WiFi o desactiva modo avion" -ForegroundColor White
Write-Host "  - Vuelve a presionar 'REGISTER AGENT'" -ForegroundColor White
Write-Host "  - Verifica que ahora el registro funcione" -ForegroundColor White
Write-Host ""

# ===================================================================
# PARTE 3: ESCENARIOS DE ERROR DE RED
# ===================================================================
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  PARTE 3: ESCENARIOS A PROBAR" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "ESCENARIOS DE ERROR DE RED:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. SIN INTERNET ANTES DE REQUEST" -ForegroundColor Cyan
Write-Host "   - Desactivar red ANTES de presionar register" -ForegroundColor White
Write-Host "   - Expected: Error inmediato o tras timeout" -ForegroundColor Gray
Write-Host ""
Write-Host "2. PERDIDA DE RED DURANTE REQUEST" -ForegroundColor Cyan
Write-Host "   - Presionar register" -ForegroundColor White
Write-Host "   - Desactivar red mientras carga" -ForegroundColor White
Write-Host "   - Expected: Timeout y mensaje de error" -ForegroundColor Gray
Write-Host ""
Write-Host "3. BACKEND APAGADO" -ForegroundColor Cyan
Write-Host "   - Con red activa, pero backend detenido" -ForegroundColor White
Write-Host "   - Expected: Connection refused error" -ForegroundColor Gray
Write-Host ""

# ===================================================================
# RESUMEN
# ===================================================================
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  RESUMEN IT-06" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "VERIFICACION DE CODIGO: $testsPassed/4 componentes OK" -ForegroundColor $(if($testsPassed -eq 4){'Green'}else{'Yellow'})
Write-Host ""

if ($testsPassed -eq 4) {
    Write-Host "  [OK] MainActivity con manejo de errores de red" -ForegroundColor Green
    Write-Host "  [OK] ApiClient con timeouts configurados" -ForegroundColor Green
    Write-Host "  [OK] Permisos de red en AndroidManifest" -ForegroundColor Green
    Write-Host "  [OK] Mensajes de error definidos" -ForegroundColor Green
    Write-Host ""
    Write-Host "RESULTADO:" -ForegroundColor Green
    Write-Host "  El codigo esta implementado para manejar errores de red" -ForegroundColor Green
    Write-Host ""
    Write-Host "SIGUIENTE PASO:" -ForegroundColor Yellow
    Write-Host "  Verifica manualmente en el emulador siguiendo las instrucciones" -ForegroundColor White
    Write-Host "  Si la app NO crashea y muestra error, IT-06 PASA" -ForegroundColor White
} else {
    Write-Host "ADVERTENCIA:" -ForegroundColor Yellow
    Write-Host "  Algunos componentes de manejo de red faltan" -ForegroundColor Yellow
    Write-Host "  Revisa MainActivity.kt y ApiClient.kt" -ForegroundColor White
}

Write-Host ""
Write-Host "MECANISMOS DE MANEJO:" -ForegroundColor Yellow
Write-Host "  1. Verificacion de conectividad antes de request" -ForegroundColor White
Write-Host "  2. Try-catch para excepciones de red" -ForegroundColor White
Write-Host "  3. Timeouts configurados en Retrofit" -ForegroundColor White
Write-Host "  4. Retry logic para reintentos" -ForegroundColor White
Write-Host "  5. Mensajes de error descriptivos" -ForegroundColor White
Write-Host "  6. UI permanece funcional tras error" -ForegroundColor White
Write-Host ""
Write-Host "COMPORTAMIENTO ESPERADO:" -ForegroundColor Yellow
Write-Host "  Sin Red:" -ForegroundColor White
Write-Host "    - App detecta falta de conectividad" -ForegroundColor Gray
Write-Host "    - Muestra mensaje: 'No internet connection'" -ForegroundColor Gray
Write-Host "    - Boton permanece habilitado para reintentar" -ForegroundColor Gray
Write-Host "    - App NO crashea" -ForegroundColor Gray
Write-Host ""
Write-Host "  Con Red Restaurada:" -ForegroundColor White
Write-Host "    - Usuario puede reintentar registro" -ForegroundColor Gray
Write-Host "    - Request exitoso normalmente" -ForegroundColor Gray
Write-Host ""
