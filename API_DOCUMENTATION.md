# 📚 Atlas Backend API - Documentación

## 🌐 Acceso a la Documentación

### Documentación Interactiva (Swagger UI)

**Desarrollo:**
```
http://localhost:3000/api-docs
```

**Producción:**
```
http://54.176.126.78/api-docs
```

La documentación interactiva permite:
- ✅ Ver todos los endpoints disponibles
- ✅ Probar requests directamente desde el navegador
- ✅ Ver ejemplos de requests y responses
- ✅ Descargar la especificación OpenAPI

---

## 🔐 Autenticación

La API utiliza **JWT (JSON Web Tokens)** para autenticación.

### Obtener un Token

**Endpoint:** `POST /api/v1/auth/login`

**Request:**
```json
{
  "email": "admin@atlas.com",
  "password": "SecurePass123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login exitoso",
  "data": {
    "user": {
      "id": "uuid-here",
      "email": "admin@atlas.com",
      "role": "admin"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### Usar el Token

Incluye el token en el header `Authorization` de tus requests:

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 📋 Endpoints Principales

### 1. Health Check

**Verificar estado del servidor**

```http
GET /api/v1/health
```

**Response:**
```json
{
  "success": true,
  "message": "API is running",
  "timestamp": "2025-10-20T22:00:00.000Z"
}
```

---

### 2. Autenticación

#### Registrar Usuario
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "email": "admin@atlas.com",
  "password": "SecurePass123",
  "firstName": "John",
  "lastName": "Doe"
}
```

#### Login
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "admin@atlas.com",
  "password": "SecurePass123"
}
```

#### Renovar Token
```http
POST /api/v1/auth/refresh-token
Content-Type: application/json

{
  "refreshToken": "your-refresh-token-here"
}
```

#### Obtener Perfil
```http
GET /api/v1/auth/profile
Authorization: Bearer {token}
```

---

### 3. Agentes

#### Registrar Agente (Público)
```http
POST /api/v1/agents/register
Content-Type: application/json

{
  "device_id": "android_device_12345",
  "wallet_address": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e"
}
```

#### Listar Todos los Agentes (Requiere Auth)
```http
GET /api/v1/agents
Authorization: Bearer {token}
```

**Parámetros de query opcionales:**
- `status`: Filtrar por estado (active, inactive, suspended)
- `limit`: Número máximo de resultados (default: 100)
- `offset`: Paginación (default: 0)

**Ejemplo:**
```http
GET /api/v1/agents?status=active&limit=50&offset=0
Authorization: Bearer {token}
```

#### Obtener Agente por ID (Requiere Auth)
```http
GET /api/v1/agents/{id}
Authorization: Bearer {token}
```

#### Actualizar Estado de Agente (Requiere Admin)
```http
PUT /api/v1/agents/{id}/status
Authorization: Bearer {token}
Content-Type: application/json

{
  "status": "suspended"
}
```

#### Eliminar Agente (Requiere Admin)
```http
DELETE /api/v1/agents/{id}
Authorization: Bearer {token}
```

---

## 🧪 Ejemplos de Uso

### Ejemplo 1: Flujo Completo de Autenticación

```bash
# 1. Registrar usuario
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@atlas.com",
    "password": "SecurePass123",
    "firstName": "John",
    "lastName": "Doe"
  }'

# 2. Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@atlas.com",
    "password": "SecurePass123"
  }'

# 3. Usar el token para acceder a recursos protegidos
curl -X GET http://localhost:3000/api/v1/auth/profile \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Ejemplo 2: Registrar y Listar Agentes

```bash
# 1. Registrar un agente (endpoint público)
curl -X POST http://localhost:3000/api/v1/agents/register \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "android_device_12345",
    "wallet_address": "0x742d35Cc6634C0532925a3b844Bc454e4438f44e"
  }'

# 2. Listar todos los agentes (requiere autenticación)
curl -X GET http://localhost:3000/api/v1/agents \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# 3. Obtener un agente específico
curl -X GET http://localhost:3000/api/v1/agents/AGENT_UUID \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Ejemplo 3: Administración de Agentes

```bash
# 1. Suspender un agente (requiere rol admin)
curl -X PUT http://localhost:3000/api/v1/agents/AGENT_UUID/status \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "suspended"}'

# 2. Eliminar un agente (requiere rol admin)
curl -X DELETE http://localhost:3000/api/v1/agents/AGENT_UUID \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

---

## 🔍 Códigos de Estado HTTP

| Código | Significado |
|--------|-------------|
| 200 | OK - Solicitud exitosa |
| 201 | Created - Recurso creado exitosamente |
| 400 | Bad Request - Datos inválidos |
| 401 | Unauthorized - Token faltante o inválido |
| 403 | Forbidden - Sin permisos suficientes |
| 404 | Not Found - Recurso no encontrado |
| 500 | Internal Server Error - Error del servidor |

---

## 📦 Estructura de Respuestas

### Respuesta Exitosa
```json
{
  "success": true,
  "message": "Operación exitosa",
  "data": {
    // Datos del recurso
  }
}
```

### Respuesta de Error
```json
{
  "success": false,
  "message": "Descripción del error",
  "error": "Detalles técnicos del error"
}
```

---

## 🔒 Seguridad

### Headers de Seguridad

La API implementa los siguientes headers de seguridad:
- `Helmet.js` para headers HTTP seguros
- `CORS` configurado para orígenes permitidos
- `Rate Limiting` (10 requests/segundo)

### Validaciones

Todos los endpoints validan:
- ✅ Formato de email
- ✅ Longitud mínima de contraseña (6 caracteres)
- ✅ Formato de wallet address (42 caracteres, prefijo 0x)
- ✅ Formato UUID para IDs
- ✅ Estados válidos para agentes

---

## 🧩 Modelos de Datos

### Agent
```typescript
{
  id: UUID,
  device_id: string,
  wallet_address: string (42 chars, 0x prefix),
  status: 'active' | 'inactive' | 'suspended',
  created_at: DateTime,
  updated_at: DateTime
}
```

### User
```typescript
{
  id: UUID,
  email: string (format: email),
  role: 'admin' | 'user',
  firstName: string,
  lastName: string,
  created_at: DateTime,
  updated_at: DateTime
}
```

---

## 🚀 Testing con Postman

### Importar Colección

1. Descarga la especificación OpenAPI:
   ```
   http://localhost:3000/api-docs/swagger.json
   ```

2. En Postman: `Import > Link > Paste URL`

3. Configura variables de entorno:
   ```
   base_url: http://localhost:3000/api/v1
   token: (se llenará automáticamente después del login)
   ```

---

## 📞 Soporte

Para reportar problemas o solicitar características:
- GitHub: [github.com/Underlaba/Atlas-Backend-core](https://github.com/Underlaba/Atlas-Backend-core)
- Email: support@atlas.com

---

## 📝 Changelog

### v1.0.0 (2025-10-20)
- ✅ Implementación inicial de endpoints
- ✅ Sistema de autenticación JWT
- ✅ Gestión de agentes
- ✅ Documentación Swagger/OpenAPI
- ✅ Deploy en AWS EC2
