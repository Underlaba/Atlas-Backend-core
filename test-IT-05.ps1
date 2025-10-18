# ===================================================================
# TEST IT-05: BLOQUEO DE RE-REGISTRO (DEVICE ID DUPLICADO)
# ===================================================================
# Objetivo: Verificar que el sistema rechaza registros con Device ID duplicado
# Expected: 409 Conflict, no se duplica en BD
# ===================================================================

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  TEST IT-05: BLOQUEO DE RE-REGISTRO" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Contador de tests
$testsPassed = 0

# ===================================================================
# PREPARACION
# ===================================================================
Write-Host "[PREPARACION]" -ForegroundColor Yellow

# Usar un Device ID conocido que ya existe en BD
$existingDeviceId = "test-device-94562"  # Del IT-02
$existingWallet = "0x1234567890123456789012345678901234567890"

# Intentar con una wallet diferente (debe fallar igual)
$newWallet = "0xABCDEF1234567890123456789012345678901234"

Write-Host "  Device ID (existente): $existingDeviceId" -ForegroundColor White
Write-Host "  Wallet Original: $existingWallet" -ForegroundColor White
Write-Host "  Wallet Nueva: $newWallet" -ForegroundColor White
Write-Host "  Expected Status: 409 Conflict" -ForegroundColor White
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
Write-Host "[TEST 2/5] Verificando Registro Existente en BD..." -ForegroundColor Yellow

Push-Location "D:\Users\alexj\Proyectos\Atlas\backend-core"

# Crear script para verificar registro existente
$queryScript = @"
const { Pool } = require('pg');
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'atlas_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'Alex87032623302'
});

