# ==============================================================================
# IT-08 - SEGURIDAD Y JWT (JSON WEB TOKEN)
# ==============================================================================
# Objetivo: Verificar que el backend genera JWT al registrar un agente
#           y que ese token se usa correctamente en endpoints protegidos
# ==============================================================================

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "IT-08 - SEGURIDAD Y JWT (JSON WEB TOKEN)" -ForegroundColor Cyan
Write-Host "==============================================================================`n" -ForegroundColor Cyan

Write-Host "OBJETIVO:" -ForegroundColor Yellow
Write-Host "   Verificar generacion y uso de JWT para autenticacion de agentes`n"

$baseUrl = "http://localhost:3000/api/v1/agents"
$testsPassed = 0
$totalTests = 0

# ==============================================================================
# TEST 1: REGISTRO DE AGENTE Y GENERACION DE JWT
# ==============================================================================

Write-Host "------------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "TEST 1: REGISTRO DE AGENTE Y GENERACION DE JWT" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------------------------`n" -ForegroundColor Cyan

$totalTests++

$deviceId = "test-jwt-device-" + (Get-Random -Minimum 10000 -Maximum 99999)
$walletAddress = "0x" + -join ((1..40) | ForEach-Object { '{0:x}' -f (Get-Random -Minimum 0 -Maximum 15) })

$registerBody = @{
    deviceId = $deviceId
    walletAddress = $walletAddress
} | ConvertTo-Json

