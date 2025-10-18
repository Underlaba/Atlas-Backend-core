# ============================================================================
# IT-08 - SEGURIDAD Y JWT (JSON WEB TOKEN)
# ============================================================================
# Objetivo: Verificar que el backend genera JWT al registrar un agente
#           y que ese token se usa correctamente en endpoints protegidos
# 
# Flujo esperado:
#   1. Registrar agente válido → Backend retorna JWT en la respuesta
#   2. Extraer el token del JSON
#   3. Usar el token en request a /assign-task (endpoint protegido)
#   4. Verificar que el endpoint permite acceso con token válido
#   5. Verificar que el endpoint rechaza requests sin token (401)
# ============================================================================

Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "IT-08 - SEGURIDAD Y JWT (JSON WEB TOKEN)" -ForegroundColor Cyan
Write-Host "============================================================================`n" -ForegroundColor Cyan

Write-Host "📋 OBJETIVO:" -ForegroundColor Yellow
Write-Host "   Verificar generación y uso de JWT para autenticación de agentes`n"

$baseUrl = "http://localhost:3000/api/agents"
$testsPassed = 0
$totalTests = 0

# ============================================================================
# TEST 1: REGISTRO DE AGENTE Y GENERACIÓN DE JWT
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "TEST 1: REGISTRO DE AGENTE Y GENERACIÓN DE JWT" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

$totalTests++

$deviceId = "test-jwt-device-" + (Get-Random -Minimum 10000 -Maximum 99999)
$walletAddress = "0x" + -join ((1..40) | ForEach-Object { '{0:x}' -f (Get-Random -Minimum 0 -Maximum 15) })

$registerBody = @{
    deviceId = $deviceId
    walletAddress = $walletAddress
} | ConvertTo-Json

Write-Host "📤 Registrando agente..." -ForegroundColor Yellow
Write-Host "   Device ID: $deviceId" -ForegroundColor Gray
Write-Host "   Wallet: $walletAddress`n" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/register" -Method Post -Body $registerBody -ContentType "application/json"
    
    Write-Host "STATUS: 201 Created" -ForegroundColor Green
    Write-Host "RESPONSE:" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 10) -ForegroundColor Gray
    Write-Host ""
    
    # Verificar que el token esta presente
    if ($response.data.token) {
        Write-Host "JWT TOKEN GENERADO" -ForegroundColor Green
        $tokenPreview = $response.data.token.Substring(0, [Math]::Min(50, $response.data.token.Length))
        Write-Host "   Token (primeros 50 chars): $tokenPreview..." -ForegroundColor Gray
        
        # Guardar el token para tests siguientes
        $global:agentToken = $response.data.token
        $global:agentId = $response.data.id
        $global:agentDeviceId = $response.data.deviceId
        
        Write-Host ""
        Write-Host "TEST 1 PASO: Registro retorna JWT" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "TEST 1 FALLO: No se genero JWT en el registro" -ForegroundColor Red
        Write-Host "   Respuesta no contiene data.token" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "❌ TEST 1 FALLÓ: Error en registro" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ============================================================================
# TEST 2: ACCESO A ENDPOINT PROTEGIDO CON TOKEN VÁLIDO
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "TEST 2: ACCESO A ENDPOINT PROTEGIDO CON TOKEN VÁLIDO" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

$totalTests++

$taskBody = @{
    taskId = "TASK-12345"
    description = "Complete data collection task"
} | ConvertTo-Json

Write-Host "📤 Request a /assign-task con JWT..." -ForegroundColor Yellow
Write-Host "   Authorization: Bearer <token>" -ForegroundColor Gray
Write-Host "   Task ID: TASK-12345`n" -ForegroundColor Gray

try {
    $headers = @{
        "Authorization" = "Bearer $global:agentToken"
    }
    
    $response = Invoke-RestMethod -Uri "$baseUrl/assign-task" `
                                  -Method Post `
                                  -Body $taskBody `
                                  -ContentType "application/json" `
                                  -Headers $headers
    
    Write-Host "✅ STATUS: 200 OK" -ForegroundColor Green
    Write-Host "📊 RESPONSE:" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 10) -ForegroundColor Gray
    Write-Host ""
    
    # Verificar que la respuesta es correcta
    if ($response.success -eq $true -and $response.data.taskId) {
        Write-Host "✅ Tarea asignada correctamente" -ForegroundColor Green
        Write-Host "   Agent ID: $($response.data.agentId)" -ForegroundColor Gray
        Write-Host "   Device ID: $($response.data.deviceId)" -ForegroundColor Gray
        Write-Host "   Task ID: $($response.data.taskId)" -ForegroundColor Gray
        Write-Host "   Status: $($response.data.status)" -ForegroundColor Gray
        
        Write-Host "`n✅ TEST 2 PASÓ: Token válido permite acceso" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "❌ TEST 2 FALLÓ: Respuesta inesperada" -ForegroundColor Red
    }
    
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "❌ TEST 2 FALLÓ: Error al acceder con token válido" -ForegroundColor Red
    Write-Host "   Status Code: $statusCode" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# ============================================================================
# TEST 3: ACCESO SIN TOKEN (DEBE SER RECHAZADO)
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "TEST 3: ACCESO SIN TOKEN (DEBE SER RECHAZADO)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

$totalTests++

Write-Host "📤 Request a /assign-task SIN token..." -ForegroundColor Yellow
Write-Host "   (No Authorization header)`n" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/assign-task" `
                                  -Method Post `
                                  -Body $taskBody `
                                  -ContentType "application/json"
    
    # Si llega aquí, el test falló (debería haber dado error 401)
    Write-Host "❌ TEST 3 FALLÓ: Endpoint permitió acceso sin token" -ForegroundColor Red
    Write-Host "   Respuesta: $($response | ConvertTo-Json)" -ForegroundColor Red
    
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    
    if ($statusCode -eq 401) {
        Write-Host "✅ STATUS: 401 Unauthorized (esperado)" -ForegroundColor Green
        
        # Intentar leer el mensaje de error
        try {
            $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            $errorBody = $streamReader.ReadToEnd() | ConvertFrom-Json
            Write-Host "📊 ERROR RESPONSE:" -ForegroundColor Cyan
            Write-Host ($errorBody | ConvertTo-Json -Depth 10) -ForegroundColor Gray
            
            if ($errorBody.message -match "No token provided" -or $errorBody.message -match "token") {
                Write-Host "`n✅ TEST 3 PASÓ: Acceso rechazado sin token (401)" -ForegroundColor Green
                $testsPassed++
            }
        } catch {
            Write-Host "`n✅ TEST 3 PASÓ: Acceso rechazado sin token (401)" -ForegroundColor Green
            $testsPassed++
        }
        
    } else {
        Write-Host "❌ TEST 3 FALLÓ: Status code incorrecto" -ForegroundColor Red
        Write-Host "   Esperado: 401, Recibido: $statusCode" -ForegroundColor Red
    }
}

