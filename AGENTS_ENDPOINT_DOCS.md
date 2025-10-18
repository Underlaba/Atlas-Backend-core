# ENDPOINT DE AGENTES - IMPLEMENTACIÓN COMPLETA

## ✅ ARCHIVOS CREADOS

### 1. Modelo de Datos
**Archivo:** `src/models/Agent.js`
- ✅ Clase Agent con métodos CRUD
- ✅ `create()` - Crear nuevo agente
- ✅ `findByDeviceId()` - Buscar por device ID
- ✅ `findByWalletAddress()` - Buscar por wallet
- ✅ `findById()` - Buscar por ID
- ✅ `findAll()` - Listar con paginación
- ✅ `updateStatus()` - Actualizar estado
- ✅ `delete()` - Eliminar agente
- ✅ `count()` - Contar total de agentes

### 2. Controlador
**Archivo:** `src/controllers/agentController.js`
- ✅ `register()` - Registro de nuevos agentes
- ✅ `getAll()` - Listar todos los agentes (con paginación)
- ✅ `getById()` - Obtener agente específico
- ✅ `updateStatus()` - Cambiar estado (active/inactive/suspended)
- ✅ `delete()` - Eliminar agente

**Validaciones implementadas:**
- ✅ Device ID requerido y único
- ✅ Wallet address formato: 0x + 40 caracteres hexadecimales
- ✅ Detección de duplicados (device ID y wallet)
- ✅ Estados válidos: active, inactive, suspended

### 3. Rutas
**Archivo:** `src/routes/agents.js`

| Método | Endpoint | Autenticación | Descripción |
|--------|----------|---------------|-------------|
| POST | `/api/v1/agents/register` | ❌ Pública | Registro de agentes |
| GET | `/api/v1/agents` | ✅ JWT | Listar todos los agentes |
| GET | `/api/v1/agents/:id` | ✅ JWT | Obtener agente por ID |
| PUT | `/api/v1/agents/:id/status` | ✅ Admin | Actualizar estado |
| DELETE | `/api/v1/agents/:id` | ✅ Admin | Eliminar agente |

### 4. Validación
**Archivo:** `src/middleware/validation.js`
- ✅ `validateAgentRegistration()` agregado
- ✅ Valida deviceId (string no vacío)
- ✅ Valida walletAddress (formato 0x + 40 hex)

### 5. Base de Datos
**Archivo:** `src/database/migrations/create-agents-table.js`

**Tabla:** `agents`
```sql
CREATE TABLE agents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id VARCHAR(255) NOT NULL UNIQUE,
  wallet_address VARCHAR(42) NOT NULL UNIQUE,
  status VARCHAR(50) DEFAULT 'active' 
    CHECK (status IN ('active', 'inactive', 'suspended')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Índices creados:**
- ✅ `agents_device_id_idx` (UNIQUE)
- ✅ `agents_wallet_address_idx` (UNIQUE)
- ✅ `agents_status_idx`
- ✅ `agents_created_at_idx`

### 6. Actualización de Rutas
**Archivo:** `src/routes/index.js`
- ✅ Importación de `agentRoutes`
- ✅ Montaje en `/agents`

### 7. Script de Pruebas
**Archivo:** `test-agents-api.ps1`
- ✅ Test de registro de agente
- ✅ Test de duplicados
- ✅ Test de validación de wallet
- ✅ Test de autenticación
- ✅ Test de endpoints protegidos

---

## 📋 ESTRUCTURA DE DATOS

### Request: Registro de Agente
```json
POST /api/v1/agents/register
{
  "deviceId": "android-abc123-uuid-xyz789",
  "walletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1"
}
```

### Response: Registro Exitoso (201)
```json
{
  "success": true,
  "message": "Agent registered successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "deviceId": "android-abc123-uuid-xyz789",
    "walletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1",
    "status": "active",
    "createdAt": "2025-10-18T10:30:00.000Z"
  }
}
```

### Response: Error - Dispositivo Duplicado (409)
```json
{
  "success": false,
  "message": "Device already registered",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "deviceId": "android-abc123-uuid-xyz789",
    "walletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1",
    "status": "active",
    "createdAt": "2025-10-18T10:30:00.000Z"
  }
}
```

### Response: Error - Validación (400)
```json
{
  "success": false,
  "message": "Invalid wallet address format. Must start with 0x and be 42 characters long"
}
```

### Response: Listar Agentes (200)
```json
GET /api/v1/agents?limit=10&offset=0
Authorization: Bearer {token}

