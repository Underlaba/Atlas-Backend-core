# TEST IT-05 - BLOQUEO DE RE-REGISTRO (DEVICE ID DUPLICADO)
## ATLAS - Duplicate Prevention Integration Test

**Fecha de Ejecución:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Ejecutado por:** Sistema de Testing Automatizado  
**Servidor:** http://localhost:3000

---

## OBJETIVO DEL TEST
Verificar que el sistema **rechaza correctamente** los intentos de re-registro con el mismo Device ID, retornando error 409 Conflict y **sin crear** registros duplicados en la base de datos PostgreSQL.

## MECANISMOS DE PREVENCIÓN

### Nivel 1: Base de Datos
```sql
-- Constraint UNIQUE en device_id
ALTER TABLE agents 
ADD CONSTRAINT agents_device_id_key UNIQUE (device_id);
```

### Nivel 2: Backend
```javascript
// agentController.js - Validación antes de INSERT
const existing = await Agent.findByDeviceId(deviceId);
if (existing) {
    return res.status(409).json({
        success: false,
        message: 'Agent with this deviceId already exists'
    });
}
```

---

## DATOS DE PRUEBA

**Registro Existente (IT-02):**
- Device ID: `test-device-94562`
- Wallet Original: `0x1234567890123456789012345678901234567890`
- Agent ID: `0d1fab1a-fd49-4acb-839b-7ea4dd5b71b7`
- Created: `2025-10-18 23:42:53`

**Intento de Re-registro:**
- Device ID: `test-device-94562` (MISMO)
- Wallet Nueva: `0xABCDEF1234567890123456789012345678901234` (DIFERENTE)
- Expected Response: `409 Conflict`

**Nota:** Aunque la wallet sea diferente, el Device ID es la clave única.

---

## RESULTADOS DE EJECUCIÓN

### ✅ TEST 1: BACKEND ACTIVO
- **Resultado:** PASS
- **Endpoint:** GET /api/v1/health
- **Respuesta:** Backend está operativo

### ✅ TEST 2: VERIFICAR REGISTRO EXISTENTE
- **Resultado:** PASS
- **Query:** `SELECT * FROM agents WHERE device_id = 'test-device-94562'`
- **Encontrado:** ✅ Sí

**Datos del Registro Existente:**
```json
{
  "id": "0d1fab1a-fd49-4acb-839b-7ea4dd5b71b7",
  "device_id": "test-device-94562",
  "wallet_address": "0x1234567890123456789012345678901234567890",
  "created_at": "2025-10-18T20:42:53.457Z"
}
```

### ✅ TEST 3: INTENTAR RE-REGISTRO
- **Resultado:** PASS - Rechazado correctamente
- **Método:** POST /api/v1/agents/register
- **Payload:**
  ```json
  {
    "deviceId": "test-device-94562",
    "walletAddress": "0xABCDEF1234567890123456789012345678901234"
  }
  ```
- **Status Code:** 409 Conflict ✅
- **Comportamiento:** Sistema detectó Device ID duplicado

### ✅ TEST 4: VERIFICAR INTEGRIDAD DE BD
- **Resultado:** PASS
- **Query:** `SELECT COUNT(*) FROM agents WHERE device_id = 'test-device-94562'`
- **Count:** 1 (correcto)
- **Conclusión:** NO se creó registro duplicado

### ✅ TEST 5: VERIFICAR CONSTRAINT UNIQUE
- **Resultado:** PASS (verificación manual exitosa)
- **Query:** 
  ```sql
  SELECT constraint_name, constraint_type, column_name
  FROM information_schema.table_constraints tc
  LEFT JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
  WHERE tc.table_name = 'agents'
  ```

**Constraints Encontrados:**
| Tipo | Nombre | Columna |
|------|--------|---------|
| PRIMARY KEY | agents_pkey | id |
| UNIQUE | agents_device_id_key | device_id ✅ |
| UNIQUE | agents_wallet_address_key | wallet_address |
| CHECK | agents_device_id_not_null | - |
| CHECK | agents_wallet_address_not_null | - |
| CHECK | agents_status_check | - |

**Confirmación:** ✅ Constraint UNIQUE en `device_id` está activo

---

## COMPORTAMIENTO DEL SISTEMA

### Flujo de Prevención de Duplicados:

```
┌─────────────────────────────────────────┐
│   INTENTO DE RE-REGISTRO                │
├─────────────────────────────────────────┤
│ 1. POST con deviceId existente          │
│ 2. Backend recibe request               │
│ 3. agentController.register() ejecuta   │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│   VALIDACIÓN EN BACKEND                 │
├─────────────────────────────────────────┤
│ 4. Agent.findByDeviceId(deviceId)       │
│ 5. Result: Agente existente encontrado  │
│ 6. if (existing) → true                 │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│   RECHAZO DE REQUEST                    │
├─────────────────────────────────────────┤
│ 7. return 409 Conflict                  │
│ 8. Message: "deviceId already exists"   │
│ 9. NO se ejecuta INSERT                 │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│   CONSTRAINT UNIQUE (Backup)            │
├─────────────────────────────────────────┤
│ Si validación fallara:                  │
│ → PostgreSQL rechaza INSERT             │
│ → Error: duplicate key value            │
│ → Integridad garantizada a nivel BD     │
└─────────────────────────────────────────┘
```

### Doble Capa de Protección:

**Capa 1: Backend (Aplicación)**
- Validación explícita antes de INSERT
- Response 409 Conflict con mensaje claro
- Evita carga innecesaria en BD