Write-Host ""

# ============================================================================
# TEST 4: ACCESO CON TOKEN INVÁLIDO (DEBE SER RECHAZADO)
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "TEST 4: ACCESO CON TOKEN INVÁLIDO (DEBE SER RECHAZADO)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

$totalTests++

$invalidToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6OTk5LCJkZXZpY2VJZCI6ImZha2UiLCJpYXQiOjE2MDk0NTkyMDB9.invalid_signature"

Write-Host "📤 Request a /assign-task con token INVÁLIDO..." -ForegroundColor Yellow
Write-Host "   Authorization: Bearer <invalid_token>`n" -ForegroundColor Gray

try {
    $headers = @{
        "Authorization" = "Bearer $invalidToken"
    }
    
    $response = Invoke-RestMethod -Uri "$baseUrl/assign-task" `
                                  -Method Post `
                                  -Body $taskBody `
                                  -ContentType "application/json" `
                                  -Headers $headers
    
    # Si llega aquí, el test falló
    Write-Host "❌ TEST 4 FALLÓ: Endpoint permitió acceso con token inválido" -ForegroundColor Red
    
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    
    if ($statusCode -eq 401) {
        Write-Host "✅ STATUS: 401 Unauthorized (esperado)" -ForegroundColor Green
        
        try {
            $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            $errorBody = $streamReader.ReadToEnd() | ConvertFrom-Json
            Write-Host "📊 ERROR RESPONSE:" -ForegroundColor Cyan
            Write-Host ($errorBody | ConvertTo-Json -Depth 10) -ForegroundColor Gray
            
            if ($errorBody.message -match "Invalid" -or $errorBody.message -match "expired") {
                Write-Host "`n✅ TEST 4 PASÓ: Token inválido rechazado (401)" -ForegroundColor Green
                $testsPassed++
            }
        } catch {
            Write-Host "`n✅ TEST 4 PASÓ: Token inválido rechazado (401)" -ForegroundColor Green
            $testsPassed++
        }
        
    } else {
        Write-Host "❌ TEST 4 FALLÓ: Status code incorrecto" -ForegroundColor Red
        Write-Host "   Esperado: 401, Recibido: $statusCode" -ForegroundColor Red
    }
}

Write-Host ""

# ============================================================================
# TEST 5: VERIFICAR ESTRUCTURA DEL JWT (DECODE)
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "TEST 5: VERIFICAR ESTRUCTURA DEL JWT (DECODE)" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

$totalTests++

Write-Host "🔍 Decodificando JWT (sin verificar firma)..." -ForegroundColor Yellow

