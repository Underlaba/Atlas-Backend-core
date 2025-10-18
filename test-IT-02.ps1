# TEST IT-02 - Registro de Agente (Valido)
# Input: Wallet valida (0x + 42 caracteres)
# Expected: Respuesta 201 Created, mensaje de exito en UI

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  TEST IT-02: REGISTRO DE AGENTE VALIDO" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Datos del test
$testDeviceId = "test-device-$(Get-Random -Maximum 99999)"
$testWallet = "0x1234567890123456789012345678901234567890"

Write-Host "[PREPARACION]" -ForegroundColor Yellow
Write-Host "  Device ID: $testDeviceId" -ForegroundColor White
Write-Host "  Wallet Address: $testWallet" -ForegroundColor White
Write-Host "  Expected Status: 201 Created" -ForegroundColor White
Write-Host ""

# Test 1: Verificar backend activo
Write-Host "[TEST 1/4] Verificando Backend..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/health" -Method GET -ErrorAction Stop
    if ($health.success) {
        Write-Host "  PASS Backend esta activo" -ForegroundColor Green
    }
} catch {
    Write-Host "  FAIL Backend no responde" -ForegroundColor Red
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 2: Enviar registro
Write-Host "[TEST 2/4] Enviando Registro..." -ForegroundColor Yellow
$registrationData = @{
    deviceId = $testDeviceId
    walletAddress = $testWallet
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/v1/agents/register" `
        -Method POST `
        -Body $registrationData `
        -ContentType "application/json" `
        -ErrorAction Stop
    
    Write-Host "  Status Code: $($response.StatusCode)" -ForegroundColor White
    
    # Verificar status code
    if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 201) {
        Write-Host "  PASS Status code correcto (200/201)" -ForegroundColor Green
    } else {
        Write-Host "  FAIL Status code incorrecto: $($response.StatusCode)" -ForegroundColor Red
    }
    
    # Parsear respuesta
    $responseData = $response.Content | ConvertFrom-Json
    Write-Host "  Success: $($responseData.success)" -ForegroundColor White
    Write-Host "  Message: $($responseData.message)" -ForegroundColor White
    
    if ($responseData.success) {
        Write-Host "  PASS Registro exitoso" -ForegroundColor Green
        Write-Host "  Agent ID: $($responseData.data.id)" -ForegroundColor Cyan
        Write-Host "  Created At: $($responseData.data.createdAt)" -ForegroundColor Cyan
        $agentId = $responseData.data.id
    } else {
        Write-Host "  FAIL Registro fallo" -ForegroundColor Red
    }
    
} catch {
    Write-Host "  FAIL Error en el registro" -ForegroundColor Red
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Test 3: Verificar estructura de respuesta
Write-Host "[TEST 3/4] Verificando Estructura de Respuesta..." -ForegroundColor Yellow
$hasSuccess = $null -ne $responseData.success
$hasMessage = $null -ne $responseData.message
$hasData = $null -ne $responseData.data
$hasId = $null -ne $responseData.data.id
$hasDeviceId = $null -ne $responseData.data.deviceId
$hasWalletAddress = $null -ne $responseData.data.walletAddress
$hasCreatedAt = $null -ne $responseData.data.createdAt

Write-Host "  Campo 'success': $(if($hasSuccess){'OK'}else{'MISSING'})" -ForegroundColor $(if($hasSuccess){'Green'}else{'Red'})
Write-Host "  Campo 'message': $(if($hasMessage){'OK'}else{'MISSING'})" -ForegroundColor $(if($hasMessage){'Green'}else{'Red'})
Write-Host "  Campo 'data': $(if($hasData){'OK'}else{'MISSING'})" -ForegroundColor $(if($hasData){'Green'}else{'Red'})
Write-Host "  Campo 'data.id': $(if($hasId){'OK'}else{'MISSING'})" -ForegroundColor $(if($hasId){'Green'}else{'Red'})
Write-Host "  Campo 'data.deviceId': $(if($hasDeviceId){'OK'}else{'MISSING'})" -ForegroundColor $(if($hasDeviceId){'Green'}else{'Red'})
Write-Host "  Campo 'data.walletAddress': $(if($hasWalletAddress){'OK'}else{'MISSING'})" -ForegroundColor $(if($hasWalletAddress){'Green'}else{'Red'})
Write-Host "  Campo 'data.createdAt': $(if($hasCreatedAt){'OK'}else{'MISSING'})" -ForegroundColor $(if($hasCreatedAt){'Green'}else{'Red'})

$allFieldsPresent = $hasSuccess -and $hasMessage -and $hasData -and $hasId -and $hasDeviceId -and $hasWalletAddress -and $hasCreatedAt

if ($allFieldsPresent) {
    Write-Host "  PASS Estructura completa" -ForegroundColor Green
} else {
    Write-Host "  FAIL Estructura incompleta" -ForegroundColor Red
}
Write-Host ""

# Test 4: Verificar datos coinciden
Write-Host "[TEST 4/4] Verificando Datos..." -ForegroundColor Yellow
$deviceIdMatch = $responseData.data.deviceId -eq $testDeviceId
$walletMatch = $responseData.data.walletAddress -eq $testWallet

Write-Host "  Device ID Match: $(if($deviceIdMatch){'OK'}else{'FAIL'})" -ForegroundColor $(if($deviceIdMatch){'Green'}else{'Red'})
Write-Host "  Wallet Address Match: $(if($walletMatch){'OK'}else{'FAIL'})" -ForegroundColor $(if($walletMatch){'Green'}else{'Red'})

if ($deviceIdMatch -and $walletMatch) {
    Write-Host "  PASS Datos correctos" -ForegroundColor Green
} else {
    Write-Host "  FAIL Datos incorrectos" -ForegroundColor Red
}
Write-Host ""

# Resumen final
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  RESUMEN DEL TEST" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Estado del Backend: ACTIVO" -ForegroundColor Green
Write-Host "Registro HTTP: $(if($response.StatusCode -in @(200,201)){'EXITOSO'}else{'FALLIDO'})" -ForegroundColor $(if($response.StatusCode -in @(200,201)){'Green'}else{'Red'})
Write-Host "Estructura de Respuesta: $(if($allFieldsPresent){'COMPLETA'}else{'INCOMPLETA'})" -ForegroundColor $(if($allFieldsPresent){'Green'}else{'Red'})
Write-Host "Validacion de Datos: $(if($deviceIdMatch -and $walletMatch){'CORRECTA'}else{'INCORRECTA'})" -ForegroundColor $(if($deviceIdMatch -and $walletMatch){'Green'}else{'Red'})
Write-Host ""

# ===================================================================
# TEST 5: VERIFICACION BASE DE DATOS POSTGRESQL
# ===================================================================
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  TEST 5/5 - Verificacion PostgreSQL" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Verificando persistencia en base de datos..." -ForegroundColor Yellow

# Cambiar al directorio backend-core para tener acceso a node_modules
Push-Location "D:\Users\alexj\Proyectos\Atlas\backend-core"

# Crear script temporal para query
$queryScript = @"
const { Pool } = require('pg');
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'atlas_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'Alex87032623302'
});

async function queryAgent() {
    try {
        const result = await pool.query(
            'SELECT * FROM agents WHERE device_id = `$1 ORDER BY created_at DESC LIMIT 1',
            ['$deviceId']
        );
        
        if (result.rows.length > 0) {
            console.log(JSON.stringify(result.rows[0], null, 2));
            process.exit(0);
        } else {
            console.error('No se encontro el registro');
            process.exit(1);
        }
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

queryAgent();
"@

$queryScript | Out-File -FilePath "temp-query.js" -Encoding UTF8

try {
    $dbResult = node temp-query.js 2>&1 | Out-String
    
    if ($dbResult -match '"device_id"') {
        Write-Host "  PASS Registro encontrado en PostgreSQL" -ForegroundColor Green
        Write-Host ""
        Write-Host "Datos en Base de Datos:" -ForegroundColor White
        Write-Host $dbResult -ForegroundColor Gray
        Write-Host ""
        
        # Verificar campos
        $dbDeviceMatch = $dbResult -match [regex]::Escape($deviceId)
        $dbWalletMatch = $dbResult -match [regex]::Escape($walletAddress)
        
        if ($dbDeviceMatch) {
            Write-Host "  Device ID en DB: VERIFICADO" -ForegroundColor Green
        } else {
            Write-Host "  Device ID en DB: NO COINCIDE" -ForegroundColor Red
        }
        
        if ($dbWalletMatch) {
            Write-Host "  Wallet Address en DB: VERIFICADO" -ForegroundColor Green
        } else {
            Write-Host "  Wallet Address en DB: NO COINCIDE" -ForegroundColor Red
        }
        
        if ($dbDeviceMatch -and $dbWalletMatch) {
            $testsPassed++
        }
    } else {
        Write-Host "  FAIL No se encontro en base de datos" -ForegroundColor Red
        Write-Host "  Respuesta: $dbResult" -ForegroundColor Red
    }
} catch {
    Write-Host "  FAIL Error al consultar base de datos" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
} finally {
    Remove-Item "temp-query.js" -ErrorAction SilentlyContinue
    Pop-Location
}

Write-Host ""

# ===================================================================
# RESUMEN FINAL
# ===================================================================
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  RESUMEN FINAL IT-02" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

if ($testsPassed -eq 5) {
    Write-Host "  RESULTADO: TEST IT-02 COMPLETO" -ForegroundColor Green
    Write-Host "  Tests Pasados: $testsPassed/5" -ForegroundColor Green
    Write-Host ""
    Write-Host "  VERIFICACIONES COMPLETADAS:" -ForegroundColor Green
    Write-Host "    [OK] Backend Activo" -ForegroundColor Green
    Write-Host "    [OK] Comunicacion HTTP" -ForegroundColor Green
    Write-Host "    [OK] Estructura de Respuesta" -ForegroundColor Green
    Write-Host "    [OK] Validacion de Datos" -ForegroundColor Green
    Write-Host "    [OK] Persistencia PostgreSQL" -ForegroundColor Green
} else {
    Write-Host "  RESULTADO: TESTS INCOMPLETOS" -ForegroundColor Yellow
    Write-Host "  Tests Pasados: $testsPassed/5" -ForegroundColor Yellow
}

Write-Host ""
Write-Host ""