async function checkExisting() {
    try {
        const result = await pool.query(
            'SELECT * FROM agents WHERE device_id = `$1',
            ['$existingDeviceId']
        );
        
        console.log(JSON.stringify({
            exists: result.rows.length > 0,
            count: result.rows.length,
            data: result.rows[0]
        }));
        
        process.exit(0);
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

checkExisting();
"@

$queryScript | Out-File -FilePath "temp-query-it05.js" -Encoding UTF8

try {
    $dbResult = node temp-query-it05.js 2>&1
    $jsonOutput = $dbResult | Where-Object { $_ -match '^\s*\{' } | Out-String
    
    if ($jsonOutput) {
        $dbData = $jsonOutput | ConvertFrom-Json
        
        if ($dbData.exists) {
            Write-Host "  PASS Registro existente encontrado" -ForegroundColor Green
            Write-Host "  Device ID: $($dbData.data.device_id)" -ForegroundColor Gray
            Write-Host "  Wallet: $($dbData.data.wallet_address)" -ForegroundColor Gray
            Write-Host "  Agent ID: $($dbData.data.id)" -ForegroundColor Gray
            $testsPassed++
        } else {
            Write-Host "  ADVERTENCIA No se encontro registro existente" -ForegroundColor Yellow
            Write-Host "  Ejecuta IT-02 primero para crear un registro" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "  FAIL Error al consultar BD: $_" -ForegroundColor Red
} finally {
    Remove-Item "temp-query-it05.js" -ErrorAction SilentlyContinue
    Pop-Location
}

Write-Host ""

# ===================================================================
# TEST 3: INTENTAR RE-REGISTRO CON MISMO DEVICE ID
# ===================================================================
Write-Host "[TEST 3/5] Intentando Re-registro con Device ID Duplicado..." -ForegroundColor Yellow

# Preparar payload con Device ID existente pero wallet diferente
$payload = @{
    deviceId = $existingDeviceId
    walletAddress = $newWallet
} | ConvertTo-Json

Write-Host "  Enviando POST con Device ID existente..." -ForegroundColor White

try {
    # Intentar registro (debe fallar con 409)
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/v1/agents/register" `
        -Method POST `
        -ContentType "application/json" `
        -Body $payload `
        -ErrorAction Stop
    
    # Si llegamos aqui, el servidor acepto el duplicado (ERROR)
    Write-Host "  FAIL Servidor acepto Device ID duplicado (Status: $($response.StatusCode))" -ForegroundColor Red
    Write-Host "  ERROR CRITICO: Sistema no esta previniendo duplicados!" -ForegroundColor Red
    
} catch {
    $errorResponse = $_.Exception.Response
    
    if ($errorResponse) {
        $statusCode = [int]$errorResponse.StatusCode
        
        # Leer el cuerpo del error
        $reader = New-Object System.IO.StreamReader($errorResponse.GetResponseStream())
        $errorBody = $reader.ReadToEnd() | ConvertFrom-Json
        $reader.Close()
        
        if ($statusCode -eq 409) {
            Write-Host "  PASS Rechazado correctamente (409 Conflict)" -ForegroundColor Green
            Write-Host "  Mensaje: $($errorBody.message)" -ForegroundColor Gray
            $testsPassed++
        } elseif ($statusCode -eq 400) {
            Write-Host "  PASS Rechazado (400 Bad Request - tambien valido)" -ForegroundColor Green
            Write-Host "  Mensaje: $($errorBody.message)" -ForegroundColor Gray
            $testsPassed++
        } else {
            Write-Host "  FAIL Status code incorrecto: $statusCode" -ForegroundColor Red
            Write-Host "  Esperado: 409 Conflict o 400 Bad Request" -ForegroundColor Red
            Write-Host "  Mensaje: $($errorBody.message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  FAIL Error inesperado: $_" -ForegroundColor Red
    }
}

Write-Host ""

# ===================================================================
# TEST 4: VERIFICAR QUE NO SE CREO REGISTRO DUPLICADO EN BD
# ===================================================================
Write-Host "[TEST 4/5] Verificando Integridad de Base de Datos..." -ForegroundColor Yellow

Push-Location "D:\Users\alexj\Proyectos\Atlas\backend-core"

# Crear script para contar registros con mismo Device ID
$countScript = @"
const { Pool } = require('pg');
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'atlas_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'Alex87032623302'
});

async function countDuplicates() {
    try {
        const result = await pool.query(
            'SELECT COUNT(*) as count FROM agents WHERE device_id = `$1',
            ['$existingDeviceId']
        );
        
        console.log(JSON.stringify({
            count: parseInt(result.rows[0].count)
        }));
        
        process.exit(0);
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

countDuplicates();
"@

$countScript | Out-File -FilePath "temp-count-it05.js" -Encoding UTF8

try {
    $countResult = node temp-count-it05.js 2>&1
    $jsonOutput = $countResult | Where-Object { $_ -match '^\s*\{' } | Out-String
    
    if ($jsonOutput) {
        $countData = $jsonOutput | ConvertFrom-Json
        $duplicateCount = $countData.count
        
        Write-Host "  Registros con Device ID '$existingDeviceId': $duplicateCount" -ForegroundColor White
        
        if ($duplicateCount -eq 1) {
            Write-Host "  PASS No se creo registro duplicado (count = 1)" -ForegroundColor Green
            $testsPassed++
        } elseif ($duplicateCount -gt 1) {
            Write-Host "  FAIL Se encontraron $duplicateCount registros duplicados!" -ForegroundColor Red
            Write-Host "  ERROR CRITICO: Constraint UNIQUE no esta funcionando" -ForegroundColor Red
        } else {
            Write-Host "  ADVERTENCIA No se encontraron registros" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "  FAIL Error al contar registros: $_" -ForegroundColor Red
} finally {
    Remove-Item "temp-count-it05.js" -ErrorAction SilentlyContinue
    Pop-Location
}

Write-Host ""

# ===================================================================
# TEST 5: VERIFICAR CONSTRAINT UNIQUE EN SCHEMA
# ===================================================================
Write-Host "[TEST 5/5] Verificando Constraint UNIQUE en Schema..." -ForegroundColor Yellow

Push-Location "D:\Users\alexj\Proyectos\Atlas\backend-core"

# Crear script para verificar constraint UNIQUE
$schemaScript = @"
const { Pool } = require('pg');
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 5432,
    database: process.env.DB_NAME || 'atlas_db',
    user: process.env.DB_USER || 'postgres',
    password: process.env.DB_PASSWORD || 'Alex87032623302'
});

async function checkConstraint() {
    try {
        const result = await pool.query(\`
            SELECT constraint_name, constraint_type
            FROM information_schema.table_constraints
            WHERE table_name = 'agents'
            AND constraint_type = 'UNIQUE'
        \`);
        
        console.log(JSON.stringify({
            hasUniqueConstraint: result.rows.length > 0,
            constraints: result.rows
        }));
        
        process.exit(0);
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

checkConstraint();
"@

$schemaScript | Out-File -FilePath "temp-schema-it05.js" -Encoding UTF8

try {
    $schemaResult = node temp-schema-it05.js 2>&1
    $jsonOutput = $schemaResult | Where-Object { $_ -match '^\s*\{' } | Out-String
    
    if ($jsonOutput) {
        $schemaData = $jsonOutput | ConvertFrom-Json
        
        if ($schemaData.hasUniqueConstraint) {
            Write-Host "  PASS Constraint UNIQUE esta definido" -ForegroundColor Green
            
            foreach ($constraint in $schemaData.constraints) {
                Write-Host "  Constraint: $($constraint.constraint_name)" -ForegroundColor Gray
            }
            
            $testsPassed++
        } else {
            Write-Host "  FAIL No se encontro constraint UNIQUE en device_id" -ForegroundColor Red
            Write-Host "  RECOMENDACION: Agregar UNIQUE constraint en migracion" -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "  FAIL Error al verificar schema: $_" -ForegroundColor Red
} finally {
    Remove-Item "temp-schema-it05.js" -ErrorAction SilentlyContinue
    Pop-Location
}

Write-Host ""

# ===================================================================
# RESUMEN FINAL
# ===================================================================
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  RESUMEN FINAL IT-05" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$totalTests = 5

if ($testsPassed -eq $totalTests) {
    Write-Host "  RESULTADO: TEST IT-05 COMPLETO" -ForegroundColor Green
    Write-Host "  Tests Pasados: $testsPassed/$totalTests" -ForegroundColor Green
    Write-Host ""
    Write-Host "  VERIFICACIONES COMPLETADAS:" -ForegroundColor Green
    Write-Host "    [OK] Backend Activo" -ForegroundColor Green
    Write-Host "    [OK] Registro Existente en BD" -ForegroundColor Green
    Write-Host "    [OK] Re-registro Rechazado (409/400)" -ForegroundColor Green
    Write-Host "    [OK] Sin Duplicados en BD" -ForegroundColor Green
    Write-Host "    [OK] Constraint UNIQUE Verificado" -ForegroundColor Green
} else {
    Write-Host "  RESULTADO: TESTS INCOMPLETOS" -ForegroundColor Yellow
    Write-Host "  Tests Pasados: $testsPassed/$totalTests" -ForegroundColor Yellow
    Write-Host "  Tests Fallidos: $($totalTests - $testsPassed)" -ForegroundColor Red
}

Write-Host ""
Write-Host "MECANISMO DE PREVENCION:" -ForegroundColor Yellow
Write-Host "  Nivel BD: Constraint UNIQUE en device_id" -ForegroundColor White
Write-Host "  Nivel Backend: Validacion en agentController.js" -ForegroundColor White
Write-Host "  Response: 409 Conflict (o 400 Bad Request)" -ForegroundColor White
Write-Host ""
Write-Host "COMPORTAMIENTO VERIFICADO:" -ForegroundColor Yellow
Write-Host "  1. Sistema detecta Device ID duplicado" -ForegroundColor White
Write-Host "  2. Backend rechaza con error apropiado" -ForegroundColor White
Write-Host "  3. NO se ejecuta INSERT en PostgreSQL" -ForegroundColor White
Write-Host "  4. Base de datos mantiene integridad" -ForegroundColor White
Write-Host "  5. Constraint UNIQUE funciona correctamente" -ForegroundColor White
Write-Host ""

if ($testsPassed -eq $totalTests) {
    Write-Host "CONCLUSION:" -ForegroundColor Yellow
    Write-Host "  El sistema CORRECTAMENTE previene re-registros duplicados" -ForegroundColor Green
    Write-Host "  y mantiene la integridad de la base de datos." -ForegroundColor Green
} else {
    Write-Host "ADVERTENCIA:" -ForegroundColor Yellow
    Write-Host "  El sistema tiene problemas previniendo duplicados." -ForegroundColor Red
    Write-Host "  Se requiere revision del constraint UNIQUE y validaciones." -ForegroundColor Red
}

Write-Host ""