try {
    # JWT format: header.payload.signature
    $parts = $global:agentToken.Split('.')
    
    if ($parts.Count -eq 3) {
        Write-Host "✅ JWT tiene 3 partes (header.payload.signature)" -ForegroundColor Green
        
        # Decode payload (base64url)
        $payload = $parts[1]
        # Agregar padding si es necesario
        $padding = (4 - ($payload.Length % 4)) % 4
        $payload += "=" * $padding
        # Reemplazar caracteres base64url por base64
        $payload = $payload.Replace('-', '+').Replace('_', '/')
        
        $payloadBytes = [Convert]::FromBase64String($payload)
        $payloadJson = [System.Text.Encoding]::UTF8.GetString($payloadBytes)
        $payloadObj = $payloadJson | ConvertFrom-Json
        
        Write-Host "`n📊 JWT PAYLOAD:" -ForegroundColor Cyan
        Write-Host ($payloadObj | ConvertTo-Json -Depth 10) -ForegroundColor Gray
        Write-Host ""
        
        # Verificar campos esperados
        $hasId = $null -ne $payloadObj.id
        $hasDeviceId = $null -ne $payloadObj.deviceId
        $hasRole = $payloadObj.role -eq "agent"
        $hasIat = $null -ne $payloadObj.iat
        $hasExp = $null -ne $payloadObj.exp
        
        Write-Host "Verificando campos del payload:" -ForegroundColor Yellow
        if ($hasId) { Write-Host "   ✅ id: $($payloadObj.id)" -ForegroundColor Green } else { Write-Host "   ❌ id: missing" -ForegroundColor Red }
        if ($hasDeviceId) { Write-Host "   ✅ deviceId: $($payloadObj.deviceId)" -ForegroundColor Green } else { Write-Host "   ❌ deviceId: missing" -ForegroundColor Red }
        if ($hasRole) { Write-Host "   ✅ role: agent" -ForegroundColor Green } else { Write-Host "   ❌ role: $($payloadObj.role)" -ForegroundColor Red }
        if ($hasIat) { Write-Host "   ✅ iat (issued at): $($payloadObj.iat)" -ForegroundColor Green } else { Write-Host "   ❌ iat: missing" -ForegroundColor Red }
        if ($hasExp) { Write-Host "   ✅ exp (expires): $($payloadObj.exp)" -ForegroundColor Green } else { Write-Host "   ❌ exp: missing" -ForegroundColor Red }
        
        if ($hasId -and $hasDeviceId -and $hasRole -and $hasIat -and $hasExp) {
            Write-Host "`n✅ TEST 5 PASÓ: JWT contiene todos los campos requeridos" -ForegroundColor Green
            $testsPassed++
        } else {
            Write-Host "`n❌ TEST 5 FALLÓ: JWT no contiene todos los campos requeridos" -ForegroundColor Red
        }
        
    } else {
        Write-Host "❌ TEST 5 FALLÓ: JWT no tiene formato válido" -ForegroundColor Red
        Write-Host "   Partes encontradas: $($parts.Count)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ TEST 5 FALLÓ: Error al decodificar JWT" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# ============================================================================
# RESUMEN DE TESTS
# ============================================================================

Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "RESUMEN DE IT-08" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

Write-Host "Tests ejecutados: $totalTests" -ForegroundColor White
Write-Host "Tests exitosos:   $testsPassed" -ForegroundColor Green
Write-Host "Tests fallidos:   $($totalTests - $testsPassed)" -ForegroundColor $(if ($testsPassed -eq $totalTests) { "Green" } else { "Red" })
Write-Host ""

if ($testsPassed -eq $totalTests) {
    Write-Host "✅ IT-08 COMPLETO: Todos los tests de seguridad JWT pasaron" -ForegroundColor Green
    Write-Host ""
    Write-Host "Funcionalidades verificadas:" -ForegroundColor Cyan
    Write-Host "   ✓ Backend genera JWT al registrar agente" -ForegroundColor Green
    Write-Host "   ✓ JWT contiene información del agente (id, deviceId, role)" -ForegroundColor Green
    Write-Host "   ✓ Endpoint /assign-task requiere autenticación" -ForegroundColor Green
    Write-Host "   ✓ Token válido permite acceso a endpoint protegido" -ForegroundColor Green
    Write-Host "   ✓ Request sin token es rechazado (401)" -ForegroundColor Green
    Write-Host "   ✓ Token inválido es rechazado (401)" -ForegroundColor Green
    Write-Host "   ✓ JWT tiene estructura correcta con expiración" -ForegroundColor Green
    Write-Host ""
    exit 0
} else {
    Write-Host "❌ IT-08 FALLÓ: Algunos tests no pasaron" -ForegroundColor Red
    Write-Host ""
    exit 1
}