**Capa 2: Base de Datos (Constraint)**
- UNIQUE constraint en `device_id`
- Garantía de integridad a nivel BD
- Protección contra bypass de validación

---

## EVIDENCIA DE PRUEBAS

### Request de Re-registro:
```http
POST http://localhost:3000/api/v1/agents/register
Content-Type: application/json

{
  "deviceId": "test-device-94562",
  "walletAddress": "0xABCDEF1234567890123456789012345678901234"
}
```

### Response del Backend:
```http
HTTP/1.1 409 Conflict
Content-Type: application/json

{
  "success": false,
  "message": "Agent with this deviceId already exists"
}
```

### Estado de Base de Datos:
```sql
-- ANTES del intento
SELECT COUNT(*) FROM agents WHERE device_id = 'test-device-94562';
-- Result: 1

-- DESPUÉS del intento (rechazado)
SELECT COUNT(*) FROM agents WHERE device_id = 'test-device-94562';
-- Result: 1 (sin cambios)
```

**Confirmación:** ✅ Ningún registro duplicado fue insertado

### Constraints Verificados:
```sql
SELECT constraint_name, constraint_type 
FROM information_schema.table_constraints
WHERE table_name = 'agents' AND constraint_type = 'UNIQUE';

-- Results:
-- agents_device_id_key | UNIQUE
-- agents_wallet_address_key | UNIQUE
```

---

## COBERTURA DE TESTING

### Escenarios Probados:

1. ✅ **Device ID Duplicado con Wallet Diferente**
   - Sistema rechaza basándose en Device ID
   - Wallet address no es considerada

2. ✅ **Validación en Backend**
   - findByDeviceId() funciona correctamente
   - Response 409 apropiada

3. ✅ **Integridad de BD**
   - No se crearon duplicados
   - Count permanece en 1

4. ✅ **Constraint UNIQUE**
   - Definido correctamente en schema
   - Activo y funcional

### Casos NO Probados (Futuros Tests):

- [ ] Device ID Diferente con Wallet Duplicada
- [ ] Múltiples intentos simultáneos (race condition)
- [ ] Re-registro tras eliminar agente
- [ ] Case sensitivity en Device ID

---

## CONCLUSIONES

### ✅ FUNCIONALIDADES VERIFICADAS:

1. **Detección de Duplicados:** Funcionando perfectamente
2. **Response 409 Conflict:** Código HTTP apropiado
3. **Prevención de INSERT:** Sistema no permite duplicados
4. **Integridad de BD:** Base de datos mantiene consistencia
5. **Constraint UNIQUE:** Activo y verificado en schema

### 📊 ESTADO DE PREVENCIÓN:

| Mecanismo | Status | Efectividad |
|-----------|--------|-------------|
| Backend Validation | ✅ Activo | 100% |
| Response 409 | ✅ Correcto | 100% |
| UNIQUE Constraint | ✅ Activo | 100% |
| DB Integrity | ✅ Verificada | 100% |
| Error Message | ✅ Claro | 100% |

### 🎯 COMPARACIÓN CON OTROS TESTS:

| Test | Aspecto | IT-02 | IT-03 | IT-04 | IT-05 |
|------|---------|-------|-------|-------|-------|
| Registro Válido | ✅ | ✅ | - | - | - |
| Validación Input | - | - | ✅ | - | - |
| Persistencia | - | - | - | ✅ | - |
| Prevención Duplicados | - | - | - | - | ✅ |
| HTTP Status | 201 | 400 | - | 409 |
| BD Insert | ✅ | ❌ | - | ❌ |

---

## RECOMENDACIONES

### Mejoras Implementadas: ✅
- ✅ UNIQUE constraint en `device_id`
- ✅ Validación explícita en backend
- ✅ Response code 409 apropiado
- ✅ Mensaje de error descriptivo

### Mejoras Futuras Sugeridas:

1. **Logging de Intentos Duplicados:**
   ```javascript
   logger.warn('Duplicate registration attempt', {
       deviceId,
       timestamp: new Date(),
       ip: req.ip
   });
   ```

2. **Mensaje de Error Más Descriptivo:**
   ```json
   {
     "success": false,
     "error": "DUPLICATE_DEVICE_ID",
     "message": "This device is already registered",
     "deviceId": "test-device-94562",
     "registeredAt": "2025-10-18T20:42:53.457Z"
   }
   ```

3. **Rate Limiting:**
   - Limitar intentos de registro por IP
   - Prevenir ataques de fuerza bruta

4. **UI Feedback:**
   - Detectar 409 en app Android
   - Mostrar mensaje: "Device already registered"
   - Opción de recuperar datos existentes

### Testing Adicional Recomendado:

- [ ] Test de wallet address duplicada
- [ ] Test de race conditions (registros simultáneos)
- [ ] Test de re-registro tras soft delete
- [ ] Performance test con muchos intentos

---

## FIRMA DEL TEST

**Status:** ✅ APROBADO  
**Tests Pasados:** 5/5  
**Duplicados en BD:** 0  
**Constraint Verificado:** ✅ Activo  
**Fecha:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  

**Sistema Testeado:**
- Frontend: Android App (Kotlin + Retrofit)
- Backend: Node.js + Express (src/server.js)
- Base de Datos: PostgreSQL (atlas_db)
- Endpoint: POST /api/v1/agents/register

**Prevención de Duplicados Confirmada:**
El sistema **correctamente rechaza** re-registros con Device ID duplicado, utilizando doble capa de protección (backend + constraint BD) y manteniendo la integridad de los datos.

---

*Este test confirma que el sistema de prevención de duplicados está funcionando correctamente y protege la integridad de la base de datos.*
