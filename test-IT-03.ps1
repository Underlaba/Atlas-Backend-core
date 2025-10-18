# ===================================================================
# TEST IT-03: REGISTRO DE AGENTE (INVALIDO - WALLET INVALIDA)
# ===================================================================
# Objetivo: Verificar que el sistema rechaza registros con wallet invalida
# Expected: 400 Bad Request, no se inserta en BD
# ===================================================================

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  TEST IT-03: WALLET ADDRESS INVALIDA" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Contador de tests
$testsPassed = 0

# ===================================================================
# PREPARACION
# ===================================================================
Write-Host "[PREPARACION]" -ForegroundColor Yellow

# Generar Device ID unico para este test
$randomId = Get-Random -Minimum 10000 -Maximum 99999
$deviceId = "test-device-$randomId"

# Wallets invalidas para probar
$invalidWallets = @(
    @{wallet = "12345"; description = "Solo numeros"},
    @{wallet = "0x123"; description = "Muy corta (0x + 3 chars)"},
    @{wallet = "1234567890123456789012345678901234567890"; description = "Sin prefijo 0x"},
    @{wallet = "0xGGGG567890123456789012345678901234567890"; description = "Caracteres no-hex"},
    @{wallet = ""; description = "Vacia"},
    @{wallet = "0x12345678901234567890123456789012345678901"; description = "Muy larga (41 chars)"}
)

Write-Host "  Device ID: $deviceId" -ForegroundColor White
Write-Host "  Tests de Wallet: $($invalidWallets.Count) casos invalidos" -ForegroundColor White
Write-Host "  Expected Status: 400 Bad Request" -ForegroundColor White
Write-Host ""

# ===================================================================
# TEST 1: VERIFICAR BACKEND ACTIVO
# ===================================================================
Write-Host "[TEST 1/$($invalidWallets.Count + 2)] Verificando Backend..." -ForegroundColor Yellow

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
# TEST 2-N: PROBAR CADA WALLET INVALIDA
# ===================================================================
$testNumber = 2
$rejectedCount = 0

foreach ($testCase in $invalidWallets) {
    Write-Host "[TEST $testNumber/$($invalidWallets.Count + 2)] Probando: $($testCase.description)" -ForegroundColor Yellow
    Write-Host "  Wallet: '$($testCase.wallet)'" -ForegroundColor Gray
    
    # Preparar payload
    $payload = @{
        deviceId = "$deviceId-$testNumber"
        walletAddress = $testCase.wallet
    } | ConvertTo-Json
    
    try {
        # Intentar registro (debe fallar)
        $response = Invoke-WebRequest -Uri "http://localhost:3000/api/v1/agents/register" `
            -Method POST `
            -ContentType "application/json" `
            -Body $payload `
            -ErrorAction Stop
        
        # Si llegamos aqui, el servidor acepto la wallet invalida (ERROR)
        Write-Host "  FAIL Servidor acepto wallet invalida (Status: $($response.StatusCode))" -ForegroundColor Red
        Write-Host "  Respuesta: $($response.Content)" -ForegroundColor Red
        
    } catch {
        $errorResponse = $_.Exception.Response
        
        if ($errorResponse) {
            $statusCode = [int]$errorResponse.StatusCode
            
            # Leer el cuerpo del error
            $reader = New-Object System.IO.StreamReader($errorResponse.GetResponseStream())
            $errorBody = $reader.ReadToEnd() | ConvertFrom-Json
            $reader.Close()
            
            if ($statusCode -eq 400) {
                Write-Host "  PASS Rechazado correctamente (400 Bad Request)" -ForegroundColor Green
                Write-Host "  Mensaje: $($errorBody.message)" -ForegroundColor Gray
                $rejectedCount++
                $testsPassed++
            } else {
                Write-Host "  FAIL Status code incorrecto: $statusCode (esperado: 400)" -ForegroundColor Red
                Write-Host "  Mensaje: $($errorBody.message)" -ForegroundColor Red
            }
        } else {
            Write-Host "  FAIL Error inesperado: $_" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    $testNumber++
}

# ===================================================================
# TEST FINAL: VERIFICAR QUE NO SE INSERTO EN BASE DE DATOS
# ===================================================================
Write-Host "[TEST $testNumber/$($invalidWallets.Count + 2)] Verificando Base de Datos..." -ForegroundColor Yellow
Write-Host "  Confirmando que NO se insertaron registros invalidos..." -ForegroundColor White

Push-Location "D:\Users\alexj\Proyectos\Atlas\backend-core"

# Crear script para verificar BD
$queryScript = @"
const { Pool } = require('pg');
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'atlas_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'Alex87032623302'
});