Write-Host "Registrando agente..." -ForegroundColor Yellow
Write-Host "   Device ID: $deviceId" -ForegroundColor Gray
Write-Host "   Wallet: $walletAddress`n" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/register" -Method Post -Body $registerBody -ContentType "application/json"
    
    Write-Host "[OK] STATUS: 201 Created" -ForegroundColor Green
    Write-Host "RESPONSE:" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 10) -ForegroundColor Gray
    Write-Host ""
    
    if ($response.data.token) {
        Write-Host "[OK] JWT TOKEN GENERADO" -ForegroundColor Green
        $tokenPreview = $response.data.token.Substring(0, [Math]::Min(50, $response.data.token.Length))
        Write-Host "   Token: $tokenPreview..." -ForegroundColor Gray
        
        $global:agentToken = $response.data.token
        $global:agentId = $response.data.id
        $global:agentDeviceId = $response.data.deviceId
        
        Write-Host ""
        Write-Host "[PASS] TEST 1: Registro retorna JWT" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "[FAIL] TEST 1: No se genero JWT en el registro" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "[FAIL] TEST 1: Error en registro" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# ==============================================================================
# TEST 2: ACCESO A ENDPOINT PROTEGIDO CON TOKEN VALIDO
# ==============================================================================

Write-Host "------------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "TEST 2: ACCESO A ENDPOINT PROTEGIDO CON TOKEN VALIDO" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------------------------`n" -ForegroundColor Cyan

$totalTests++

$taskBody = @{
    taskId = "TASK-12345"
    description = "Complete data collection task"
} | ConvertTo-Json

Write-Host "Request a /assign-task con JWT..." -ForegroundColor Yellow
Write-Host "   Authorization: Bearer [token]" -ForegroundColor Gray
Write-Host "   Task ID: TASK-12345`n" -ForegroundColor Gray

try {
    $headers = @{
        "Authorization" = "Bearer $global:agentToken"
    }
    
    $response = Invoke-RestMethod -Uri "$baseUrl/assign-task" -Method Post -Body $taskBody -ContentType "application/json" -Headers $headers
    
    Write-Host "[OK] STATUS: 200 OK" -ForegroundColor Green
    Write-Host "RESPONSE:" -ForegroundColor Cyan
    Write-Host ($response | ConvertTo-Json -Depth 10) -ForegroundColor Gray
    Write-Host ""
    
    if ($response.success -eq $true -and $response.data.taskId) {
        Write-Host "[OK] Tarea asignada correctamente" -ForegroundColor Green
        Write-Host "   Agent ID: $($response.data.agentId)" -ForegroundColor Gray
        Write-Host "   Device ID: $($response.data.deviceId)" -ForegroundColor Gray
        Write-Host "   Task ID: $($response.data.taskId)" -ForegroundColor Gray
        Write-Host "   Status: $($response.data.status)" -ForegroundColor Gray
        
        Write-Host ""
        Write-Host "[PASS] TEST 2: Token valido permite acceso" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "[FAIL] TEST 2: Respuesta inesperada" -ForegroundColor Red
    }
    
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "[FAIL] TEST 2: Error al acceder con token valido" -ForegroundColor Red
    Write-Host "   Status Code: $statusCode" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# ==============================================================================
# TEST 3: ACCESO SIN TOKEN (DEBE SER RECHAZADO)
# ==============================================================================

Write-Host "------------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "TEST 3: ACCESO SIN TOKEN (DEBE SER RECHAZADO)" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------------------------`n" -ForegroundColor Cyan

$totalTests++

Write-Host "Request a /assign-task SIN token..." -ForegroundColor Yellow
Write-Host "   (No Authorization header)`n" -ForegroundColor Gray

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/assign-task" -Method Post -Body $taskBody -ContentType "application/json"
    
    Write-Host "[FAIL] TEST 3: Endpoint permitio acceso sin token" -ForegroundColor Red
    
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    
    if ($statusCode -eq 401) {
        Write-Host "[OK] STATUS: 401 Unauthorized (esperado)" -ForegroundColor Green
        
        try {
            $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            $errorBody = $streamReader.ReadToEnd() | ConvertFrom-Json
            Write-Host "ERROR RESPONSE:" -ForegroundColor Cyan
            Write-Host ($errorBody | ConvertTo-Json -Depth 10) -ForegroundColor Gray
            $streamReader.Close()
        } catch {
            # Ignore parsing errors
        }
        
        Write-Host ""
        Write-Host "[PASS] TEST 3: Acceso rechazado sin token (401)" -ForegroundColor Green
        $testsPassed++
        
    } else {
        Write-Host "[FAIL] TEST 3: Status code incorrecto" -ForegroundColor Red
        Write-Host "   Esperado: 401, Recibido: $statusCode" -ForegroundColor Red
    }
}

Write-Host ""

# ==============================================================================
# TEST 4: ACCESO CON TOKEN INVALIDO (DEBE SER RECHAZADO)
# ==============================================================================

Write-Host "------------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "TEST 4: ACCESO CON TOKEN INVALIDO (DEBE SER RECHAZADO)" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------------------------`n" -ForegroundColor Cyan

$totalTests++

$invalidToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6OTk5LCJkZXZpY2VJZCI6ImZha2UiLCJpYXQiOjE2MDk0NTkyMDB9.invalid_signature"

Write-Host "Request a /assign-task con token INVALIDO..." -ForegroundColor Yellow
Write-Host "   Authorization: Bearer [invalid_token]`n" -ForegroundColor Gray

try {
    $headers = @{
        "Authorization" = "Bearer $invalidToken"
    }
    
    $response = Invoke-RestMethod -Uri "$baseUrl/assign-task" -Method Post -Body $taskBody -ContentType "application/json" -Headers $headers
    
    Write-Host "[FAIL] TEST 4: Endpoint permitio acceso con token invalido" -ForegroundColor Red
    
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    
    if ($statusCode -eq 401) {
        Write-Host "[OK] STATUS: 401 Unauthorized (esperado)" -ForegroundColor Green
        
        try {
            $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
            $errorBody = $streamReader.ReadToEnd() | ConvertFrom-Json
            Write-Host "ERROR RESPONSE:" -ForegroundColor Cyan
            Write-Host ($errorBody | ConvertTo-Json -Depth 10) -ForegroundColor Gray
            $streamReader.Close()
        } catch {
            # Ignore parsing errors
        }
        
        Write-Host ""
        Write-Host "[PASS] TEST 4: Token invalido rechazado (401)" -ForegroundColor Green
        $testsPassed++
        
    } else {
        Write-Host "[FAIL] TEST 4: Status code incorrecto" -ForegroundColor Red
        Write-Host "   Esperado: 401, Recibido: $statusCode" -ForegroundColor Red
    }
}

Write-Host ""

# ==============================================================================
# TEST 5: VERIFICAR ESTRUCTURA DEL JWT (DECODE)
# ==============================================================================

Write-Host "------------------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "TEST 5: VERIFICAR ESTRUCTURA DEL JWT (DECODE)" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------------------------`n" -ForegroundColor Cyan

$totalTests++

Write-Host "Decodificando JWT (sin verificar firma)..." -ForegroundColor Yellow

try {
    $parts = $global:agentToken.Split('.')
    
    if ($parts.Count -eq 3) {
        Write-Host "[OK] JWT tiene 3 partes (header.payload.signature)" -ForegroundColor Green
        
        $payload = $parts[1]
        $padding = (4 - ($payload.Length % 4)) % 4
        $payload += "=" * $padding
        $payload = $payload.Replace('-', '+').Replace('_', '/')
        
        $payloadBytes = [Convert]::FromBase64String($payload)
        $payloadJson = [System.Text.Encoding]::UTF8.GetString($payloadBytes)
        $payloadObj = $payloadJson | ConvertFrom-Json
        
        Write-Host ""
        Write-Host "JWT PAYLOAD:" -ForegroundColor Cyan
        Write-Host ($payloadObj | ConvertTo-Json -Depth 10) -ForegroundColor Gray
        Write-Host ""
        
        $hasId = $null -ne $payloadObj.id
        $hasDeviceId = $null -ne $payloadObj.deviceId
        $hasRole = $payloadObj.role -eq "agent"
        $hasIat = $null -ne $payloadObj.iat
        $hasExp = $null -ne $payloadObj.exp
        
        Write-Host "Verificando campos del payload:" -ForegroundColor Yellow
        if ($hasId) { Write-Host "   [OK] id: $($payloadObj.id)" -ForegroundColor Green } else { Write-Host "   [X] id: missing" -ForegroundColor Red }
        if ($hasDeviceId) { Write-Host "   [OK] deviceId: $($payloadObj.deviceId)" -ForegroundColor Green } else { Write-Host "   [X] deviceId: missing" -ForegroundColor Red }
        if ($hasRole) { Write-Host "   [OK] role: agent" -ForegroundColor Green } else { Write-Host "   [X] role: $($payloadObj.role)" -ForegroundColor Red }
        if ($hasIat) { Write-Host "   [OK] iat (issued at): $($payloadObj.iat)" -ForegroundColor Green } else { Write-Host "   [X] iat: missing" -ForegroundColor Red }
        if ($hasExp) { Write-Host "   [OK] exp (expires): $($payloadObj.exp)" -ForegroundColor Green } else { Write-Host "   [X] exp: missing" -ForegroundColor Red }
        
        if ($hasId -and $hasDeviceId -and $hasRole -and $hasIat -and $hasExp) {
            Write-Host ""
            Write-Host "[PASS] TEST 5: JWT contiene todos los campos requeridos" -ForegroundColor Green
            $testsPassed++
        } else {
            Write-Host ""
            Write-Host "[FAIL] TEST 5: JWT no contiene todos los campos requeridos" -ForegroundColor Red
        }
        
    } else {
        Write-Host "[FAIL] TEST 5: JWT no tiene formato valido" -ForegroundColor Red
        Write-Host "   Partes encontradas: $($parts.Count)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "[FAIL] TEST 5: Error al decodificar JWT" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# ==============================================================================
# RESUMEN DE TESTS
# ==============================================================================

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "RESUMEN DE IT-08" -ForegroundColor Cyan
Write-Host "==============================================================================`n" -ForegroundColor Cyan

Write-Host "Tests ejecutados: $totalTests" -ForegroundColor White
Write-Host "Tests exitosos:   $testsPassed" -ForegroundColor Green
Write-Host "Tests fallidos:   $($totalTests - $testsPassed)" -ForegroundColor $(if ($testsPassed -eq $totalTests) { "Green" } else { "Red" })
Write-Host ""

if ($testsPassed -eq $totalTests) {
    Write-Host "[SUCCESS] IT-08 COMPLETO: Todos los tests de seguridad JWT pasaron" -ForegroundColor Green
    Write-Host ""
    Write-Host "Funcionalidades verificadas:" -ForegroundColor Cyan
    Write-Host "   [+] Backend genera JWT al registrar agente" -ForegroundColor Green
    Write-Host "   [+] JWT contiene informacion del agente (id, deviceId, role)" -ForegroundColor Green
    Write-Host "   [+] Endpoint /assign-task requiere autenticacion" -ForegroundColor Green
    Write-Host "   [+] Token valido permite acceso a endpoint protegido" -ForegroundColor Green
    Write-Host "   [+] Request sin token es rechazado (401)" -ForegroundColor Green
    Write-Host "   [+] Token invalido es rechazado (401)" -ForegroundColor Green
    Write-Host "   [+] JWT tiene estructura correcta con expiracion" -ForegroundColor Green
    Write-Host ""
    exit 0
} else {
    Write-Host "[ERROR] IT-08 FALLO: Algunos tests no pasaron" -ForegroundColor Red
    Write-Host ""
    exit 1
}