{
  "success": true,
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "deviceId": "android-abc123-uuid-xyz789",
      "walletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1",
      "status": "active",
      "createdAt": "2025-10-18T10:30:00.000Z",
      "updatedAt": "2025-10-18T10:30:00.000Z"
    }
  ],
  "pagination": {
    "total": 25,
    "limit": 10,
    "offset": 0,
    "hasMore": true
  }
}
```

---

## 🔒 SEGURIDAD IMPLEMENTADA

1. **Validación de Entrada**
   - ✅ Formato de wallet address estricto
   - ✅ Device ID requerido y validado
   - ✅ Prevención de SQL injection (prepared statements)

2. **Control de Duplicados**
   - ✅ Constraint UNIQUE en device_id
   - ✅ Constraint UNIQUE en wallet_address
   - ✅ Verificación en aplicación antes de insertar

3. **Autenticación y Autorización**
   - ✅ Registro público (sin auth)
   - ✅ Listado requiere JWT
   - ✅ Modificación requiere rol admin
   - ✅ Eliminación requiere rol admin

4. **Validación de Estados**
   - ✅ CHECK constraint en base de datos
   - ✅ Validación en controlador
   - ✅ Solo valores permitidos: active, inactive, suspended

---

## 🧪 PRUEBAS NECESARIAS

### Antes de Probar
**IMPORTANTE:** Reiniciar el servidor para cargar las nuevas rutas
```powershell
# En la terminal del servidor:
Ctrl+C
node src/server.js
```

### Ejecutar Pruebas
```powershell
cd d:\Users\alexj\Proyectos\Atlas\backend-core
.\test-agents-api.ps1
```

### Pruebas Manuales con cURL/Postman

**1. Registrar Agente**
```bash
POST http://localhost:3000/api/v1/agents/register
Content-Type: application/json

{
  "deviceId": "test-device-12345",
  "walletAddress": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb1"
}
```

**2. Listar Agentes (requiere login primero)**
```bash
# Login
POST http://localhost:3000/api/v1/auth/login
{
  "email": "admin@atlas.com",
  "password": "Admin123!"
}

# Usar el token recibido
GET http://localhost:3000/api/v1/agents
Authorization: Bearer {access_token}
```

---

## 📊 COMPATIBILIDAD CON ANDROID APP

El endpoint `/api/v1/agents/register` es **100% compatible** con la app Android:

**Android Request (Retrofit):**
```kotlin
data class AgentRegistration(
    val deviceId: String,
    val walletAddress: String
)

interface ApiService {
    @POST("api/v1/agents/register")
    suspend fun registerAgent(
        @Body registration: AgentRegistration
    ): Response<RegistrationResponse>
}
```

**Backend Response:**
```json
{
  "success": true,
  "message": "Agent registered successfully",
  "data": {
    "id": "uuid",
    "deviceId": "...",
    "walletAddress": "0x...",
    "status": "active",
    "createdAt": "timestamp"
  }
}
```

✅ Campos coinciden perfectamente
✅ Formato JSON compatible
✅ Códigos de estado HTTP estándar
✅ Manejo de errores coherente

---

## 🚀 PRÓXIMOS PASOS

1. **Reiniciar servidor backend** ⚠️
2. **Ejecutar test-agents-api.ps1** para verificar
3. **Compilar Android App** y probar integración
4. **Verificar flujo completo** end-to-end

---

## 📝 NOTAS ADICIONALES

- La tabla `agents` usa UUIDs para IDs (más seguro)
- Timestamps automáticos (created_at, updated_at)
- Paginación implementada (default: 100 registros)
- Rate limiting heredado del servidor principal
- Logs automáticos con Morgan

---

**Estado:** ✅ IMPLEMENTACIÓN COMPLETA
**Requiere:** 🔄 Reinicio del servidor
**Próximo Test:** 🧪 Pruebas de integración con Android

---

*Documentación generada el 18/10/2025*