async function checkInvalidEntries() {
    try {
        const result = await pool.query(
            \"SELECT * FROM agents WHERE device_id LIKE '`$1%' ORDER BY created_at DESC\",
            ['$deviceId']
        );
        
        console.log(JSON.stringify({
            count: result.rows.length,
            rows: result.rows
        }));
        
        process.exit(0);
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

checkInvalidEntries();
"@

$queryScript | Out-File -FilePath "temp-query-it03.js" -Encoding UTF8

try {
    $dbResult = node temp-query-it03.js 2>&1
    
    # Filtrar solo la salida JSON (ignorar warnings de Node)
    $jsonOutput = $dbResult | Where-Object { $_ -match '^\s*\{' } | Out-String
    
    if ($jsonOutput) {
        $dbData = $jsonOutput | ConvertFrom-Json
    } else {
        throw "No se recibio respuesta JSON valida"
    }
    
    if ($dbData.count -eq 0) {
        Write-Host "  PASS No se insertaron registros invalidos en BD" -ForegroundColor Green
        Write-Host "  Registros encontrados: 0 (correcto)" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "  FAIL Se encontraron $($dbData.count) registros invalidos en BD" -ForegroundColor Red
        Write-Host "  ADVERTENCIA: El sistema esta aceptando datos invalidos!" -ForegroundColor Red
        
        foreach ($row in $dbData.rows) {
            Write-Host "  - Device: $($row.device_id), Wallet: $($row.wallet_address)" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "  FAIL Error al consultar base de datos" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
} finally {
    Remove-Item "temp-query-it03.js" -ErrorAction SilentlyContinue
    Pop-Location
}

Write-Host ""

# ===================================================================
# RESUMEN FINAL
# ===================================================================
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  RESUMEN FINAL IT-03" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$totalTests = $invalidWallets.Count + 2
$expectedPassed = $totalTests

if ($testsPassed -eq $expectedPassed) {
    Write-Host "  RESULTADO: TEST IT-03 COMPLETO" -ForegroundColor Green
    Write-Host "  Tests Pasados: $testsPassed/$totalTests" -ForegroundColor Green
    Write-Host ""
    Write-Host "  VERIFICACIONES COMPLETADAS:" -ForegroundColor Green
    Write-Host "    [OK] Backend Activo" -ForegroundColor Green
    Write-Host "    [OK] Wallets Invalidas Rechazadas ($rejectedCount/$($invalidWallets.Count))" -ForegroundColor Green
    Write-Host "    [OK] Base de Datos Sin Registros Invalidos" -ForegroundColor Green
    Write-Host ""
    Write-Host "  VALIDACIONES DE WALLET VERIFICADAS:" -ForegroundColor Green
    foreach ($testCase in $invalidWallets) {
        Write-Host "    [OK] $($testCase.description)" -ForegroundColor Green
    }
} else {
    Write-Host "  RESULTADO: TESTS INCOMPLETOS" -ForegroundColor Yellow
    Write-Host "  Tests Pasados: $testsPassed/$totalTests" -ForegroundColor Yellow
    Write-Host "  Tests Fallidos: $($totalTests - $testsPassed)" -ForegroundColor Red
    Write-Host ""
    Write-Host "  VALIDACIONES RECHAZADAS: $rejectedCount/$($invalidWallets.Count)" -ForegroundColor $(if($rejectedCount -eq $invalidWallets.Count){"Green"}else{"Red"})
}

Write-Host ""
Write-Host "CONCLUSION:" -ForegroundColor Yellow
if ($testsPassed -eq $expectedPassed) {
    Write-Host "  El sistema CORRECTAMENTE rechaza wallets invalidas" -ForegroundColor Green
    Write-Host "  y previene la insercion de datos incorrectos en la BD." -ForegroundColor Green
} else {
    Write-Host "  El sistema tiene problemas con la validacion de wallets." -ForegroundColor Red
    Write-Host "  Se requiere revision del codigo de validacion." -ForegroundColor Red
}
Write-Host ""
